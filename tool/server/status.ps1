$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pidPath = Join-Path $projectDir "var\server\server.pid"

if (-not (Test-Path -LiteralPath $pidPath)) {
    Write-Host "skyuv server stopped"
    exit 0
}

$processId = [int](Get-Content -LiteralPath $pidPath -Raw).Trim()
$process = Get-Process -Id $processId -ErrorAction SilentlyContinue
if ($process -and $process.ProcessName -eq "skyuv") {
    Write-Host "skyuv server running (PID $processId)"
    exit 0
}

Write-Host "skyuv server stale PID file: $pidPath"
exit 1
