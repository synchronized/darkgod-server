param(
    [string]$Configuration = "Debug",
    [string]$Preset = "",
    [string]$Config = "server/config-skyuv-pb.lua"
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$presetName = if ($Preset) { $Preset } else { "windows-vs2022-$($Configuration.ToLower())" }
$buildRoot = Join-Path $projectDir "build\$presetName"
$runtime = Join-Path $buildRoot "bin\skyuv.exe"

if (-not (Test-Path -LiteralPath $runtime)) {
    throw "skyuv runtime not found: $runtime. Build with: cmake --preset $presetName; cmake --build --preset $presetName"
}

$env:SERVER_NAME = "smmo"
$env:OS = "Windows_NT"
$env:DARKGOD_BUILD_ROOT = "build/$presetName"
$env:DARKGOD_BUILD_CONFIGURATION = $Configuration
Set-Location -LiteralPath $projectDir

# Skynet configuration files run in a restricted Lua environment and cannot
# rely on os.getenv(). Generate the default configuration with the selected
# preset and configuration embedded in it.
$runtimeConfig = $Config
if ($Config -eq "server/config-skyuv-pb.lua") {
    $generatedDir = Join-Path $buildRoot "generated"
    $generatedConfigPath = Join-Path $generatedDir "config-skyuv-pb.lua"
    New-Item -ItemType Directory -Path $generatedDir -Force | Out-Null

    $configText = Get-Content -LiteralPath (Join-Path $projectDir $Config) -Raw
    $configText = $configText -replace 'darkgod_build_root = .*', ('darkgod_build_root = "build/' + $presetName + '"')
    $configText = $configText -replace 'darkgod_build_configuration = .*', ('darkgod_build_configuration = "' + $Configuration + '"')
    [System.IO.File]::WriteAllText(
        $generatedConfigPath,
        $configText,
        [System.Text.UTF8Encoding]::new($false)
    )
    $runtimeConfig = "build/$presetName/generated/config-skyuv-pb.lua"
}

& $runtime $runtimeConfig
exit $LASTEXITCODE
