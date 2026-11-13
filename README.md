# ECHOFOLD — The Art of Folding Light

An original offline Godot 4.7.2 puzzle game for Android. Reflect glass panels to route light to every crystal. No timers, accounts, ads, analytics, purchases or online dependencies.

Open `project.godot` in Godot and press F6 on `scenes/main.tscn`, or F5. Select a glass panel, then swipe across its dotted axis or press **Fold panel**. Undo and redo preserve the current solution's move count. Hints solve the current state, rather than assuming a fixed sequence.

## Build and test on this workstation

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Android.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test.ps1
# Smaller ARM64 phone build:
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Build-Android.ps1 -Preset "Android Device Debug" -Output build/echofold-arm64-debug.apk
```

The process-only execution-policy option permits these local scripts without changing Windows policy. The build script uses the existing Godot, SDK and JDK installations. It creates an isolated portable Godot profile inside `.tools`, runs tests, generates a local debug key if absent, and builds `build/echofold-debug.apk`. It does not install software, change system settings, publish or access a device. Export templates must already be installed at the path in `export_presets.cfg`. Only debug credentials are used; never use this key for production.

Desktop development saves are inside `build/desktop_save.json`. Android uses the app's private `user://echofold.json`. Tests use separate disposable files inside `build`.

## Content and implementation

- 60 individually serialized campaign boards, six chapters; verified BFS solutions in development-only `tests/verified_solutions.json`.
- Rectangular reflections, mirrors, blockers, channels, multiple emitters, simultaneous receivers, splitters and bounded loop detection.
- Home, chapters, levels, gameplay, pause, completion, daily, statistics, settings and instructions.
- Runtime switching across 16 draft translations, bundled Noto fonts, Arabic RTL, reduced motion, effect controls and alternative fold buttons.
- Original vector mark and synthesized music/SFX; optional Android vibration.
- UTC date-seeded daily boards, validated before play; independent of campaign unlocks.

The visual baseline and functional Android debug build are implemented. With explicit approval, the first ARM64 build was installed and launched on a Redmi Note 9S; real campaign/daily progress survived a process restart. MIUI blocks ADB touch injection, and insufficient storage blocks installing the latest presentation update. This is **not a commercially approved release**: remaining physical Android checks, measured device performance, native-language review, full accessibility review, and independent campaign playtesting remain open. See [acceptance matrix](docs/ACCEPTANCE_MATRIX.md), [known issues](docs/KNOWN_ISSUES.md), and [continuation notes](docs/NEXT_SESSION.md).

Screenshots in `build` are actual Godot desktop captures, not mockups. Bundled fonts are under SIL OFL; license files and source attribution are in `assets/fonts` and [third-party notices](docs/THIRD_PARTY_NOTICES.md).
