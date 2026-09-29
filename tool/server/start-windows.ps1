param(
    [string]$RedisServerPath = "",
    [string]$Configuration = "Debug",
    [string]$Preset = "",
    [string]$Config = "server/config-skyuv-pb.lua"
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location -LiteralPath $projectDir

& (Join-Path $PSScriptRoot "..\redis\start.ps1") -Action Start -RedisServerPath $RedisServerPath
& (Join-Path $PSScriptRoot "start-skyuv.ps1") -Configuration $Configuration -Preset $Preset -Config $Config
exit $LASTEXITCODE
