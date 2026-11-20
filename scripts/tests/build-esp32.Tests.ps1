$ErrorActionPreference = "Stop"
$helper = Join-Path (Split-Path -Parent $PSScriptRoot) "build-esp32.ps1"
$shell = (Get-Process -Id $PID).Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("juwei-build-test-" + [guid]::NewGuid())
$savedEnvironment = @{}
foreach ($name in @("TEMP", "JUWEI_TEST_LOG", "JUWEI_TEST_FAIL")) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

function Assert-True($Condition, [string]$Message) {
    if (!$Condition) { throw $Message }
}

function Invoke-Helper([string[]]$Options, [int]$ExpectedExit = 0) {
    if (Test-Path -LiteralPath $env:JUWEI_TEST_LOG) {
        Remove-Item -LiteralPath $env:JUWEI_TEST_LOG
    }
    $previousPreference = $ErrorActionPreference
    try {
        # Windows PowerShell turns native stderr into error records, including expected failures.
        $ErrorActionPreference = "Continue"
        $output = & $shell -NoProfile -File $helper -CliPath $fakeCli @Options 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    Assert-True ($exitCode -eq $ExpectedExit) "Expected exit $ExpectedExit, got $exitCode`: $output"
    if (Test-Path -LiteralPath $env:JUWEI_TEST_LOG) {
        Get-Content -LiteralPath $env:JUWEI_TEST_LOG | ForEach-Object {
            ,(ConvertFrom-Json $_)
        }
    }
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    $env:TEMP = $testRoot
    $env:JUWEI_TEST_LOG = Join-Path $testRoot "calls.jsonl"
    $env:JUWEI_TEST_FAIL = ""
    $mock = Join-Path $testRoot "fake cli.ps1"
    $fakeCli = Join-Path $testRoot "arduino-cli.cmd"
    @'
@($args) | ConvertTo-Json -Compress | Add-Content -LiteralPath $env:JUWEI_TEST_LOG
if ($args[0] -eq $env:JUWEI_TEST_FAIL) { exit 23 }
if ($args[0] -eq "compile") {
    $index = [Array]::IndexOf($args, "--output-dir")
    $directory = $args[$index + 1]
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $directory "OnStepX.ino.bin") -Value "mock firmware"
}
exit 0
'@ | Set-Content -LiteralPath $mock
    "@echo off`r`n`"$shell`" -NoProfile -File `"$mock`" %*`r`nexit /b %errorlevel%" |
        Set-Content -LiteralPath $fakeCli

    $legacyDirectory = Join-Path $testRoot "arduino-cli-cfg"
    New-Item -ItemType Directory -Path $legacyDirectory | Out-Null
    Set-Content -LiteralPath (Join-Path $legacyDirectory "arduino-cli.yaml") -Value "invalid: ["
    $imageDirectory = Join-Path $testRoot "output with spaces"

    $calls = @(Invoke-Helper -Options @("-OutputDirectory", $imageDirectory))
    Assert-True ($calls.Count -eq 1 -and $calls[0][0] -eq "compile") "Default mode must only compile."
    Assert-True ($calls[0] -contains "--config-dir") "Default Arduino15 selection was lost."
    Assert-True ($calls[0] -notcontains "--config-file") "An unrelated TEMP configuration was loaded."
    Assert-True (Test-Path -LiteralPath (Join-Path $imageDirectory "OnStepX.ino.bin")) "Compile output path was not preserved."

    $calls = @(Invoke-Helper -Options @("-OutputDirectory", $imageDirectory, "-UploadPort", "COM42"))
    Assert-True ($calls.Count -eq 2) "Default configuration must support upload."
    foreach ($call in $calls) {
        $index = [Array]::IndexOf($call, "--config-dir")
        Assert-True ($index -ge 0 -and $call[$index + 1] -eq (Join-Path $env:LOCALAPPDATA "Arduino15")) "Default configuration was not reused."
        Assert-True ($call -notcontains "--config-file") "Upload loaded an unrelated TEMP configuration."
    }

    $config = Join-Path $testRoot "custom config.yaml"
    Set-Content -LiteralPath $config -Value "board_manager: {}"
    $options = @("-OutputDirectory", $imageDirectory, "-ConfigFile", $config, "-UploadPort", "COM42")
    $calls = @(Invoke-Helper -Options $options)
    Assert-True ($calls.Count -eq 2 -and $calls[0][0] -eq "compile" -and $calls[1][0] -eq "upload") "Build/upload ordering is wrong."
    foreach ($call in $calls) {
        $index = [Array]::IndexOf($call, "--config-file")
        Assert-True ($index -ge 0 -and $call[$index + 1] -eq $config) "Custom configuration was not reused."
        Assert-True ($call -notcontains "--config-dir") "Default config directory overrides the explicit file."
    }
    $upload = $calls[1]
    Assert-True ($upload[[Array]::IndexOf($upload, "--input-dir") + 1] -eq $imageDirectory) "Upload used a different image directory."
    Assert-True ($upload[[Array]::IndexOf($upload, "--port") + 1] -eq "COM42") "Upload port was not passed."
    Assert-True (($upload | Where-Object { $_ -like "*UploadSpeed=115200" }).Count -eq 1) "Upload speed was not preserved."

    $env:JUWEI_TEST_FAIL = "compile"
    $calls = @(Invoke-Helper -Options $options -ExpectedExit 23)
    Assert-True ($calls.Count -eq 1 -and $calls[0][0] -eq "compile") "A failed compile must not upload an old image."

    $env:JUWEI_TEST_FAIL = "upload"
    $calls = @(Invoke-Helper -Options $options -ExpectedExit 23)
    Assert-True ($calls.Count -eq 2) "Upload failure was not exercised."

    $env:JUWEI_TEST_FAIL = ""
    $calls = @(Invoke-Helper -Options @("-ConfigFile", (Join-Path $testRoot "missing.yaml")) -ExpectedExit 1)
    Assert-True ($calls.Count -eq 0) "Missing configuration must fail before invoking the CLI."
    Write-Output "PASS: default compile, explicit build/upload configuration, paths with spaces, failure propagation, and missing configuration."
}
finally {
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], "Process")
    }
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
