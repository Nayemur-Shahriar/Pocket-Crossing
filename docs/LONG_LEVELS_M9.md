# M9 — finite long levels, camera, section activation

## Install and run

1. Close Godot and keep a backup of your working project.
2. Extract `PocketCrossing_M9_Update.zip` into the existing project folder **containing project.godot**. Merge the `scripts`, `resources`, `tests`, `tools`, and `docs` folders and replace the listed files. Do not place them inside another nested project folder.
3. Open your existing project in Godot 4.5.2 and let imports finish.
4. Open `tools/long_level_preview.tscn`, then click **Run Current Scene**. It starts **Long Crossing** immediately. F6 is optional; the toolbar button does the same thing.
5. **Run Project** (F5) still opens the five original campaign levels.

This update is based on your uploaded `PocketCrossing - Copy.zip`. It does not include a replacement `project.godot`, export presets, campaign catalog, or existing level resources. No save migration is needed. Preview writes use `user://section_preview_profile.cfg`; campaign writes remain `user://profile.cfg`. M6/M7/M8 previews remain available and share the isolated preview profile.

## Work already present before resuming

The compiler gate change, camera, terrain component, activation manager, integration wiring, 24-row preview and first integration suite were already written. The interrupted run completed with 133 checks passing and one failing. They were retained.

The remaining startup activation failure was fixed: newly registered entries no longer receive the retention margin until they have actually been initialized. Activation also waits until registration is complete, and safely skips collected pickup nodes after they are freed. Visual verification prompted moving the long-route destination counter into the footer. Further tests cover train contact, water falls, multiple bays and normal-input completion. The final run has 676 passing assertions/checks across nine suites.

## Architecture

The original `SectionLayoutCompiler` still assigns each ordered section a `first_row` and `row_count`. Its end row is `first_row + row_count - 1`. The unchanged `LevelConfig.cell_position()` maps cells to world coordinates: `grid_origin + Vector2(column, -row) * cell_size`. Long worlds extend upward into negative world Y; no teleportation between screens is used.

`CompiledLevelLayout.runtime_errors()` no longer rejects layouts for being taller than one screen. Malformed endpoints, obstacles, reachability, lane settings, railway warnings and water support constraints still validate before a working world is replaced. The old large-data safety caps (4096 total rows, 512 rows per section) remain; no small replacement cap was introduced. Layouts of 8, 17, 64 and 1024 rows were checked. The landscape renderer still uses 18 columns, 64-pixel cells and origin (96,576).

`RoadLevel` reuses TrafficLane, RailwaySection/Track/Train, WaterLane/WaterSupport, player, goals and rewards. Their gameplay is not copied into a new implementation. The original five campaign configurations and M6/M7/M8 examples are unchanged. Levels that fit retain their existing board art and fixed framing.

### Camera

`LevelCamera` is a Camera2D with fixed horizontal framing and a vertically smoothed target. In the existing 1280×720 logical canvas, the playable region is Y=108..616. Forward progress crosses a line at Y=400 before the target moves. The backward line is Y=528, so a small backward hop does not immediately reverse the camera. A hard visibility guard keeps the player clear of header/footer while smoothing catches up.

Bounds come from the Start sidewalk and destination garden, including their existing art margins. The camera cannot reveal space beyond those bounds. `CrossingPlayer.spawned` resets camera/window immediately for death, protected water rescue, Retry, and the next destination crossing. Pause disables the world subtree, including the camera.

HUD and split buttons remain on the original CanvasLayer. Swipe coordinates remain screen-space. Collision markers transform the player's world position into HUD coordinates. For scrolling routes, the destination counter moves to the footer rather than floating over intermediate roads or water.

### Activation

`SectionActivation` registers the original component nodes once per run. Its window covers the camera and player, plus four rows ahead and three behind. Already active nodes receive two more rows of retention to avoid toggling at an edge. The window updates on row-boundary changes, not by rebuilding nodes every frame.

- Road and water bands activate per lane, so a large section does not require full simulation.
- Railway sections activate as one batch, preserving the shared safe window and independent track clocks.
- Distant components are hidden and use `PROCESS_MODE_DISABLED`. Their collision objects use Godot's default removal behavior while disabled.
- Reentry restores inherited processing. Timers, vehicle positions, train state and platform identities are retained. No elapsed-time catch-up or accumulated spawn burst occurs.
- Player-adjacent lanes are always inside the window. Water motion runs before support and player movement.
- Collected rewards remain collected when revisiting a section. Retry rebuilds the original run state.

This is lightweight activation streaming, not file/chunk loading. Nodes remain allocated for the finite route. `LongLevelTerrain` draws only nearby rows using existing textures. Road/rail speed effects propagate only when their value changes, avoiding a full hazard scan every frame.

## Configure a level

Use the existing LevelConfig Resource and populate its ordered `sections` array. No new level-specific gameplay script is needed. Give each released level a stable `level_id` and choose its timer/rewards as before. `presentation` remains an independent theme Resource.

The new `resources/examples/long_crossing_demo.tres` is a complete example:

| Rows | Section |
| --- | --- |
| 0 | Start |
| 1–6 | Road, six lanes |
| 7 | Safe |
| 8–9 | Railway, two tracks |
| 10 | Safe |
| 11–12 | Road, two lanes |
| 13 | Safe |
| 14–16 | Water, three lanes |
| 17 | Safe |
| 18–21 | Road, four lanes |
| 22 | Safe |
| 23 | Destination, column 8 |

The demo has 240 seconds and one destination. Multiple destinations remain supported: reaching a non-final bay returns the player and camera to Start using the existing rules. Road direction/speed/gaps, railway timing and water platform settings stay in their existing Resources. Reorder/reuse section templates to change the world; do not manually assign global lane rows. Theme changes do not change the layout.

## Verification performed

Godot 4.5.2 Standard, Linux headless plus a software-rendered Compatibility viewport:

| Suite | Passed | Coverage |
| --- | ---: | --- |
| Original integration | 135 | Gameplay, keyboard/touch/swipe routing, app pause, score/lives |
| Campaign | 103 | Existing five levels, progression, traffic spacing |
| Rewards/progression | 62 | Coins, stars, characters, power-ups, save corruption/recovery |
| Section architecture | 68 | Compiler, validation, legacy compatibility; old long-layout rejection expectations updated |
| Railway | 88 | Warning cycles, one/two/three tracks, both directions, damage/shield |
| Water | 73 | Support, movement, falls, pools, pause/retry, save isolation |
| Water route simulation | 3 | Existing four-bay water routes |
| Long-level integration | 142 | Placement, bounds, dead zone/backtracking, activation, clocks, real scrolled collisions, rescue, freed pickups, completion and multiple bays |
| Long mixed-route playthrough | 2 | Ordinary hop requests and real physics across all 24 rows; seeds 42 and 2026, three lives remaining |
| **Total** | **676** | **Zero failed checks** |

The progression suite intentionally creates invalid save data and a failed-save condition; its logged parse errors belong to those recovery tests. Clean editor import and resource-reference checks found no GDScript/parser or missing-reference errors. A Windows-preset resource pack was built and launched headlessly. This checks packaged resources; it is not a Windows executable/device test.

The world was rendered at Start, railway, water, intermediate rest areas and the final destination. Viewport/control layout checks covered window sizes 1280×720, 1920×864, 960×720 and 800×360. The software renderer reports an unsupported VSync-setting warning; no gameplay/render script errors occurred. Screenshots and test logs are included in docs. No physical Windows/Android device test was available here.

## Exact manual PC tests

1. Run `tools/long_level_preview.tscn` with **Run Current Scene**. Confirm the title is **Long Crossing**, the timer is 4:00, and the player starts on the bottom sidewalk.
2. Use arrows/WASD. Cross the first road lanes: the camera should start following upward, keeping horizontal framing steady. Stop: it should settle without jitter.
3. From a safe area, move back one row. The camera should usually hold. Move several rows back: earlier areas should become visible and active again, with no missing terrain or duplicate spawns.
4. At rows 8–9, observe railway warnings before trains. Wait through a batch and cross. Move away and return; signals/trains should resume coherently.
5. At rows 14–16, ride boats/logs in both directions, hop between them and onto the safe banks. The camera must not disturb platform carrying.
6. Fall into water without a shield. Confirm one lost life, existing respawn feedback and an immediate camera return to Start. Repeat with a shield; confirm rescue without a lost life.
7. Collide with road traffic and a train after scrolling. Confirm one loss per hit, a correctly positioned impact effect, and normal shield protection.
8. Collect a coin far above Start, then backtrack and revisit. It must not reappear. Verify the wallet after stopping/relaunching the preview.
9. Pause during train warning, train passing and platform riding. Camera, hazards, player and timer should freeze. Resume must not produce a timer catch-up burst.
10. Use Retry both while paused and after failure/completion. The camera, hazard clocks and run counters should reset; saved coins/results should remain.
11. Reach the final numbered bay at row 23. Confirm Level Complete, score/stars, Retry and Return to Level Select. At the destination the camera must stop before blank space appears above the garden.
12. Stop the preview. Use **Run Project** and test Levels 1–5, character selection, sound, pause, coins and progression. Their original layouts should remain unchanged. The campaign wallet should not contain coins earned only in the preview.
13. Run the existing section, railway and water previews once each. Their fixed layouts should still work.

## Exact manual Android tests

Use your normal project/export workflow to test campaign compatibility. To put the dedicated long preview on a device, make a temporary project copy. In that copy only, set the main scene to `tools/long_level_preview.tscn`, remove `tools/*` from the Android preset's export exclusions, and use a separate package ID such as `org.pocketcrossing.m9preview`. Export a debug APK using your installed SDK/signing setup. These are test-copy changes; do not change the campaign project's main scene or package ID.

On the device, repeat PC tests 2–11 with split-touch buttons and then swipes. Hold directions, switch thumbs, pause with Android Back, background/resume the app, and verify no stuck input. Check that controls stay inside the display safe area while the world scrolls. Ride a platform during camera movement and after pause/resume. Restart the app and check preview wallet/results persist. Check frame pacing on your actual phone, especially near rail/water transitions.

## Preserved and remaining limits

The campaign, assets, keyboard/swipe/split-touch input code, railway/water mechanics, wallet/characters, power-ups, scoring, lives, timer, destination rules and save schema are retained. No progression reset or migration is performed. No new final campaign levels, weather, endless generation, checkpoints or release/store changes are included.

Horizontal framing remains the existing landscape board; M9 extends length only. The large-data validation caps remain. All finite-route component nodes are allocated at load/reset, so memory and startup work still scale with authored length even though active simulation/rendering are bounded. Extremely large production routes should be profiled on target phones before deciding whether actual lazy loading is necessary. Distant simulation freezes intentionally rather than continuing offscreen. Content designers remain responsible for safe rest areas, readable hazard combinations and a suitable timer for the route length.

See `M9_FILES.txt` for every created/modified deliverable file.
