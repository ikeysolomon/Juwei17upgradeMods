param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "build\esp32")
)

$ErrorActionPreference = "Stop"
$cli = Join-Path $env:LOCALAPPDATA "Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"
$config = Join-Path $env:TEMP "arduino-cli-cfg\arduino-cli.yaml"
$configDirectory = Join-Path $env:LOCALAPPDATA "Arduino15"
$firmware = Join-Path $PSScriptRoot "firmware\OnStepX"
$fqbn = "esp32:esp32:esp32:PartitionScheme=huge_app,FlashFreq=80,UploadSpeed=921600"

if (!(Test-Path $cli)) {
    throw "Arduino CLI was not found at $cli"
}
if (!(Test-Path $firmware)) {
    throw "OnStepX source was not found at $firmware"
}

$arguments = @("compile", "--config-dir", $configDirectory, "--fqbn", $fqbn, "--output-dir", $OutputDirectory, $firmware)
if (Test-Path $config) {
    $arguments = @("compile", "--config-file", $config, "--config-dir", $configDirectory, "--fqbn", $fqbn, "--output-dir", $OutputDirectory, $firmware)
}

& $cli @arguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$image = Join-Path $OutputDirectory "OnStepX.ino.bin"
if (!(Test-Path $image)) {
    throw "Build completed without producing $image"
}

Write-Output "BUILD_IMAGE=$image"