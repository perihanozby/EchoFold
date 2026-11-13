# Level design and validation

Runtime campaign data: `levels/chapter_01` through `chapter_06`, ten JSON boards each. Cell index = y×width+x. Emitter/receiver cells are defined once in the cell array, not redundantly in separate object lists. Panel rectangles may not overlap. The `tutorial` key records chapter context. Chapter-opening guidance reacts to panel selection and the first committed fold.

Authored route and scramble factory: `levels/campaign.gd`. It is also used by the daily generator. Individual JSON campaign boards may be edited directly and are loaded at runtime. Normal tests validate existing JSON without replacing it. To deliberately regenerate all campaign files from the factory, run:

```powershell
./.tools/Godot_console.exe --headless --path . --script tests/test_runner.gd -- --generate
```

This explicit generation command replaces campaign JSON. Preserve intentional JSON-only design edits before using it. Normal verification:

```powershell
./tools/Test.ps1
```

Every level must have valid types and dimensions, in-bounds non-overlapping panels, an emitter and mandatory receiver, no initial win, a unique starting arrangement and a solver-verified shortest solution equal to par. Tests write development solution fixtures to `tests/verified_solutions.json`; export excludes the entire tests directory.

Do not treat solver validation as difficulty approval. The current campaign uses spatial variants of authored route families and deserves independent playtesting for repetition and challenge. Disjoint panel reflections commute; order-dependent mechanics would require a separately specified rule, rather than misleading animation. Add interactions only with explicit model and regression tests.

Daily generation uses UTC FNV-1a date hashing, authored route selection and a date-derived scramble mask. All 365 dates in 2026 were solved during integration testing. A daily board is validated again immediately before presentation.
