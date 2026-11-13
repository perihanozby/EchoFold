# Design system

Identity: Quiet Futurism, architectural glass, soft light and spatial clarity. Original folded geometric icon in `assets/icons/echofold.svg`. All game drawing and synthesized audio were created for this project; no LumiBlock files were inspected or reused.

| Role | Colour |
|---|---|
| Background | #0B1322 |
| Surface | #19293B |
| Elevated | #24364B |
| Board | #101D2C |
| Panel / boundary | #284356 / #527083 |
| Text / secondary | #F2F6FA / #B8C9D6 |
| Accent | #72D6D0 |
| Splitter | #9A9BE8 |
| Warm / stars | #F0B98D |
| Beam / active receiver | #83E9DC / #A6F0D4 |

Theme construction is centralized in `ui/theme/design_tokens.gd`. Fine one-pixel borders, rounded 14 px surfaces, generous margins, native focus borders and consistent button hover/press states. Noto Sans primary text; Arabic, Devanagari, Thai and CJK fallbacks. Titles 26–30, section labels 19–23, body/buttons 16, supporting copy 13–15 logical units. Labels wrap naturally.

Buttons are at least 50 logical units high. The board scales uniformly and retains clear mirror slashes, source triangles, splitter branch marks, and check marks on activated receivers. State is not colour-only. Compact-height layouts intentionally scroll to retain useful board size and touch controls.

Motion: 150 ms selection, 300 ms fold, 220 ms beam reveal, 200 ms screen/modal fade, 600 ms star entrance. Native button press states provide immediate feedback. Reduced motion bypasses selection/fold/reveal/fades. Effects intensity changes beam halo opacity. No fullscreen bloom, expensive blur or physics scenes.

Actual desktop captures: `build/home.png`, `first_light.png`, `resonance.png`, `complete.png`, `compact.png`, `arabic_settings.png`. These capture the current visual baseline, not a claim of final art-direction approval. Additional receiver-specific choreography, chapter-unlock presentation and broad human visual review remain polish work.

Device review identified the engine's default loading image and letterboxing. The original SVG now also produces `assets/icons/boot.png`; project/native Android splash settings use that artwork. Viewport aspect uses expand to fill tall screens. The corrected native splash was extracted from the final APK and visually inspected. The corrected update could not be installed on the phone due to storage, so final device presentation review is still pending. Native splash option names were checked against [Godot's Android exporter source](https://github.com/godotengine/godot/blob/master/platform/android/export/export_plugin.cpp).
