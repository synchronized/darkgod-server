$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "stop.ps1")
& (Join-Path $PSScriptRoot "..\redis\stop.ps1")
exit $LASTEXITCODE
