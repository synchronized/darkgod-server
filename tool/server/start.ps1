param(
    [string]$Configuration = "Debug",
    [string]$Preset = "",
    [string]$Config = "server/config-skyuv-pb.lua",
    [switch]$Background
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$presetName = if ($Preset) { $Preset } else { "windows-vs2022-$($Configuration.ToLower())" }
$buildRoot = Join-Path $projectDir "build\$presetName"
$projectRoot = Join-Path $buildRoot "project"
$runtime = Join-Path $projectRoot "bin\skyuv.exe"
$pidDir = Join-Path $projectDir "var\server"
$pidPath = Join-Path $pidDir "server.pid"
$logPath = Join-Path $pidDir "server.log"
$errorLogPath = Join-Path $pidDir "server.error.log"

if (-not (Test-Path -LiteralPath $runtime)) {
    throw "skyuv runtime not found: $runtime. Build with: cmake --preset $presetName; cmake --build --preset $presetName"
}

$env:SERVER_NAME = "smmo"
$env:OS = "Windows_NT"
$env:DARKGOD_BUILD_ROOT = "build/$presetName/project"
$env:DARKGOD_BUILD_CONFIGURATION = $Configuration
Set-Location -LiteralPath $projectDir

# Skynet configuration files run in a restricted Lua environment and cannot
# rely on os.getenv(). Generate the default configuration with the selected
# preset and configuration embedded in it.
$runtimeConfig = $Config
if ($Config -eq "server/config-skyuv-pb.lua") {
    $generatedDir = Join-Path $projectRoot "config"
    $generatedConfigPath = Join-Path $generatedDir "config-skyuv-pb.lua"
    New-Item -ItemType Directory -Path $generatedDir -Force | Out-Null

    $configText = Get-Content -LiteralPath (Join-Path $projectDir $Config) -Raw
    $configText = $configText -replace 'darkgod_build_root = .*', ('darkgod_build_root = "build/' + $presetName + '/project"')
    $configText = $configText -replace 'darkgod_build_configuration = .*', ('darkgod_build_configuration = "' + $Configuration + '"')
    [System.IO.File]::WriteAllText(
        $generatedConfigPath,
        $configText,
        [System.Text.UTF8Encoding]::new($false)
    )
    $runtimeConfig = "build/$presetName/project/config/config-skyuv-pb.lua"
}

if ($Background) {
    New-Item -ItemType Directory -Path $pidDir -Force | Out-Null
    if (Test-Path -LiteralPath $pidPath) {
        $existingPid = [int](Get-Content -LiteralPath $pidPath -Raw).Trim()
        $existingProcess = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
        if ($existingProcess -and $existingProcess.ProcessName -eq "skyuv") {
            Write-Host "skyuv server already running (PID $existingPid)"
            exit 0
        }
        Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
    }
    $process = Start-Process -FilePath $runtime -ArgumentList @($runtimeConfig) `
        -WorkingDirectory $projectDir -RedirectStandardOutput $logPath `
        -RedirectStandardError $errorLogPath -WindowStyle Hidden -PassThru
    Set-Content -LiteralPath $pidPath -Value $process.Id -NoNewline
    Write-Host "skyuv server started in background (PID $($process.Id))"
    exit 0
}

& $runtime $runtimeConfig
exit $LASTEXITCODE
