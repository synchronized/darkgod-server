param(
    [int]$InstanceCount = 2,
    [int]$BasePort = 6379
)

$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "start.ps1") -Action Status -InstanceCount $InstanceCount -BasePort $BasePort
exit $LASTEXITCODE
