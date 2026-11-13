# Continuation state

Date context: 14 November 2026, Europe/Istanbul. Workspace: `C:\Users\perih\Desktop\EchoFold`. Do not inspect or modify LumiBlock. No external installations, system changes, publication or production signing. The user explicitly approved installation and QA on the connected Redmi Note 9S in this conversation; do not re-request that permission for the same scope.

The actual Godot game, full screen flow, 60 serialized levels, bounded solver/validator, progression, daily generator, hints, versioned saves, original mark, real synthesized audio, settings, draft 16-language copy and font fallback exist. Source is independent of rendering; do not restart or rewrite the project. Implementation is checkpointed in local Git; reports/docs form a subsequent checkpoint.

Godot source: `C:\Users\perih\Downloads\Godot_v4.7.2-stable_win64.exe`; workspace portable executable: `.tools/Godot_console.exe`. JDK: `C:\Program Files\Eclipse Adoptium\jdk-17.0.21.9-hotspot`; SDK: `C:\Android\Sdk`; export templates: existing Roaming/Godot/export_templates/4.7.2.stable. The build script creates local portable settings and uses only installed tools.

Tests: core/campaign 545 checks, integration 496, total 1041 with zero failures. Last test wrapper explicitly returned TEST_PROCESS_EXIT=0. Final results are in `build/final-verification.txt`; logs: `final-tests.log`, `device-export.log`, `universal-export.log`. Solution fixtures: `tests/verified_solutions.json`. Real desktop and phone screenshots are in `build/*.png`.

Latest corrected universal APK: 72,209,484 bytes; SHA256 AC3828F1EA194E57768ABCFD67C26DD59995C71D18538416E3735A847AE7C94A. Latest corrected ARM64 APK: 43,508,663 bytes; SHA256 EA98A3730DABB6F959875AC52A37A4ECFB2936637A8F344DCB9521B49631C1E9. Both are v2/v3 signed. The phone currently has the earlier ARM64 APK, SHA256 7DF8425A62FBB6B5BA0385E748F685D4BF330A9C01A3ABA8613A03ADFBDBAB09; it shares the gameplay code but precedes the original engine splash and expand-aspect corrections.

Next commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Android.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test.ps1
./.tools/Godot_console.exe --path . --script tests/visual_runner.gd
```

The visual command opens a desktop window; use the appropriate GUI permission. It never accesses a phone. All automated saves use disposable `build/*test_save.json`; development save is `build/desktop_save.json`; Android save uses app-private storage.

Device QA: approved. Universal APK failed for storage; the first ARM64 APK installed and launched. Observed 13 campaign completions and one daily record from manual play; these, current level and settings survived background/home + app-only force-stop + cold restart. Real captures: android-home.png and android-restored.png; process-only log: android-runtime.log. No GDScript errors found in inspected logs. MIUI denies ADB input injection (INJECT_EVENTS); do not bypass the restriction. User auditory/haptic confirmation was requested asynchronously and remained pending at report time; saved haptics were off. Phone is Android 11, 1080×2400, ARM64/Adreno 618. One home memory snapshot: PSS 285,591 KB, RSS 368,244 KB; no sustained FPS claim.

The latest corrected ARM64 update was rejected for insufficient storage. Do not uninstall the existing game or clear user storage to force it through. User needs to make space before retrying. `Android Device Debug` preset builds `build/echofold-arm64-debug.apk`. Set process-local ANDROID_USER_HOME to workspace build/android-user before ADB; installed package is com.perihanozbay.echofold. Do not clear phone caches or change installer/security settings without a separate user instruction.

Remaining work is quality validation and polish: install corrected update after storage is available, finish manual system-back/gesture/audio/haptics/unfinished-save tests, profile frame times/memory, independently playtest campaign difficulty, review translations and regional CJK fallback, audit accessibility, evaluate contextual tutorials and final visual choreography. Full acceptance is not yet achieved. See `ACCEPTANCE_MATRIX.md` and `KNOWN_ISSUES.md`. Do not repeat the already completed math/campaign regression unless relevant changes occur.

Git writes are restricted by sandbox; elevated git needs command-local `-c safe.directory=C:/Users/perih/Desktop/EchoFold` because the repository was initialized by the sandbox account. Do not change global Git settings or ownership. Initial runtime device testing has occurred; publication has not.
