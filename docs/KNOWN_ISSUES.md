# Known issues and limitations

- The first ARM64 build is installed and launches on the approved Redmi Note 9S. Campaign/daily records survive a process restart. The corrected splash/aspect update is blocked by INSTALL_FAILED_INSUFFICIENT_STORAGE. The existing installed game and progress were preserved; no phone files/caches were deleted.
- MIUI blocks ADB touch injection with INJECT_EVENTS. Manual gameplay produced 13 saved campaign completions and a daily completion, but automated hardware gesture/system-back checks remain blocked. Actual audio/haptic confirmation is pending; the device's saved haptics setting is off.
- One home-screen memory sample measured PSS 285,591 KB / RSS 368,244 KB in the debug build. Sustained frame rate, memory stability, thermal and battery behavior remain unmeasured.
- Campaign boards are unique and mathematically verified, but many derive from spatial variants of authored route families. Independent difficulty, repetition and chapter pacing review is outstanding. Disjoint reflections commute, so order-dependent puzzle depth is not claimed.
- Chapter-specific guidance reacts to panel selection and the first fold. Its teaching effectiveness still needs new-player playtests.
- The visual baseline is cohesive and actually rendered, but final receiver-specific/chapter-unlock choreography and independent premium-art acceptance remain open.
- Short viewports intentionally scroll. This keeps the board readable but may put lower controls below the initial fold. Full language × device-size UI review is outstanding.
- Translations are complete draft key columns, not native-reviewed text. CJK fallback uses Noto Sans CJK SC for Chinese, Japanese and Korean coverage; region-specific glyph-shape review remains open.
- Accessibility controls are implemented, but formal assistive-technology, screen-reader, motor-accessibility and low-vision testing has not occurred. Contrast has not been audited with a measurement tool.
- Original synthesized audio plays through real buses; sustained-loop listening, speaker balancing and Android latency/haptics review remain open.
- Active-session load replays the full action history. Extremely long unfinished sessions have not been stress-tested for load latency or memory use.
- Sandboxed engine startup can report OS certificate-store and editor snapshot-directory access warnings; game networking is absent. Occasional test shutdowns report two AudioStream playback resource instances; investigate before making memory-stability claims.
- Android template targets SDK 36 while installed build tools are 35. Non-Gradle debug export succeeds, but release toolchain/policy validation is outstanding.
- No cloud synchronization, ads, purchases or analytics are implemented by design.
