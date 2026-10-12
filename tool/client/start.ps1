param(
    [string]$Ip = "127.0.0.1",
    [string]$Username = "",
    [string]$Password = "",
    [string]$LuaPath = "",
    [string]$SkyuvLuaCpath = ""
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $LuaPath) {
    $LuaPath = Join-Path $projectDir "3rd\skyuv\3rd\skynet\3rd\lua\lua.exe"
}
if (-not $SkyuvLuaCpath) {
    $SkyuvLuaCpath = Join-Path $projectDir "3rd\skyuv\build\darkgod\3rd\portable\luaclib"
}
if (-not (Test-Path -LiteralPath $LuaPath)) {
    throw "Lua interpreter not found: $LuaPath"
}

& $LuaPath (Join-Path $projectDir "client\simpleclient.lua") `
    $projectDir $Ip $Username $Password $SkyuvLuaCpath
exit $LASTEXITCODE
