param(
    [string]$OutputDirectory,
    [string]$CliPath,
    [string]$ConfigFile,
    [string]$UploadPort
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRoot "build\esp32"
}
if ([string]::IsNullOrWhiteSpace($CliPath)) {
    $ideCli = Join-Path $env:LOCALAPPDATA "Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"
    if (Test-Path $ideCli) {
        $CliPath = $ideCli
    }
    else {
        $cliCommand = Get-Command arduino-cli.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (!$cliCommand) {
            $cliCommand = Get-Command arduino-cli -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if (!$cliCommand) {
            throw "Arduino CLI was not found. Install it with the ESP32 core, add it to PATH, or pass -CliPath."
        }
        $CliPath = $cliCommand.Source
    }
}

$configDirectory = Join-Path $env:LOCALAPPDATA "Arduino15"
$firmware = Join-Path $repositoryRoot "firmware\OnStepX"
$fqbn = "esp32:esp32:esp32:PartitionScheme=huge_app,FlashFreq=80,UploadSpeed=921600"

if (!(Test-Path $CliPath)) {
    throw "Arduino CLI was not found at $CliPath"
}
if (!(Test-Path $firmware)) {
    throw "OnStepX source was not found at $firmware"
}

$configArguments = @("--config-dir", $configDirectory)
if (![string]::IsNullOrWhiteSpace($ConfigFile)) {
    if (!(Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
        throw "Arduino CLI configuration was not found at $ConfigFile"
    }
    $configArguments = @("--config-file", (Resolve-Path -LiteralPath $ConfigFile).Path)
}

$arguments = @("compile") + $configArguments + @("--fqbn", $fqbn, "--output-dir", $OutputDirectory, $firmware)
& $CliPath @arguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$image = Join-Path $OutputDirectory "OnStepX.ino.bin"
if (!(Test-Path $image)) {
    throw "Build completed without producing $image"
}

Write-Output "BUILD_IMAGE=$image"

if (![string]::IsNullOrWhiteSpace($UploadPort)) {
    $uploadFqbn = "esp32:esp32:esp32:PartitionScheme=huge_app,FlashFreq=80,UploadSpeed=115200"
    $arguments = @("upload") + $configArguments + @("--fqbn", $uploadFqbn, "--port", $UploadPort, "--input-dir", $OutputDirectory)
    & $CliPath @arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Write-Output "UPLOAD_PORT=$UploadPort"
}