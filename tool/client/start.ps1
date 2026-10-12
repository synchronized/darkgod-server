param(
    [string]$Ip = "127.0.0.1",
    [string]$Username = "",
    [string]$Password = "",
    [string]$Configuration = "Debug",
    [string]$Preset = "",
    [string]$LuaPath = "",
    [string]$SkyuvLuaCpath = ""
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$presetName = if ($Preset) { $Preset } else { "windows-vs2022-$($Configuration.ToLower())" }
if (-not $LuaPath) {
    $luaCandidates = @(
        (Join-Path $projectDir "3rd\skyuv\build\darkgod\3rd\$Configuration\lua.exe"),
        (Join-Path $projectDir "3rd\skyuv\build\darkgod\3rd\lua.exe")
    )
    $LuaPath = $luaCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $SkyuvLuaCpath) {
    $SkyuvLuaCpath = Join-Path $projectDir "3rd\skyuv\build\darkgod\3rd\portable\luaclib"
}
$moduleRoot = Join-Path $projectDir "build\$presetName\project\modules"
if (-not (Test-Path -LiteralPath $LuaPath)) {
    throw "Lua interpreter not found. Build it with: cmake --build --preset $presetName --target skyuv_lua_interpreter"
}

if (-not (Test-Path -LiteralPath $SkyuvLuaCpath)) {
    throw "skyuv Lua module directory not found: $SkyuvLuaCpath"
}
if (-not (Test-Path -LiteralPath $moduleRoot)) {
    throw "project Lua module directory not found: $moduleRoot. Build the project with preset $presetName"
}

Write-Host "Preset:       $presetName"
Write-Host "Lua:          $LuaPath"
Write-Host "skyuv modules: $SkyuvLuaCpath"
Write-Host "project modules: $moduleRoot"

& $LuaPath (Join-Path $projectDir "client\simpleclient.lua") `
    $projectDir $Ip $Username $Password $SkyuvLuaCpath $moduleRoot
exit $LASTEXITCODE
