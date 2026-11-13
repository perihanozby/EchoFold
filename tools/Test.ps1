param([string]$Godot = '')
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
if ($Godot -eq '') { $Godot = Join-Path $workspace '.tools\Godot_console.exe' }
Push-Location -LiteralPath $workspace
try {
    & $Godot --headless --path $workspace --script tests/test_runner.gd
    if ($LASTEXITCODE -ne 0) { throw 'Core/campaign tests failed.' }
    & $Godot --headless --path $workspace --script tests/integration_runner.gd
    if ($LASTEXITCODE -ne 0) { throw 'Integration tests failed.' }
} finally { Pop-Location }
exit 0
