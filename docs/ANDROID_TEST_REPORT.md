# Android debug verification

PASS — Android debug export using existing Godot 4.7.2 templates, JDK 17.0.21, SDK build-tools 35.0.0. Export template reports target/compile SDK 36 and minimum SDK 24. The editor notes build-tools 35 fallback; non-Gradle template export and signing complete successfully. No Android Studio or software installation was required.

Artifact: `build/echofold-debug.apk`. Development package: `com.perihanozbay.echofold`. Version code 1, version name 0.1.0. This package identifier has not been reserved or checked for publication ownership. Native libraries: arm64-v8a and x86_64. Only requested permission: android.permission.VIBRATE. No INTERNET permission. Launcher alias is present as `com.godot.game.GodotAppLauncher`, targeting GodotApp. The aapt 35 badging command does not summarize this alias as a launchable activity; manifest XML inspection confirms MAIN/LAUNCHER and exported alias.

PASS — apksigner verifies APK Signature Schemes v2 and v3. Debug certificate subject: CN=ECHOFOLD Debug, O=ECHOFOLD, C=TR. Certificate SHA-256: `90db40f1e82276af0ce6ff33654ecb84c98dc59fdf4dbce705e40a79c624f1c1`. The project-local key is a disposable development key; no production credentials were accessed. Final file hash/size is recorded in `build/final-verification.txt`.

The user explicitly approved installation and device QA on 14 November 2026. ADB detected a Redmi Note 9S running Android 11, 1080×2400, arm64-v8a, Adreno 618. The universal APK first failed with INSTALL_FAILED_INSUFFICIENT_STORAGE; /data reported 752 MB available. The 43,487,754-byte first ARM64 build then installed successfully and launched through the actual exported launcher alias. Its SHA256 is 7DF8425A62FBB6B5BA0385E748F685D4BF330A9C01A3ABA8613A03ADFBDBAB09. No pre-existing EchoFold package was present.

PASS — actual cold launch to the branded home screen. Initial ActivityManager launch reported TotalTime 2372 ms; this is an activity-start observation, not a game-ready or frame-rate measurement. Process-only logs showed Godot 4.7.2, GL Compatibility on Adreno 618 and no GDScript exceptions in the inspected startup log. Real screenshots: `build/android-home.png`, `android-restored.png`.

PASS — real interaction/progression persistence, observed through app-private saved state: 13 campaign completions, one daily completion, 14 solves, star/best records, hint usage, current level and settings. ADB touch injection itself is BLOCKED by MIUI's INJECT_EVENTS restriction. The observed completions came from manual phone interaction, not automated taps. Auditory/haptic confirmation is pending; saved haptics were disabled. No permission/security settings were changed to bypass the restriction.

PASS — background/home transition, app-only force-stop, cold relaunch and matching completed/daily/settings records before and after. The second ActivityManager cold launch reported TotalTime 838 ms. This verifies completed-progress restoration, not unfinished-puzzle history after every possible lifecycle interruption.

Measured memory snapshot at the home screen: TOTAL PSS 285,591 KB, TOTAL RSS 368,244 KB from dumpsys meminfo. This is one debug-build sample, not a leak or steady-state performance assessment. 60 FPS, thermal and battery acceptance remain NOT TESTED.

Device inspection exposed a default engine boot image and letterboxing. Both are fixed in source with original PNG/native splash assets and expand-aspect layout. The corrected ARM64 APK is 43,508,663 bytes, SHA256 EA98A3730DABB6F959875AC52A37A4ECFB2936637A8F344DCB9521B49631C1E9. Corrected universal APK is 72,209,484 bytes, SHA256 AC3828F1EA194E57768ABCFD67C26DD59995C71D18538416E3735A847AE7C94A. Both verify v2/v3 signatures. The corrected ARM64 update was rejected for insufficient storage; the prior playable build and its progress remain intact. No uninstall, cache clearing, user-file deletion or storage-threshold changes were performed. Latest presentation validation on the phone is therefore BLOCKED pending storage availability.

NOT TESTED — manual system-back behavior, touch/swipe edge cases, unfinished-state restoration, actual speaker/haptic experience, full safe-area combinations, sustained FPS and broad device coverage. Approval is already recorded; do not ask again for the same connected-device QA scope. Package update may be retried once space is available.

Reproduction: `tools/Build-Android.ps1`; manual metadata: aapt dump badging/xmltree; signature: java -jar apksigner.jar verify --verbose --print-certs. No publishing, release signing or Play Console activity was performed.
