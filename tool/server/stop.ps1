$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pidPath = Join-Path $projectDir "var\server\server.pid"

if (-not (Test-Path -LiteralPath $pidPath)) {
    Write-Host "skyuv server is not running (no PID file)"
    exit 0
}

$processId = [int](Get-Content -LiteralPath $pidPath -Raw).Trim()
$process = Get-Process -Id $processId -ErrorAction SilentlyContinue
if (-not $process -or $process.ProcessName -ne "skyuv") {
    Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
    Write-Host "skyuv server is not running"
    exit 0
}

Stop-Process -Id $processId
$stopped = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 250
    if (-not (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
        $stopped = $true
        break
    }
}
if (-not $stopped) {
    throw "skyuv server did not stop cleanly (PID $processId)"
}
Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
Write-Host "skyuv server stopped"
