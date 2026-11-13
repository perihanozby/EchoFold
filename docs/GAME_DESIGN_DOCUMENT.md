# ECHOFOLD — design baseline

Status: implemented playable baseline; commercial quality signoff pending.

Quiet spatial logic on a 5×5 optical grid. Select a bounded glass panel, then reflect its internal cells through its vertical or horizontal centre axis. Direction is travel direction, with north at the top. The animation represents a reversible in-place reflection, never overlapping pieces of paper. Receivers are solid diamonds with check marks when active, sources are directional circles, splitters are circles with an outgoing branch mark, and blockers are crossed squares.

Victory requires all mandatory receivers to be lit in a stable simulation after an animation. No transient animation result can win. Beams cross without collision or colour mixing. Splitters preserve the incoming beam and add their marked branch when different. Receivers absorb light. Channels pass beams only parallel to their axis. A beam hitting another emitter stops.

The player can tap a panel and press Fold panel instead of swiping. Across a vertical axis, swipe horizontally; across a horizontal axis, swipe vertically. Both swipe signs perform the same involution. A minimum 24 logical pixel displacement and 1.3 axis dominance avoid ambiguous gestures. Only one touch owns a gesture. Undo/redo count the currently committed solution path; lifetime folds count every newly committed player fold, including those subsequently undone. Redo is not a new lifetime fold.

Stars: three at or below par, two through par+2, otherwise one. Replays can improve a record but cannot reduce earned stars. Campaign unlocks follow the preceding completed level. Daily solves never unlock campaign content. Statistics show actual persisted values.

Six chapters introduce one mirror, multi-turn paths, blockers, simultaneous signals, splitters, and combinations. The 60 unique starting arrangements use authored route families, spatial variants and explicit scramble masks. Disjoint reflections commute mathematically: difficulty is identifying correct panel states rather than enforcing one arbitrary move order. Some panels start correct and must be left alone. Final chapter combines five panels, branching and multiple sources. Independent difficulty/playtest review is still required.

Daily policy: UTC date YYYY-MM-DD, 32-bit FNV-1a seed; choose an authored route family from chapters 3–6, solve it, apply date-derived fold bits, avoid an already solved start, then BFS validate. A verified first campaign board is the fallback if validation fails. No network, advertisements or device identifier is involved. Local calendar midnight can differ from UTC midnight; this policy is deliberate and documented.

Home, chapter/level selection, gameplay, pause, completion, daily, statistics, settings, instructions and legal notices are implemented. The campaign is untimed, offline, single-player and free from artificial energy or retention mechanics.
