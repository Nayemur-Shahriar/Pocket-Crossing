# Pocket Crossing M8 — Water Crossing

## Continue/resume audit

Before this resumed run, the M8 implementation already existed: WaterLaneConfig extensions,
FloatingPlatform, WaterLane, WaterSupport, player hop/landing adapters, existing damage-flow
integration, water demo/preview, and an initial water test suite. That run reported 71 passes
and two failures. No completed implementation was rebuilt.

The remaining failures were test synchronization: after a long synchronous simulation,
a wall-clock timer finished while the first hop was still in flight. Tests now wait for
physics frames. The resumed run completed regression checks, normal-hop route tests,
visual inspection, resource/import checks, export-pack startup, documentation and packaging.

## Install and preview

1. Close Godot and back up the existing working M7 project.
2. Extract `PocketCrossing_M8_Update.zip` into the folder containing `project.godot`.
   Replace matching files. This update does not replace project.godot or export_presets.cfg.
3. Reopen Godot and wait for import.
4. Open `tools/water_preview.tscn` and click **Run Current Scene**. F6 is optional.
5. Expect Water Workshop to open directly with three lanes: small boats moving right,
   long boats moving left, and logs moving right.

The preview uses the already-fixed section preview and `user://section_preview_profile.cfg`.
It shares the isolated *test* profile with the M6/M7 previews; the normal campaign writes
`user://profile.cfg`. F5 / Run Project still opens Levels 1–5. No save migration was needed.
A full source archive is an alternative to the update, not a second required installation.

## Architecture and configuration

Water Sections remain ordered `LevelSectionConfig` Resources. The number of lanes is the
length of their `water_lanes` array. The compiler now considers water supported, retaining
section row descriptors. `RoadLevel` instantiates one reusable `WaterLane` for each row and
connects the single `WaterSupport` adapter to the existing player. Railway/road components
continue to work alongside these lanes. No campaign level or theme Resource was changed.

- `WaterLaneConfig`: validated movement, size, spacing, type and variation data.
- `WaterLane`: fixed platform pool, lane-wide movement, recycling, support lookup and ripples.
- `FloatingPlatform`: original lightweight deck artwork and horizontal support bounds.
- `WaterSupport`: support ownership, carrying, water-aware hop targets and landing checks.
- `CrossingPlayer`: optional callbacks, empty on normal road/rail levels. Existing keyboard,
  touch, swipe, hop easing, buffering and destination signals remain in use.
- `CrossingGame`: water hazard forwards to the existing collision/shield/life-loss handler.
  Only the protected-fall rescue behavior is specific to water.

Example, matching the demo's first lane:

```gdscript
var boat := WaterLaneConfig.new()
boat.direction = 1
boat.platform_speed = 50.0
boat.platform_type = "small_boat"
boat.platform_length = 224.0
boat.spawn_min = 5.2
boat.spawn_max = 6.0
boat.minimum_spacing = 32.0
boat.spawn_variation = true
boat.speed_variation = 0.05
boat.variation_period = 10.0

var water := LevelSectionConfig.new()
water.kind = LevelSectionConfig.Kind.WATER_SECTION
water.water_lanes = [boat]
# Add further independent WaterLaneConfig Resources to this array.
# Insert water into LevelConfig.sections between suitable safe areas.
```

In the Inspector, open `resources/examples/water_demo.tres`, expand Sections -> Water ->
Water Lanes. Each lane can be made unique and edited independently. Existing M6
`boat_placeholder` is accepted as the original boat visual for compatibility.

| Setting | Meaning / validation |
|---|---|
| direction | +1 right, -1 left; describes both the lane flow and its platforms |
| platform_speed | 20–120 logical pixels/sec |
| platform_type | boat_placeholder, small_boat, long_boat, log |
| platform_length | 192–384 logical pixels; the highlighted central deck is safe |
| spawn_min/max | Ordered nominal intervals, 0.5–12 seconds |
| minimum_spacing | Minimum empty water between platforms, 24–96 pixels |
| spawn_variation | Seeded variation between min/max pitch; false uses fixed minimum pitch |
| speed_variation | Shared sinusoidal lane-speed variation, 0–12%; platforms cannot overtake |
| variation_period | 4–30 seconds |

Nominal platform center pitch is `max(length + minimum_spacing, speed * interval)`.
The maximum empty gap must not exceed 96 pixels. Intervals smaller than the required safe
spacing are lengthened automatically. Shared speed variation changes the actual interval
slightly while preserving the spatial gaps. These are spatially scheduled lanes, not timers
that accumulate missed spawns and then burst.

Validation also rejects nonfinite values and platform travel during one player hop greater
than one quarter of the usable deck length. These checks catch obviously unsafe parameters;
they are not a universal solver for every future custom layout.

## Water hazard and stable riding

The player is never reparented onto a platform. Grounded support holds a reference to the
current platform. Physics order is explicit: platforms move first (-20), support applies
the platform's horizontal motion (-10), then the existing player hop runs (0).

Grounded carrying updates the player's continuous X and its nearest logical column.
Beginning a hop clears support. Airborne motion is the existing hop trajectory; the player
is not pulled by the departing platform. Water hop targets retain continuous X instead of
snapping to an old grid center. Landing on dry land returns to the normal grid position.

At water landing, the player's center must be inside a platform's usable deck, with an
18px margin at both ends. That margin fits the player's 26px body on the visible deck.
The platform under the final position becomes the new owner. Landing validation runs
**before** step scoring, pickups and a buffered next hop. Airborne players are not tested
against open water mid-hop. A grounded unsupported player, or a rider passing the playable
horizontal center bounds (96..1184), triggers the existing hazard flow.

Shield is consumed through the normal collision handler and the protected player is returned
to spawn. Active spawn invulnerability also rescues to spawn without losing a life. This
avoids leaving a protected player standing in open water. Without protection, the existing
life-loss, feedback, respawn or game-over behavior applies. There is no second lives system.

Slow Traffic still affects road vehicles and trains only. Water platforms ignore it.
Coin/score multipliers, selected skin and all save behavior remain unchanged. Demo pickups
are on safe land only; RewardField remains separate from water layout for future placement.
Platform-attached collectible placement is not implemented in this milestone.

## Spawning, recycling and cleanup

Each lane prefills a continuous route with a small bounded pool. Platforms are distributed
using seeded configured pitches. Every platform in a lane shares its speed, preserving gaps.
After a platform fully clears the far screen edge plus a 64px margin, the same object is
moved behind the last platform upstream. No player can ride that recycling jump: the playable
boundary is reached earlier and triggers normal hazard handling.

There are no platform physics bodies, per-frame scene creation, shaders or particle systems.
Support uses small horizontal interval checks; water ripples redraw at 10 Hz. Platform
art redraws on setup. The game retains the existing GL Compatibility renderer.

Pause disables the world, freezing lane motion, support, hops and timers together.
Death/respawn emits support reset. Retry clears support before freeing every old water lane
and its pool, builds fresh seeded lanes and resets the player/timers. Level changes also
clear the lane map and optional player callbacks. On non-water levels both callbacks are
empty. Completion and Level Select disable simulation through the existing game state flow.

## Demo layout and difficulty

| Row | Content |
|---|---|
| 0 | Start |
| 1 | Safe launch bank with pickups |
| 2 | Small boats, right, 50 px/sec, 224px long |
| 3 | Long boats, left, 64 px/sec, 288px long |
| 4 | Logs, right, 42 px/sec, 224px long |
| 5 | Safe destination bank |
| 6 | Existing four destinations |

Three water lanes and safe banks take the available space, so this single demo omits a road.
Road and railway gameplay remain in their existing campaign/examples. The demo is deliberately
readable and forgiving; it is not a final difficulty-balanced campaign level. It is not
added to the campaign or used to renumber existing progression IDs.

## Automated validation

Final results on Godot 4.5.2 Standard:

| Suite | Passed | Failed |
|---|---:|---:|
| Water behavior | 73 | 0 |
| Unmodified demo routes, normal hops | 3 | 0 |
| Existing gameplay/input regression | 135 | 0 |
| Existing campaign | 103 | 0 |
| Existing progression/save recovery | 62 | 0 |
| M6 sections, water support expectation updated | 68 | 0 |
| M7 railway | 88 | 0 |
| **Total** | **532** | **0** |

Water tests cover 1/2/3 lanes, both directions, different speeds, two-minute spacing/recycling
simulations, stable rider offsets, boat/log support, transfers, dry-land landing, unsupported
water entry, damage before score/buffered movement, both boundaries, invulnerability/shield,
Slow Traffic exclusion, pause/resume, Retry cleanup, coins/multipliers, completion, Next Level
to railway, return/reentry, and save isolation. Three additional seeded runs complete all
four destinations with normal hops and three lives, without teleporting/repositioning actors.
They demonstrate reachable routes; they do not prove all possible authored configurations.

Existing suites verify keyboard, split-touch/swipe routing, progression and corrupted-save
recovery. Corrupt-save diagnostics and the intentionally failed-save fixture are expected
in that suite, not new gameplay errors.

Also checked: GDScript import, static resource references, Windows export-pack and headless
pack startup; 1280x720, 1920x864, 960x720 and 800x360 rendered landscape layouts and control
containment. Final water runs have no parser/runtime errors or resource-leak diagnostics.
Physical Windows/Android device testing and native performance profiling remain manual.

## Exact manual PC tests

1. Run `tools/water_preview.tscn` with **Run Current Scene**. Confirm immediate Water Workshop
   gameplay, three differently styled water lanes, safe banks, four bays and 3:00 timer.
2. Use arrows/WASD to reach the first bank. Wait for a light deck and hop onto its middle.
   Release all keys. You should move with the boat without drifting across its deck.
3. Hop left/right on a deck, then hop onto the opposite-moving lane and the logs. Carrying
   should transfer once and follow the new direction. Hop back to a bank: carrying stops.
4. After spawn protection fades, deliberately land in a gap. Expect one lost life and normal
   respawn; a buffered second hop must not skip the fall or award forward points for it.
5. Collect Shield (S), then fall. Shield disappears, lives stay unchanged, and the player
   returns to spawn. Repeat after protection fades without shield: now one life is lost.
6. Stay on a platform until carried past the left/right playable boundary. Expect a normal
   fall/respawn, not an infinite ride or a teleport when that platform recycles.
7. Collect Slow Traffic (T). Boats/logs keep their normal speed. Double reward pickup (2)
   still doubles a subsequently collected coin. Coins should only appear on safe land.
8. Pause while riding, wait five seconds and resume. Position and timer must not jump.
   Repeat while airborne. Test focus loss and returning to the game.
9. Retry while riding and after falling. Expect fresh platforms, restored lives/time,
   no leftover attachment, no duplicate lanes and no old moving objects.
10. Reach all four destinations. Confirm Level Complete, stars, best score and coins.
    Retry and Return to Level Select must work; returning to preview select is normal.
11. Close/reopen the preview and check saved test progress. Stop it, then Run Project/F5:
    normal campaign progress, wallet, selected character and Levels 1–5 remain intact.
12. Run the existing railway preview and road section preview. Recheck train warnings,
    shield collision and road movement. Optional: duplicate the water demo Resource and
    reduce its Water Lanes array to one/two entries, then assign it to the preview's Example
    field. Restore the supplied demo afterward; do not add these tests to the campaign.

## Exact manual Android tests

The production export presets exclude `tools/*`. A normal APK still opens the campaign.
For an isolated water test APK, use a **separate copy** of the updated project:

1. Project Settings -> Application -> Run -> Main Scene:
   `res://tools/water_preview.tscn`.
2. Android Export -> Resources: remove `tools/*` from exclusions in the test copy only.
   Keep exporting all resources. Use a separate test package identifier such as
   `org.pocketcrossing.waterpreview` and a distinct APK output filename. Keep the normal
   project, package and signing settings unchanged; do not uninstall your normal game.
3. Export/install using your already-working Android setup. Confirm direct Water Workshop
   launch. Its separate package and preview filename isolate progress from the normal app.
4. Repeat PC tests 2–10 with split-touch buttons. Test each direction, taps, held controls,
   two-thumb movement and quick direction changes while riding and hopping.
5. Switch to swipe mode. Test up/down/left/right swipes from the board, including swipe
   release, short gestures and repeated gestures. One swipe should trigger one hop.
6. Test Back/pause, Home/background for ten seconds, return, lock/unlock and resume.
   Riding, boat motion and the timer must resume without a jump or duplicate damage.
7. Check a small landscape screen and a wider device: light decks, gaps, player, banks,
   destinations and touch buttons remain readable. Play for two minutes to inspect frame
   pacing and recycling. Native device performance is not certified by the headless tests.
8. Close/reopen the test APK and check preview progression. Separately launch your normal
   game and verify the existing save. Do not copy preview settings into the production project.

## M9 boundary / known limitations

The current board remains 18 columns, 64px cells, origin (96,576), maximum seven rows.
Water's spawn/recycle width is the fixed 1280px logical canvas. M9 should provide world/camera
bounds, section activation and persistent off-screen ownership rather than changing the
player's support semantics or stable progression IDs. Water Section arrays can contain more
lanes in future; layouts exceeding seven rows are still rejected at runtime today.

No scrolling, streaming, weather, night effects, final level redesign, Bangladesh-content
pass or release work was added. Water collectibles remain land-only in the demo. Custom
future combinations still need route playtesting; validation bounds are practical safeguards,
not a universal fairness proof. No save migration was introduced.

## Exact file manifest

```text
CREATED
docs/M8_CAMPAIGN_RESULTS.txt
docs/M8_IMPORT_RESULTS.txt
docs/M8_PACK_RESULTS.txt
docs/M8_PROGRESSION_RESULTS.txt
docs/M8_RAILWAY_RESULTS.txt
docs/M8_REGRESSION_RESULTS.txt
docs/M8_RENDER_RESULTS.txt
docs/M8_ROUTES_RESULTS.txt
docs/M8_SECTIONS_RESULTS.txt
docs/M8_STATIC_RESULTS.txt
docs/M8_WATER_RESULTS.txt
docs/WATER_M8.md
docs/screenshots/water_1920x864.png
docs/screenshots/water_800x360.png
docs/screenshots/water_960x720.png
docs/screenshots/water_overview.png
docs/screenshots/water_riding.png
resources/examples/water_demo.tres
scripts/actors/floating_platform.gd
scripts/actors/floating_platform.gd.uid
scripts/world/water_lane.gd
scripts/world/water_lane.gd.uid
scripts/world/water_support.gd
scripts/world/water_support.gd.uid
tests/water_route_tests.gd
tests/water_route_tests.gd.uid
tests/water_route_tests.tscn
tests/water_tests.gd
tests/water_tests.gd.uid
tests/water_tests.tscn
tools/capture_water.gd
tools/capture_water.gd.uid
tools/capture_water.tscn
tools/water_preview.tscn
docs/WATER_FILES.txt

MODIFIED
README.md
docs/ARCHITECTURE.md
docs/SECTION_ARCHITECTURE.md
scripts/actors/player.gd
scripts/core/game.gd
scripts/data/section_layout_compiler.gd
scripts/data/water_lane_config.gd
scripts/world/road_level.gd
tests/section_tests.gd

No files removed. Compared with delivered M7. Saves/builds/cache excluded.
```
