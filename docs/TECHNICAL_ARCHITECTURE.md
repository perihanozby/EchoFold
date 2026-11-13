# Technical architecture

Godot 4.7.2 stable, GDScript, GL Compatibility renderer, native Control UI. Verified installed build: `4.7.2.stable.official.ed1daf0bf`.

`gameplay/systems/puzzle_engine.gd` is the single logical authority. A board has integer `width`, `height`, a row-major `cells` array and non-overlapping rectangular `panels`. Each cell has `type`, `dir`, and optional `channel`, `required_dir`, `mandatory`. Each panel requires string `id`, integer `x/y/w/h`, `axis` (`v` or `h`) and boolean `folded`. Cells outside a folded panel remain unchanged. Mirrored required receiver directions transform with the other optics.

Coordinates: x right, y down, north/east/south/west = 0/1/2/3. Slash travel mapping is [1,0,3,2]; backslash is [3,2,1,0]. Mirrors use dir 0/1 only. Vertical reflection uses x′=W−1−x; horizontal uses y′=H−1−y. Cardinal directions reflect through the same axis. Both transformations are exact involutions for valid boards.

Simulation queues beam branches and visits `(x,y,travel_direction,channel)` states. Intersections do not interact. Sharing a visited state across sources with the same channel is sound because receivers do not depend on source identity. The maximum optical state count is bounded by cells × directions × channels. Win evaluation counts mandatory receivers only and requires at least one. The BFS solver uses optical canonical states; panel animation metadata is deliberately excluded. It returns `solved`, `unsolvable`, `invalid`, or `limit`, with an explicit 8192-state default bound. Timeouts/limits are never treated as validation.

`PuzzleSession` maintains independent snapshot history and matching action stacks. Renderer state is not serialized as authoritative gameplay. `board_view.gd` draws cells, panels, axes and exact simulation segments; its 300 ms compression tween commits at the edge-on midpoint and evaluates completion only after the animation. Input is blocked during a fold. Focus changes cancel gestures and persist committed state; an uncommitted animation may be lost safely on termination.

`app_controller.gd` assembles screens from reusable button, label, row, header, modal and brand functions. All layouts use containers and consistent theme tokens. Portrait boards remain square; short viewports use scrolling instead of squeezing controls. The board always uses fixed coordinate direction, independent of Arabic UI direction. Android safe-area insets are converted to viewport units.

`save_service.gd` uses schema 1 JSON, flushed temporary writes, a previous valid backup and same-directory replacement. Recovery order is primary, backup, temporary. It validates fields independently, preserves usable progress, rejects malformed records and protects unsupported future-version primary files from replacement. Active sessions replay legal panel IDs rather than accepting arbitrary deserialized boards; the entire current action/redo path is retained. Desktop development and tests write inside `build`; Android uses app-private user storage.

`audio_service.gd` synthesizes original PCM streams locally, including a looped atmospheric tone and event sounds. Separate Music/SFX buses support persistent toggles. Haptics use Android vibration only when enabled. No Android networking permission is requested.

All player-facing UI copy is keyed in `localization_service.gd`, with 16 translation columns, localized digits/dates and RTL selection. Product name, numeric identifiers and original legal notices are intentional exceptions. Bundled Noto fonts provide offline fallback. Native-language review and regional CJK typography review remain open.
