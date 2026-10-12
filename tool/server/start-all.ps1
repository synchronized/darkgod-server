param(
    [string]$RedisServerPath = "",
    [string]$Configuration = "Debug",
    [string]$Preset = "",
    [string]$Config = "server/config-skyuv-pb.lua",
    [switch]$Background
)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "..\redis\start.ps1") `
    -Action Start -RedisServerPath $RedisServerPath
& (Join-Path $PSScriptRoot "start.ps1") `
    -Configuration $Configuration -Preset $Preset -Config $Config -Background:$Background
exit $LASTEXITCODE
