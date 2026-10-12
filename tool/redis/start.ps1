param(
    [ValidateSet("Start", "Stop", "Status")]
    [string]$Action = "Start",
    [string]$RedisServerPath = "",
    [int]$InstanceCount = 2,
    [int]$BasePort = 6379
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dataRoot = Join-Path $projectDir "var\redis"

function Resolve-RedisServer {
    if ($RedisServerPath) {
        return (Resolve-Path -LiteralPath $RedisServerPath).Path
    }
    $command = Get-Command redis-server.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    throw "redis-server.exe not found. Pass -RedisServerPath 'C:\path\to\redis-server.exe' or add it to PATH."
}

function Get-RedisDirectory([int]$index) { return Join-Path $dataRoot ("redis{0}" -f $index) }
function Get-RedisPort([int]$index) { return $BasePort + $index }
function Get-RedisConfigPath([int]$index) {
    return Join-Path (Get-RedisDirectory $index) ("redis{0}.conf" -f $index)
}

function Test-TcpPort([int]$port) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync("127.0.0.1", $port)
        if (-not $task.Wait(500)) { return $false }
        return $client.Connected
    } catch { return $false } finally { $client.Dispose() }
}

switch ($Action) {
    "Start" {
        $server = Resolve-RedisServer
        & (Join-Path $PSScriptRoot "setup.ps1") -InstanceCount $InstanceCount -BasePort $BasePort
        for ($index = 0; $index -lt $InstanceCount; $index++) {
            $port = Get-RedisPort $index
            $configPath = Get-RedisConfigPath $index
            if (Test-TcpPort $port) {
                Write-Host "Redis already running on 127.0.0.1:$port"
                continue
            }
            $directory = Get-RedisDirectory $index
            $logPath = Join-Path $directory ("redis{0}.log" -f $index)
            $errorLogPath = Join-Path $directory ("redis{0}.error.log" -f $index)
            $pidPath = Join-Path $directory ".launcher.pid"
            $process = Start-Process -FilePath $server -ArgumentList @(Split-Path -Leaf $configPath) `
                -WorkingDirectory $directory -RedirectStandardOutput $logPath `
                -RedirectStandardError $errorLogPath -WindowStyle Hidden -PassThru
            Set-Content -LiteralPath $pidPath -Value $process.Id -NoNewline
            $ready = $false
            for ($attempt = 0; $attempt -lt 20; $attempt++) {
                Start-Sleep -Milliseconds 250
                if (Test-TcpPort $port) { $ready = $true; break }
                if ($process.HasExited) { break }
            }
            if (-not $ready) {
                throw "Redis failed to start on port $port. See $logPath"
            }
            Write-Host "Redis started on 127.0.0.1:$port (PID $($process.Id))"
        }
    }
    "Stop" {
        for ($index = 0; $index -lt $InstanceCount; $index++) {
            $pidPath = Join-Path (Get-RedisDirectory $index) ".launcher.pid"
            if (-not (Test-Path -LiteralPath $pidPath)) { continue }
            $processId = [int](Get-Content -LiteralPath $pidPath -Raw).Trim()
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
            if ($process -and $process.ProcessName -eq "redis-server") {
                Stop-Process -Id $processId
                Write-Host "Redis stopped on 127.0.0.1:$(Get-RedisPort $index) (PID $processId)"
            }
            Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
        }
    }
    "Status" {
        for ($index = 0; $index -lt $InstanceCount; $index++) {
            $port = Get-RedisPort $index
            $state = if (Test-TcpPort $port) { "running" } else { "stopped" }
            Write-Host "127.0.0.1:$port $state"
        }
    }
}
