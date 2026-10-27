# M12 — Bangladesh-inspired content and visual identity

## Status and installation

M12 content is implemented and locally validated against the completed M11 project. **Physical Android performance and Windows/Android hands-on playtesting remain acceptance checks.** Linux software-rendered screenshots and automated input/physics tests do not substitute for those checks. M13 has not been started.

This is ONE incremental update ZIP for the completed M11 project, not a standalone replacement project. Back up your project, close Godot, then extract/merge this ZIP directly into the folder containing `project.godot`. Replace matching files. Do not create a second nested PocketCrossing folder. No existing files need deleting. Open `project.godot` in Godot 4.5.2 and let imports finish. Run Project opens the same 15-level campaign with the new content. Normal saves are not included, moved, reset or migrated.

For testing without altering normal progression, open `tools/campaign_preview.tscn`, select its root, set **Starting Level** to 1–15 and click **Run Current Scene** in the toolbar (no F6 key required). It uses the existing isolated `user://campaign_preview_profile.cfg`. Return to Level Select within that preview to choose another level. Preview completed flags are artificial; test real unlock behavior separately with a disposable profile.

Open `tools/identity_gallery.tscn` and click **Run Current Scene** for a read-only art gallery. Its top selectors show Road vehicles, Train/boats or Environment props under Day, Evening, Night, Rain, Snow and Fog palettes. This gallery does not change saves. It displays stationary actors; rain/snow motion and full gameplay should be inspected in the campaign preview.

## Audit and preservation

The M11 baseline already had working traffic spawning and one TrafficVehicle actor, pooled trains with warning signals, pooled water platforms and WaterSupport, M9 terrain/camera/activation, M10 themes/weather, 15 authored campaign Resources, safe-section pickups, result cards/fireworks, controls and progression. M12 extends these components; it introduces no parallel movement, collision, water-support, railway-timing, camera, reward or save system.

Before M12, roads used the original car/van-based car/truck/bus/train visuals, railway trains and watercraft were drawn by their existing actors, and world art was mostly board/terrain plus weather. There was no reusable Bangladesh-inspired vehicle library or independent scenery profile. Existing assets and legacy rendering fallbacks remain available.

The M11 gameplay snapshot test compares every exported gameplay property recursively for all 15 campaign levels, excluding only new visual/environment fields and normalizing equivalent road vehicle IDs. Lane counts, section order, timings, speeds, gaps, warning lengths, platform lengths, destinations, pickups, time limits, score targets and progression IDs are preserved. Road selection arrays keep their lengths and the same size family in every slot, so this art change does not alter traffic RNG consumption or spacing. The first-five legacy Resources and older previews remain available.

The save implementation/schema, player, input router, power-up controller, WaterSupport, WaterLane, railway section, camera, activation manager, compiler, HUD, results/fireworks scripts, catalog order, project settings and Windows/Android export settings are unchanged. Two small game-state hooks control optional environment audio and scenery visibility.

## Added original content

There are **43 new SVG assets**, authored as small original vector art for this project. No real company logos, advertisements, national flags, commercial recordings or borrowed game artwork are used. The project MIT license applies; see `assets/IDENTITY_M12.md`.

- **Nine road types:** `cng`, `rickshaw`, `local_bus`, `small_car`, `microbus`, `pickup`, `delivery_van`, `medium_truck`, `large_truck`. CNG has a tapered three-wheel cabin; the cycle rickshaw has an exposed bicycle front and colored canopy. The bus and two cargo sizes use distinct body/window/load designs.
- **Two passenger-train variants:** Riverline (teal/cream) and Sunrise (terracotta/cream), each with separate original engine and coach art. Both directions reuse the same modular actor.
- **Five watercraft:** wooden boat, passenger boat, fishing boat, engine boat and squared ferry deck. Existing logs remain in some late-level lanes. Cabins/gear sit near the edges; the open deck and its highlight keep landing space clear.
- **25 props:** banana, palm, bamboo, leafy tree, bush, reeds, flowers, crop patch, dirt patch, grass patch, bamboo fence, fence, utility pole, lamp, bench, road sign, railway sign, signal box, market stall, tea stall, rural house, urban facade, bridge rail, ghat steps and finish gate. Captions/icons use existing English-capable fonts. Not every prop is placed in every level.
- **Seven environment profiles:** Green, Village, City, Highway, Railway, River and Crossroads. Crossroads combines scenery for the finale; Snow Way deliberately remains a fantasy snow variation.

## Campaign assignments

| # | Level | Environment | Theme | Road vehicle IDs |
| --- | --- | --- | --- | --- |
| 1 | Easy Road | green | day | cng, small_car |
| 2 | City Run | city | day | cng, delivery_van, microbus, rickshaw, small_car |
| 3 | Sunset Rush | city | evening | cng, delivery_van, microbus, rickshaw, small_car |
| 4 | Night Ride | city | night | cng, delivery_van, local_bus, microbus, rickshaw, small_car |
| 5 | Train Time | village | day | cng, local_bus, medium_truck, pickup, rickshaw, small_car |
| 6 | Double Track | railway | evening | cng, local_bus, medium_truck, pickup, rickshaw, small_car |
| 7 | River Hop | river | day | cng, local_bus, medium_truck, pickup, small_car |
| 8 | Rain Run | city | rain | cng, delivery_van, local_bus, microbus, rickshaw, small_car |
| 9 | River Rush | river | evening | cng, local_bus, medium_truck, pickup, small_car |
| 10 | Snow Way | village | snow | cng, local_bus, medium_truck, pickup, rickshaw, small_car |
| 11 | Fog Track | railway | fog | cng, local_bus, medium_truck, pickup, rickshaw, small_car |
| 12 | Wild River | river | rain | cng, local_bus, medium_truck, pickup, small_car |
| 13 | Midnight Run | highway | night | large_truck, local_bus, medium_truck, microbus, pickup, small_car |
| 14 | Danger Zone | highway | evening | large_truck, local_bus, medium_truck, microbus, pickup, small_car |
| 15 | Final Crossing | crossroads | night | large_truck, local_bus, medium_truck, microbus, pickup, small_car |

The table lists the union of a level's road IDs, not every lane's exact selection. `docs/M12_LEVEL_CONTENT.json` lists the level Resource paths and each track/water-lane visual assignment. The `.tres` files remain authoritative for individual lane arrays.

Train Time, Rain Run, Fog Track, Wild River, Midnight Run and Final Crossing use Riverline. Double Track, Snow Way and Danger Zone use Sunrise. River Hop introduces wooden/passenger boats; River Rush adds engine boats; Wild River adds ferry and fishing art. Levels 13–15 retain a legacy log lane while using ferry/engine boats; the final river also uses passenger boats.

## Architecture

**Layout** remains `LevelConfig.sections` compiled by M6/M9. **Weather/time** remains `LevelConfig.presentation` (`LevelThemeConfig`). **Place/scenery** is the new optional `LevelConfig.environment` (`EnvironmentProfile`). For example, the same City profile works with Day, Night or Rain without copying a layout or altering speeds.

EnvironmentProfile exposes ID/name, rest-surface style (Path/Paving/Bank/Gravel), ground tint, safe/edge colors, sign caption, prop/vegetation texture arrays, separate densities, guard rails and an optional ambience stream/volume. Missing or invalid profiles fall back to the previous environment art without preventing a level from loading. Changing a shared Resource affects every level that uses it; duplicate the Resource first for a level-specific variation.

One `EnvironmentLayer` belongs to RoadLevel. It draws a cached list of scenery for the camera's visible rows plus two rows of margin, rebuilding only when that window changes or a level/reset explicitly refreshes it. Placement uses profile ID and row, never the traffic RNG. Backtracking gives the same sites. Props are textures in a draw list, not individual scene/physics nodes. Railway signal rows are reserved; raised props stay outside playable footprints. Safe surfaces, road-edge/wear marks, Start ring and finish garden/gates are presentation only. Decorations draw behind hazards, pickups, signals and player. Camera movement, level length and section activation do not create duplicate environment owners or weather systems.

`VehicleVisualConfig` holds ID/name, texture, rendered dimensions, collision dimensions, spacing envelope and optional lane tint. `VehicleLibrary` lazily loads one catalog after imports; all types still use TrafficVehicle and TrafficLane. The catalog includes all four legacy IDs. Invalid lane IDs are rejected by validation. The new campaign substitutions preserve the original size families:

| Family | Render size | Collision | Spacing envelope |
| --- | --- | --- | --- |
| Small: car/CNG/rickshaw/small car | 116 × 58 | 92 × 38 | 144 |
| Medium: truck/microbus/pickup/van/medium truck | 140 × 58 | 116 × 38 | 144 |
| Large: bus/local bus/large truck | 210 × 58 | 186 × 38 | 214 |

`TrainVisualConfig` supplies engine/coach textures to RailwayTrain; it composes them inside the existing configured train length. `PlatformVisualConfig` supplies a texture to FloatingPlatform, stretched to the lane's existing platform length. Neither replaces motion or damage. Platform support still uses half-length minus 18 pixels, and the visible deck highlight marks that boundary. Null train/platform visuals preserve the old drawing; malformed assigned visuals fail configuration validation.

## Theme integration and performance

Ground/safe/edge surfaces use M10 theme colors and tint. Road markings and shoulder wear are inexpensive drawing. Snow surface details remain; Rain roads stay darker than blue water. New vehicles reuse lightweight head/tail lights, trains retain their warning signals and headlights, and scenery lamps use small drawn glows. No dynamic shadows or real-time reflections were added. Fog fades decorations more than critical actors. Boats retain the existing water-lane theme treatment and bright readable decks.

The 43 source textures are small (props generally 64 × 64, vehicles up to 210 × 58, boat source art 256 × 52). Imported textures and Resources are shared. Existing train/platform pools remain; road spawning is unchanged. There is one scenery node and one optional AudioStreamPlayer per world, no decorative collision bodies, no per-frame decoration regeneration, no per-prop lights/material instances and no extra weather particles. Tests bound the campaign's visible prop list to 36 entries. Weather remains camera-local under M10, independent of total level length.

The optional ambience stream is unassigned in shipped profiles. Supply your own original/licensed sound if wanted. It starts/loops only during active gameplay, pauses with Pause/results, stops on mute/menu and is replaced on level changes. No horn effects or default field recordings were added. The fireworks sound used in the automated audio-hook test is only a fixture, not a shipped ambience choice.

## Exact Godot Inspector steps

### Change a level's environment or weather

1. In FileSystem, open `res://resources/campaign/level_01.tres` (use `level_02.tres` through `level_15.tres` for other campaign levels). These are the M11 campaign files, not the older `resources/levels/` examples.
2. In Inspector expand **Section architecture**, then find **Environment**. Drag `res://resources/environments/village.tres` onto it, or use its Resource menu → Load and select a profile.
3. Keep **Presentation** as the independently selected M10 theme, or drag a preset from `resources/themes/` onto it. The older string **Theme** field is a legacy fallback, not the M10 theme Resource.
4. Save with Ctrl+S. Run the campaign preview at that level to inspect the result.
5. To tune scenery globally, open the profile `.tres` directly and change **Prop Density**, **Vegetation Density**, colors, **Rest Style**, **Guard Rails**, **Props**, **Vegetation** or **Sign Caption**. Densities are 0–1. The first two rest rows guarantee a landmark if density is positive; later rows use deterministic density selection. Set both densities to zero for no randomly selected side props; finish gardens/bank/rail landmarks remain authored presentation details.
6. To tune only one level, duplicate the profile in FileSystem, rename it, change its **Profile Id**, then assign that copy. Do not use a shared profile expecting only one level to change.

### Change a Road lane's vehicle types

1. Open the campaign Level Resource. Expand **Section architecture → Sections**.
2. Expand an element with **Kind = ROAD_SECTION**, then **Road Lanes**, then the desired LaneConfig element.
3. Edit the **Vehicle Types** String array using the exact IDs from the campaign table or gallery. You can keep the same array length to preserve the current weighting.
4. Leave **Speed**, **Spawn Min/Max**, variation, pattern and gap settings unchanged for an art-only edit. Replacing an ID with a larger size family can change practical difficulty; M12's shipped replacements preserve each original family.
5. Save and run that level. To add a new reusable type later, create/duplicate a `VehicleVisualConfig` Resource, assign texture/dimensions/envelope and a unique ID, then add it to `resources/vehicles/catalog.tres` → **Entries**. No per-type movement script is needed.

### Change boat/platform appearance

1. Level → **Section architecture → Sections** → a **WATER_SECTION** → **Water Lanes** → the target WaterLaneConfig.
2. Drag a Resource from `resources/water/visuals/` onto **Visual** (`wooden_boat`, `passenger_boat`, `fishing_boat`, `engine_boat`, `ferry`).
3. Keep platform length, speed, direction, spacing and phase unchanged. The visual adapts to the existing support length.
4. Clear **Visual** to use the legacy **Platform Type** drawing, including a log. Save and test landing/carrying/jumping off.

### Change train appearance

1. Level → **Section architecture → Sections** → a **RAILWAY_SECTION** → **Railway Tracks** → target RailwayTrackConfig.
2. Drag `resources/railway/visuals/riverline.tres` or `sunrise.tres` onto **Visual**.
3. Leave warning duration, train length, interval, speed, direction and delays unchanged. Clear Visual for legacy train art.
4. Save and inspect both warning and passing states. Different tracks can use different visual Resources without changing their independent timing.

### Optional ambience

Open an EnvironmentProfile, expand **Optional ambience — original/licensed audio only**, drag a supported original/licensed AudioStream onto **Ambience**, and set **Ambience Volume Db** (default −26 dB). Use a loop-friendly clip. Test Sound on/off, Pause, Retry and Level Select. No ambience data is saved in player progression.

## Automated and visual validation

Godot 4.5.2, Linux, headless regression tests and X11 software OpenGL Compatibility renders were used. **2,266 assertions passed, zero failed**, counting each suite once:

| Suite | Passed |
| --- | ---: |
| Core / input / controls | 135 |
| Phase 3 / campaign compatibility | 103 |
| Phase 4 / progression / corruption handling | 62 |
| M6 sections | 68 |
| M7 railway | 88 |
| M8 water + route | 73 + 3 |
| M9 long level + route | 142 + 2 |
| M10 themes + route | 109 + 6 |
| M11 campaign / results | 372 |
| M11 campaign physics routes | 60 |
| M12 identity / integration | 1,043 |

M12 checks all 15 level loads and baseline gameplay equivalence, 13 road variants including legacy IDs, all seven profiles × six themes, train/boat assignments, both vehicle directions, collision dimensions, train life-loss path, landing/carry/jump-off on every new watercraft, deterministic scenery, no gameplay-RNG consumption, backtracking, Retry, Next Level, menu cleanup, optional audio controls and untouched normal profile files. Existing M7/M8/M9 suites cover shield, unsupported water, transfer, timers and scrolling interactions. The route suite runs three ordinary-physics seeds per campaign level (45 routes) plus 15 checks for attainable three-star routes; it does not teleport through gameplay for those route results.

A fresh-cache editor import, external scene/resource reference audit, Windows and Android resource-pack export, and packed headless startup are recorded alongside tests in `docs/validation_m12/`. Pack export/startup checks are not native Windows EXE or Android APK/device certification.

Rendered and visually reviewed all 15 representative campaign positions, six-theme actor sheets and destination samples. The captured set contains **61 PNGs** in `docs/screenshots/m12_*`: campaign/menu/results/window-size views, destinations and gallery pages. Capture tools deliberately stage actors/camera for visibility and are separate from the physics-route tests. A capture-only stale scenery-window issue was fixed by refreshing decorations after scripted camera teleport while simulation is frozen. The shipped runtime refreshes normally as the camera moves. Small destination text was moved away from garden props after image review.

The headless audio fixture initially emitted an intermittent teardown-retention warning; the fixed-FPS test now allows the Dummy mixer 50 ms to release its stopped stream before quitting. Two final M12 test runs exited cleanly. Older Railway, Water and Phase 4 tests were also rerun with the normal clock and exited without resource-retention warnings. Older Railway, Water and Phase 4 tests were also rerun with the normal clock and exited without resource-retention warnings. This wait exists only in the test, not in gameplay. Render logs contain the software driver's unsupported V-Sync warning; the corrupted-save suite intentionally emits diagnostics while testing recovery. Neither is a GDScript/parser failure.

To rerun tests after importing, invoke Godot with `--headless --path <project-folder> --fixed-fps 60 tests/identity_tests.tscn`. The older test scenes remain in `tests/` and the log filenames identify each suite. Use a separate test user-data directory when running the whole suite; shipped tests use isolated profile paths.

## Windows hands-on checklist — not yet performed on Windows

1. Open the updated project in Godot 4.5.2; confirm no red parser/resource errors. Run Project and verify your existing coins, character, unlocked levels, stars and scores remain.
2. Use `tools/campaign_preview.tscn` → **Run Current Scene** for all 15 levels. Level 1 should remain clean; Level 2 shows CNG/rickshaw city roads; 3 sunset; 4 readable night vehicles; 5 village railway; 6 two-track station; 7 wooden/passenger boats; 8 rain city; 9 river/ghat; 10 fantasy snow; 11 fog railway; 12 fishing/ferry river; 13 night highway; 14 mixed route; 15 combined scenery and finish garden.
3. Use keyboard arrows/WASD and the existing controls. Move forward several sections, then backtrack far enough to reactivate passed sections. Check scenery stays deterministic, signals stay uncovered and no prop blocks any cell.
4. Take a road hit and a train hit; test a shield hit; observe every train's warning first. On each new boat type, land, ride, jump off and transfer; deliberately miss a platform once. Life loss, respawn and shield rescue should behave as before.
5. Collect coins and test Shield, Slow Traffic and Double Rewards. Confirm timer/lives/score and selected character remain correct. Pause during rain/snow, a train warning and while riding a boat; resume without motion/timer jumps.
6. Retry repeatedly from Pause/failure. Reach a destination and inspect Level Complete, stars/score/best/coins; Play Again; Next Level; Level Select. Exhaust lives and confirm failure has no Next Level. Beat an old high score and verify the existing 3–4 fireworks/sound; mute and repeat.
7. Compare gallery pages under all six themes, especially CNG vs rickshaw silhouette, night headlights, train warnings, ferry deck and wet road vs river. Inspect the game at 1280×720 and a smaller landscape window for HUD/touch-control overlap.
8. For optional ambience, assign a test clip to a duplicated profile and verify mute, pause/resume, completion, Next Level and menu cleanup. Exit/relaunch the real campaign and confirm progression persisted.

## Android hands-on checklist — not yet performed on a device

1. Export using the existing Android preset and your configured SDK/signing setup. Install an update on a test device while retaining its data; verify the old wallet, stars, high scores, unlocks and selected character survive. No save migration is required.
2. Test landscape levels **2, 4, 6, 7, 8, 12, 14 and 15**, including Night, Rain, railway and mixed water gameplay. Also sample 10 Snow and 11 Fog for visibility.
3. Test split-touch controls, taps, held directions and swipes near all screen edges. HUD and controls must remain screen-space; props must not cover buttons, player, warnings or rideable decks. Check actual phone-size vehicle silhouettes.
4. Play through and backtrack across activation boundaries. Pause/resume in water and during warnings, die/respawn, Retry several times, finish, Next Level and return to Level Select. Check no duplicate scenery/weather/audio or retained gameplay overlay on menus.
5. On a representative lower-end device, watch FPS/frame-time, memory and node count over several minutes of Rain + decorations + traffic, repeated Retry and Level 15 backtracking. Record device/GPU/resolution and sustained performance; investigate any new activation stutter or growing memory rather than treating desktop renders as a pass.
6. Test sound off/on and existing fireworks. Lock/unlock/background/foreground using your existing app behavior checks; re-open the game and verify saves. Visually compare Night/Fog in normal mobile lighting.

## Known limits

- Android acceptance remains open until real device FPS, memory, touch and visibility checks are done. Native Windows manual results are also pending. This update is implementation-ready for that validation, not a claim of completed release QA.
- Art is deliberately lightweight stylized vector content, not final high-detail production illustration. Boats use an open, flat deck to preserve support readability rather than tall cabins that obscure the player.
- Scenery follows the current 1280-wide, 18-column board framing while allowing arbitrary supported vertical level lengths. A future change to horizontal board dimensions should update scenery margins as well as existing terrain/UI assumptions.
- Decorations use fixed camera margins and deterministic placement, not authored per-cell obstacle placement. Density controls do not remove the shared finish/bank/railway landmark treatment.
- No ambience recordings ship, no complex gates/bridge mechanics were introduced, and no new hazards, weather physics, economy or progression features were added.
- The optional environment field is null in historical example Resources unless explicitly assigned; their old appearance is intentionally preserved.

## Files

`docs/M12_FILES.txt` contains every created and modified file relative to M11, including asset import sidecars, script UIDs, screenshots and validation evidence. New runtime code is limited to the visual-data classes/catalog and EnvironmentLayer. Modified runtime integrations are Vehicle, RailwayTrain, FloatingPlatform, their data configs, traffic envelope lookup, RoadLevel, board/terrain presentation and the two game-state/audio hooks. All 15 campaign `.tres` files receive presentation assignments. Read the exact manifest rather than copying only the artwork folders.
