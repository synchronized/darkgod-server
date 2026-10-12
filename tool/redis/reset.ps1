param(
    [int]$InstanceCount = 2,
    [int]$BasePort = 6379
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dataRoot = Join-Path $projectDir "var\redis"

& (Join-Path $PSScriptRoot "start.ps1") -Action Stop -InstanceCount $InstanceCount -BasePort $BasePort

for ($index = 0; $index -lt $InstanceCount; $index++) {
    $directory = Join-Path $dataRoot ("redis{0}" -f $index)
    if (Test-Path -LiteralPath $directory) {
        Remove-Item -LiteralPath (Join-Path $directory ("redis{0}.rdb" -f $index)) -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $directory ("redis{0}.aof" -f $index)) -Force -ErrorAction SilentlyContinue
    }
}
