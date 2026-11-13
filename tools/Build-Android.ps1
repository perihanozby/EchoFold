param(
    [string]$GodotSource = 'C:\Users\perih\Downloads\Godot_v4.7.2-stable_win64.exe',
    [string]$AndroidSdk = 'C:\Android\Sdk',
    [string]$JavaSdk = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.21.9-hotspot',
    [switch]$SkipTests
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $workspace
try {
    New-Item -ItemType Directory -Path '.tools', 'build', '.tools\editor_data' -Force | Out-Null
    $godot = Join-Path $workspace '.tools\Godot_console.exe'
    if (-not (Test-Path -LiteralPath $godot)) {
        Copy-Item -LiteralPath (Join-Path $GodotSource 'Godot_v4.7.2-stable_win64.exe') -Destination '.tools\Godot.exe'
        Copy-Item -LiteralPath (Join-Path $GodotSource 'Godot_v4.7.2-stable_win64_console.exe') -Destination $godot
    }
    New-Item -ItemType File -Path '.tools\_sc_' -Force | Out-Null
    $javaPath = $JavaSdk.Replace('\', '/')
    $sdkPath = $AndroidSdk.Replace('\', '/')
    $settingsPath = Join-Path $workspace '.tools\editor_data\editor_settings-4.7.tres'
    # A workspace-contained editor profile; no system environment/settings changes.
    $settings = "[gd_resource type=`"EditorSettings`" format=3]`n`n[resource]`nexport/android/java_sdk_path = `"$javaPath`"`nexport/android/android_sdk_path = `"$sdkPath`"`nnetwork/connection/check_for_updates = 0`n"
    [System.IO.File]::WriteAllText($settingsPath, $settings)
    & $godot --headless --path $workspace --import
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    if (-not $SkipTests) {
        & $godot --headless --path $workspace --script tests/test_runner.gd
        if ($LASTEXITCODE -ne 0) { throw 'Core/campaign tests failed.' }
        & $godot --headless --path $workspace --script tests/integration_runner.gd
        if ($LASTEXITCODE -ne 0) { throw 'Integration tests failed.' }
    }
    if (-not (Test-Path -LiteralPath 'build\echofold-debug.keystore')) {
        & (Join-Path $JavaSdk 'bin\keytool.exe') -genkeypair -keystore build/echofold-debug.keystore -storepass android -alias androiddebugkey -keypass android -dname 'CN=ECHOFOLD Debug,O=ECHOFOLD,C=TR' -keyalg RSA -keysize 2048 -validity 10000
        if ($LASTEXITCODE -ne 0) { throw 'Debug keystore generation failed.' }
    }
    & $godot --headless --path $workspace --export-debug 'Android Debug' build/echofold-debug.apk
    if ($LASTEXITCODE -ne 0) { throw 'Android export failed.' }
    & (Join-Path $JavaSdk 'bin\java.exe') -jar (Join-Path $AndroidSdk 'build-tools\35.0.0\lib\apksigner.jar') verify --verbose --print-certs build/echofold-debug.apk
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    Get-FileHash -LiteralPath 'build\echofold-debug.apk' -Algorithm SHA256
} finally {
    Pop-Location
}
