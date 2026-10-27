## Current focused refinement (after M14.9)

See `docs/REFINEMENT_REPORT.md` for the 14 requested changes, validation and manual tests. PB Ghost, the dedicated Records screen and Mastery have been removed; Challenges and Best Time remain. Settings now has independent Music and Sound. Character Selection has six cosmetic humans. Village intermediate safe lanes have a warned anti-camping dog. Older milestone notes below are historical.

# Current campaign: M14.5

Run Project for the four-map campaign. Read [M14.5 report](docs/M14_5_REPORT.md) and [installation](M14_5_INSTALL.txt). Older notes below describe retained legacy fixtures; old previews intentionally use `scenes/legacy_main.tscn`.

---

# M14 QA candidate update

Merge this update into a backed-up completed M13 project named `PocketCrossing_M14_RELEASE_CANDIDATE`.
Close Godot first, replace matching supplied files, then reopen and allow import.
Your project/export/signing settings and normal save are not replaced.

Local QA: 10,456 assertions passed, zero failed; 368-cycle / 20-minute automated lifecycle run; clean import; both export resource packs load.
Native EXE/APK builds and Windows/physical-Android acceptance remain pending. **NOT READY FOR M15 until those checks pass.**
No new feature/content or balance changes. No M15 work started.

Read `docs/QA_M14.md` for the complete report, installation, exact PC/phone checklist and limitations.
Read `docs/M14_FILES.txt` for every supplied file and `docs/M14_REQUIREMENT_COVERAGE.md` for all 65 request items.
Use toolbar Run Project for the normal game; Run Current Scene on `tools/campaign_preview.tscn` for isolated level testing (Starting Level 1–15).

---

# M13 — Campaign balance and repeating fireworks

All 15 campaign levels now have at least five hazards, with five in Level 1 and twenty in Level 15. Vehicle types have distinct cruise speeds with safe following gaps; boats are shorter and varied. New-high-score fireworks repeat while the result panel stays open and stop on exit.

Read [balance tables, installation, Inspector instructions, tests and device checklist](docs/BALANCE_M13.md) and [exact changed files](docs/M13_FILES.txt). Open `tools/campaign_preview.tscn` → **Run Current Scene** for isolated gameplay, or `tools/speed_preview.tscn` to compare actual vehicle speeds. Native Windows/Android playtesting and Android performance acceptance remain pending. M14 has not started.

**Earlier milestone notes below are historical.**

# M12 — Bangladesh-inspired visual identity

The existing 15-level campaign now uses original CNG/rickshaw/bus/truck art, two passenger trains, five watercraft and seven reusable environment profiles. Layout, weather and scenery remain separate; M11 gameplay and save IDs are preserved.

Read [installation, per-level content, Inspector steps, tests and device checklist](docs/IDENTITY_M12.md) and [exact changed files](docs/M12_FILES.txt). Open `tools/campaign_preview.tscn` → **Run Current Scene** for isolated gameplay, or `tools/identity_gallery.tscn` for all new art under six themes. Physical Android performance and Windows/Android hands-on checks remain pending.

**Earlier milestone notes below are historical.**

# M11 — 15-level campaign

Run Project to play the 15-level campaign. For an isolated unlocked test run, open `tools/campaign_preview.tscn`, set **Starting Level** (1–15) and click **Run Current Scene**.

See [M11 installation, level list, Inspector instructions and tests](docs/CAMPAIGN_M11.md) and [exact changed files](docs/M11_FILES.txt). Existing saves keep their first-five level IDs. M11 intentionally replaces the active campaign layouts while preserving the old Resources for regression testing.

**Earlier milestone notes below are historical.**

# M10 Theme and Weather

Open `tools/theme_preview.tscn` and click **Run Current Scene**. Use the footer selector to compare Day, Evening, Night, Rain, Snow and Fog on one long road/rail/water layout. Run Project still opens the unchanged campaign.

See [M10 installation, Inspector instructions, architecture and tests](docs/THEMES_M10.md) and [exact changed files](docs/M10_FILES.txt).

**Earlier milestone notes below are historical; M10 adds visual weather.**

# M9 Long levels, camera, and section activation

Open `tools/long_level_preview.tscn` and click **Run Current Scene** (the editor toolbar button; no F6 key required).
It launches **Long Crossing**, a 24-row road/rail/water example with a forward-following camera.
Run Project still opens the original five-level campaign.

See [M9 installation, architecture, configuration and manual tests](docs/LONG_LEVELS_M9.md)
and [the exact update file list](docs/M9_FILES.txt).
The preview uses `user://section_preview_profile.cfg`; normal progress remains in `user://profile.cfg`.

The screen-height runtime restriction is removed. Distant components retain their nodes and
freeze outside an active window. Backtracking reactivates them with their timers and pools intact.
There is no procedural/endless generation or weather implementation.

**The following milestone notes are historical. M9 supersedes their seven-row/no-scrolling statements.**

# M8 Water Crossing

Open `tools/water_preview.tscn` and click **Run Current Scene** (F6 if available).
The preview immediately opens Water Workshop with three moving-platform lanes and uses
`user://section_preview_profile.cfg`. F5 still opens the normal five-level campaign.
See [M8 guide/configuration/manual tests](docs/WATER_M8.md) and
[exact changed-file list](docs/WATER_FILES.txt).

Water sections now support boats/logs, carrying, falls, shield rescue and pooling.
The M6/M7 previews and railway behavior remain available. Seven-row runtime limit remains.
No M9 scrolling/streaming or weather work is included. Notes below describe earlier milestones.

# M7 Railway Crossing

Open `tools/railway_preview.tscn` and use **Run Current Scene** (F6 if available).
It directly starts the seven-row railway example and uses the isolated
`user://section_preview_profile.cfg`. F5 still opens the unchanged five-level campaign.

Read [M7 guide and manual tests](docs/RAILWAY_M7.md) and
[exact changed-file list](docs/RAILWAY_FILES.txt).
The M6 road preview remains available at `tools/section_preview.tscn`.

Ordered Railway Sections now create reusable tracks, signals and trains.
Water, weather, scrolling and chunk streaming are not implemented.
The seven-row static-board limitation remains enforced.

The milestone notes below describe their historical scope.

# Pocket Crossing — Phase 4 rewards

The existing five-level campaign now includes safe-area coins, best stars and scores,
four cosmetic couriers, and temporary shield / slow-traffic / double-reward pickups.
See [Phase 4 audit and guide](docs/PHASE4.md), [architecture](docs/ARCHITECTURE.md),
and [complete file manifest](docs/PHASE4_FILES.txt). No new levels or world systems
were added in this phase. Phase 1–3 art, controls and traffic rules remain.

Install the update ZIP over your working Phase 3 project, or over the interrupted
Phase 4 folder. Keep your existing project.godot and export_presets.cfg.
The update does not contain either file. Reimport in Godot and export a fresh APK.
The full source ZIP uses the original generic export presets.

Coins bank on pickup, even if the run fails. Stars reward completing a route:
one for completion, one for at least 35% time left, one for at least two lives.
Character skins are cosmetic only; earn their prices through gameplay.
Missing old save fields receive defaults; valid previous progress is preserved.
See the Phase 4 guide for backup recovery behavior and manual phone checks.

# Pocket Crossing

A playable **five-level campaign** for **Godot 4.5.2 Standard / GDScript**. Guide Pip, a little courier in a yellow cap, through the traffic and reach all four destination bays.

The project targets **Windows desktop and Android** with one codebase. It uses the Compatibility renderer, original SVG placeholder artwork, and original synthesized sound effects. No plugins, paid assets, C#, or online services are required.

## Play in the editor

1. Install **Godot 4.5.2 Standard** from the [official archive](https://godotengine.org/download/archive/4.5.2-stable/).
2. Extract the entire ZIP into a writable folder.
3. In Godot's Project Manager, choose **Import**, select `PocketCrossing/project.godot`, and open it.
4. Wait for the assets to finish importing. Press **F6** only to run a particular scene; use **F5** to run the full game.
5. Select an unlocked level, or press **Enter** on the focused level button.

The source project is included. Compiled `.exe` and `.apk` files are not included; use the supplied presets and [export guide](docs/EXPORTING.md) to build them. Godot 4.5.2 is the tested baseline. Other Godot 4 versions have not been validated.

## Controls

| Action | Windows / keyboard | Android / pointer |
| --- | --- | --- |
| Move one grid cell | Arrow keys or WASD | Swipe anywhere on the board; tap an arrow button |
| Repeated movement | Hold a direction key | Hold an arrow button |
| Pause / resume | Esc or P; Pause button | Pause button; Android Back during a run |
| Restart | R; pause/end-screen button | Pause → Restart level |
| Toggle sound | M; Sound button | Sound button |
| Start / replay | Enter on the focused main button | Tap the main button |

A swipe makes **one hop**, even if you drag a long distance. Lift your finger before the next swipe. Mouse dragging on the board also simulates a swipe. Input received by the UI does not also move the player. Returning from another app leaves the game paused until you resume.

## Level 1 rules

- You start with **3 lives** and **90 seconds**.
- Cross **four lanes**, moving in alternating directions. Cars and longer vans have different hitbox widths.
- The starting sidewalk and the center island are safe places to wait.
- Enter each of the **four numbered bays** once. Reached bays show a check mark and cannot be entered again.
- After reaching a bay, Pip returns to the start for the next crossing.
- An unshielded collision costs one life and returns Pip to the start after a short delay. A ring and blinking sprite show brief spawn protection.
- Lose all lives, or let the timer reach zero, and the game-over screen appears.
- Reach all four bays to complete Level 1. The end screen offers Next Level, Retry and Level Select. There are five existing campaign levels.
- The timer continues during short respawn/delivery delays. Pausing freezes traffic, movement, the timer, and the respawn delay.

## Score

| Event | Points |
| --- | ---: |
| New highest row reached in the current crossing | 10 per row |
| Destination reached | 100 |
| Completion bonus | 5 × whole seconds remaining + 50 × remaining lives |

Revisiting an earlier row in the same crossing awards no extra points. The local best score and sound preference persist in Godot's `user://profile.cfg`. There is no account or network requirement.

## Project organization

| Location | Purpose |
| --- | --- |
| `scenes/main.tscn` | Game entry point |
| `scenes/levels/level_01.tscn` | World, traffic, destinations, player |
| `scenes/actors/` | Reusable player and vehicle scenes |
| `scripts/core/` | Game state, score, timer, saving, audio |
| `scripts/input/` | Keyboard, swipe, and on-screen input routing |
| `scripts/actors/` | Player hopping and vehicle movement/collision |
| `scripts/world/` | Traffic spawning, destination rules, original scenery |
| `scripts/data/` | Typed level and lane resources |
| `scripts/ui/` | HUD and menu/pause/end screens |
| `resources/levels/level_01.tres` | Editable Level 1 rules and traffic tuning |
| `assets/art/`, `assets/audio/` | Original art and sound effects |
| `tests/` | Automated integration checks |
| `tools/` | Sound regeneration and screenshot capture helpers |
| `docs/` | Architecture, exporting, validation, screenshots |
| `builds/` | Destination for your exported builds |

See [architecture and extension notes](docs/ARCHITECTURE.md) before replacing art or adding a level.

## Test from a terminal

Run from the project directory. Replace `godot` with your Godot executable path. On Windows PowerShell, use `& "C:\path\Godot_v4.5.2-stable_win64.exe"` in place of `godot`.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . tests/test_runner.tscn
```

The tests exercise real movement, collision areas, keyboard and swipe event dispatch, on-screen button input, timer expiry, respawn, pause, all four destination states, completion bonuses, and local score saving. Test profiles use a separate file and leave your normal saved best score unchanged. See [validation](docs/VALIDATION.md) for results and platform testing limits.

## License

Project code and original artwork/audio are provided under the [MIT license](LICENSE). The game uses Godot's built-in fallback font. Godot and its bundled components retain their respective licenses; include their notices with distributed builds. See [asset notes](assets/ASSET_NOTES.md).
