# Acceptance matrix

| Requirement | Status | Evidence / limitation |
|---|---|---|
| Deterministic reversible rectangular folds | PASS | Core tests, isolation, inverse transforms, directional optics |
| Cardinal optics, blockers, channels, splitters, loops | PASS | Model tests and campaign/daily solving |
| Exact undo/redo and active move count | PASS | Session + UI history tests; resumed redo |
| 60 valid solvable campaign boards | PASS | JSON validation, unique starts, shortest par, solution fixtures |
| Campaign progression/stars | PASS | Unlock and award persistence tests |
| Daily puzzles independent of campaign | PASS | 365 date generation checks + separate save records |
| State-aware hints | PASS | BFS on current state; first useful panel only |
| Versioned recoverable saves | PASS | Round trip, corrupt backup, partial records, future version protection |
| Required screen flows | PASS | Functional navigation baseline; reset modal and completion verified |
| Initial physical phone installation/startup | PASS | ARM64 build installed and launched on approved Redmi Note 9S |
| Latest presentation update installation | BLOCKED | Android rejected update for insufficient storage; installed game preserved |
| Completed progress after process restart | PASS | 13 campaign and one daily record retained after app-only force-stop/cold launch |
| Full physical Android navigation | BLOCKED | MIUI denies ADB input injection; full manual system-back/gesture QA outstanding |
| Original visual baseline | PASS | Original mark, centralized theme, real desktop captures |
| Final premium visual/art acceptance | NOT TESTED | Human review and remaining choreography/polish |
| Fold animation and logical separation | PASS | Real desktop animation path and headless action checks |
| Final receiver/unlock choreography | NOT TESTED | Baseline beam/star transitions exist; dedicated choreography remains |
| Audio buses/settings | PASS | Real PCM synthesis, buses and persisted controls; auditory review pending |
| Physical-device audio/haptics | NOT TESTED | User confirmation pending; saved haptics currently disabled |
| Accessibility features | PASS | Reduced motion, shapes/check marks, focus, alternative controls, effect control |
| Full accessibility acceptance | NOT TESTED | No formal screen reader/low-vision/motor-accessibility review |
| 16-language key coverage and glyphs | PASS | All rows have 16 nonempty columns; bundled font glyph test |
| Native-language quality/RTL usability | NOT TESTED | Arabic screenshot inspected; full linguistic usability review absent |
| Responsive board geometry | PASS | Six viewport size checks; square/fits width; compact layout scrolls |
| Every screen at every language/size pair | NOT TESTED | Language smoke and size checks are separate, not full Cartesian QA |
| Automated regression | PASS | Core/campaign and integration commands executed |
| Android debug APK export/signing | PASS | Existing SDK/template export; apksigner v2/v3 verifies |
| Midrange Android 60 FPS | NOT TESTED | No measurements collected |
| Independent campaign difficulty review | NOT TESTED | Route-family variants need player testing |
| Publication / release readiness | BLOCKED | Outstanding human and physical device quality gates; no publication attempted |

PASS describes the stated executed scope, not commercial release approval. No physical device results or performance numbers are fabricated.
