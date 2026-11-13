# Level validation report

PASS — executed with Godot 4.7.2 on 14 November 2026, Europe/Istanbul date context.

All 60 campaign boards have schema-valid cells and panel regions, unique optical starting arrangements, at least one receiver, an unsolved starting state, a verified BFS solution, par equal to shortest solution length, and exact JSON load round trips. Solver solutions and explored state counts are stored in `tests/verified_solutions.json`. The final chapter reaches five-fold solutions. No solver timeout was accepted as a pass.

The core/campaign runner executed 545 checks with zero failures. The integration runner also verifies all 365 UTC dates in 2026: each daily puzzle starts unsolved, is solvable within the state bound and has shortest-solution par. Determinism is tested for repeated dates.

NOT TESTED — independent human difficulty, novelty, chapter pacing and alternative-solution quality review. Exact unique starting states do not imply 60 different underlying mechanical concepts. Spatial reflections and route-family variations are part of the current content design.
