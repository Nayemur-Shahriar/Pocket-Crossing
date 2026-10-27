# Pocket Crossing M7 — Railway Crossing

## Install and run

Close Godot and back up your working M6 project. Extract `PocketCrossing_M7_Update.zip`
into the folder containing `project.godot`, allowing matching files to be replaced.
The update leaves project/export settings and all five campaign levels untouched.
The full project archive also includes the previously confirmed M6 preview fix.

Open `tools/railway_preview.tscn`. Click **Run Current Scene** in Godot's upper-right
toolbar (F6 if your keyboard has it). Expect **Railway Workshop**, immediately playing.
F5 / Run Project still opens the normal five-level Level Select.

The railway preview inherits the fixed M6 preview, selects `railway_demo.tres`, and
uses only `user://section_preview_profile.cfg` for writes. It shares that *test*
profile with the M6 road preview; it never redirects writes to `user://profile.cfg`.
Stopping the preview and running F5 starts a new process with the normal profile.
No save-schema migration, campaign level ID changes, or asset replacements were made.

## Architecture

- `RailwayTrackConfig`: reusable track settings with finite/range/fairness validation.
- `SectionLayoutCompiler`: keeps Railway Section descriptors in the compiled layout;
  railway is now playable. Water is still deferred. The static-board gate stays intact.
- `RoadLevel`: creates RailwaySection components from descriptors alongside road lanes;
  forwards collision to its existing signal, resets tracks on Retry, and applies slow effects.
- `RailwaySection`: drives all track clocks using the world's physics/pause clock.
  Holds new train batches until every current train clears and a common quiet window passes.
- `RailwayTrack`: SAFE -> WARNING -> PASSING state machine, seeded interval variation,
  track scenery and one reusable train. It emits collision rather than applying damage.
- `RailwayTrain`: original vector train, directional cab, Area2D collision. No death code.
- `RailwaySignal`: text, direction arrows, alternating lamps and flashing track tint.
  Visual feedback remains complete when audio is disabled. No new warning audio is included.

Train hit -> track -> section -> world collision signal -> existing deferred
CrossingGame handler. Shield, spawn invulnerability, life loss, respawn and game-over
therefore keep their existing rules. A long train does not repeatedly spend lives/shields
while remaining in the same overlap, matching the existing vehicle overlap behavior.

One train node is reused per track. The small track tree is rebuilt only when a run resets
or a level changes. No particles, per-frame scene creation or expensive shaders are used.
Signal drawing updates only when state/flashing changes; rail and train geometry are cached
by Godot between redraws. Physics runs only through the active world.

## The seven-row example

| Row (bottom to top) | Section |
|---|---|
| 0 | Start |
| 1 | Road, one existing vehicle lane |
| 2 | Safe resting area |
| 3 | Railway, eastbound track |
| 4 | Railway, westbound track |
| 5 | Safe resting area |
| 6 | Destination, four existing bays |

This is ONE example, not a sixth campaign level. Its stable score ID is
`example_railway_demo`. Coins/power-ups use the existing safe-row placement system.
Tracks do not count as pickup sites.

## Configuring a railway section

Open `resources/examples/railway_demo.tres` in Godot's Inspector. Expand **Sections**,
then the Railway entry, then **Railway Tracks**. Add one, two or three
RailwayTrackConfig Resources. Track array order is bottom to top.
Make a shared Resource unique before changing it for just one use.

Equivalent construction:

```gdscript
var east := RailwayTrackConfig.new()
east.direction = 1
east.speed = 420.0
east.warning_seconds = 3.0
east.initial_delay = 2.0
east.interval_min = 6.0
east.interval_max = 9.0
east.safe_delay = 3.0
east.train_length = 360.0
east.timing_variation = true

var west := RailwayTrackConfig.new()
west.direction = -1
west.speed = 560.0
west.warning_seconds = 3.5
west.initial_delay = 5.0
west.interval_min = 8.0
west.interval_max = 11.0
west.safe_delay = 3.0
west.train_length = 440.0

var railway := LevelSectionConfig.new()
railway.kind = LevelSectionConfig.Kind.RAILWAY_SECTION
railway.railway_tracks = [east, west]
# Insert railway in LevelConfig.sections; road/safe/start/destination are unchanged.
```

| Parameter | Meaning / enforced range |
|---|---|
| direction | +1 right, -1 left |
| speed | 80–1000 logical pixels/sec; independent of road difficulty multipliers |
| warning_seconds | 2–20 seconds before the nose enters the visible board |
| initial_delay | 0–120 seconds before the first warning is eligible |
| interval_min/max | 2–120 seconds, measured from **train fully clears to next warning eligibility**; min >= safe_delay, max >= min |
| safe_delay | 2–30 seconds, minimum local clear time between trains |
| train_length | 128–768 logical pixels |
| timing_variation | true samples seeded uniform min..max; false always uses min |

Warnings must additionally cover `(track_count + 1) * player_hop_seconds + 1.0`.
This protects reaction and traversal time if player hopping is configured unusually slowly.
Invalid configs are rejected before replacing the active world.

## Warning -> train -> safe cycle

1. Every track starts SAFE with its initial countdown. No train exists on-screen.
2. A due track can begin WARNING only when the section allows a new batch.
3. Lamps alternate and the track tints; text reads WARNING and arrows show direction.
4. The full warning elapses. The nose starts just outside the visible 1280px board.
5. PASSING remains visible for the complete crossing, including the trailing carriage.
6. Only after the tail leaves the opposite screen edge does SAFE return.
7. The next clear-to-warning interval is sampled. No missed timer creates a spawn burst.

Slow Traffic reduces train movement, not warning duration. It can extend PASSING and
therefore delays the next batch. Pausing freezes warnings, motion, flashes and timers.
Retry creates fresh SAFE tracks with fresh initial delays and no active old train.

## Independent tracks and fairness

Directions, speeds, lengths, warnings and requested intervals belong to each track.
Their countdowns run independently. All due tracks may start together at a batch boundary;
tracks that become due during a warning/passing batch wait for the next boundary.

After the entire batch clears, the section guarantees at least
`max(2 seconds, (track_count + 1) * hop_seconds + 1 second)` with **all tracks SAFE**.
This quiet period also applies at level start. It can extend initial_delay/intervals:
these settings are minimum eligibility times, not promises of exact wall-clock arrivals.
New warnings never join an already passing batch. This prevents interleaved schedules
from eliminating every safe crossing window while preserving independent track settings.

Future authors should place Safe Sections on both sides of railway groups, as in this
example. The local coordinator guarantees a window for its own section; it is not a
path planner for arbitrary future combinations of adjacent hazards without resting areas.

## Verification performed

Godot 4.5.2 Standard, Linux headless runtime and X11 software rendering:

- 88 railway checks: 1/2/3 tracks, both directions, warning-before-every-train over repeated
  cycles, safe windows, matching hitboxes, pooling, invalid configs, slow-player fairness,
  slow power-up, shield, real physics collision/life loss, pause during warning and passing,
  Retry, movement, pickups, destination completion and persistence.
- 135 existing regression checks: gameplay and input behavior.
- 103 existing campaign checks: Levels 1–5, spacing and migration.
- 62 existing progression checks: characters, coins, stars, scores, powers and save recovery.
- 68 section checks, updated only for railway becoming playable and water remaining deferred.
- Total: **456 passed, zero failed**.
- Normal profile, backup and temporary-file bytes were verified unchanged with populated
  sentinel campaign files in an isolated test data directory.
- Godot import/parser scan and resource-reference scan; normal Windows export-pack and
  headless startup. No GDScript errors in final runs.
- Rendered SAFE/WARNING/PASSING and 1280x720, 1920x864, 960x720, 800x360 UI layouts;
  touch-control containment checked. Physical Windows/Android testing is still required.

The progression suite intentionally emits diagnostics for corrupt/missing save fixtures.
Those are expected recovery tests. The railway suite stops test audio before shutdown,
so its final run has no resource-leak diagnostics.

## Exact PC manual tests

1. Open the updated project, wait for import. Run `tools/railway_preview.tscn` with
   **Run Current Scene**. It should immediately show Railway Workshop, 3 lives, 3:00,
   one road lane, two tracks, safe areas and four destinations. No startup Level Select.
2. Stay in the safe zone. Observe each track for at least 45 seconds. Every train must have
   a visible warning first. Eastbound and westbound trains differ in speed/length/timing.
   Observe an all-tracks-safe interval between batches. No train should pop into the center.
3. Turn sound off. Verify lamps, track tint, state text and arrows are still clear.
4. Use keyboard controls to cross the road and wait on both safe areas. Walk into a train
   without shield after spawn protection fades: exactly one life is lost, then respawn.
5. Collect the shield pickup (S). Meet a train after spawn protection fades: shield is consumed,
   lives stay unchanged. Leave its overlap before testing a second hit.
6. Collect Slow Traffic (T); observe a slower train while its warning remains full-length.
   Collect coins and check the wallet. Double rewards should work as before.
7. Pause once during WARNING and once during PASSING. Wait five real seconds each time.
   Resume: no timer skip, jump, surprise arrival or extra train. Also test focus loss.
8. Retry during a train run. Expect restored lives/time/score, empty effects, safe tracks,
   initial countdowns and no leftover moving train.
9. Reach all four bays. Expect Level Complete, stars, score and coin results. Retry and
   return-to-select should work. The preview catalog contains only its one example.
10. Close and rerun the preview; earned preview progress remains. Stop it and use F5:
    the normal campaign menu/profile must remain intact. Load Levels 1–5 and compare
    their existing appearance, traffic, controls and progression.
11. Optional three-track inspection: duplicate the example Resource, remove its one Road
    section and add a third track. This still fits seven rows. Set the preview's Example
    property to that duplicate. Do not add it to the campaign. Restore the supplied example
    after testing.

## Exact Android manual tests

Normal export presets intentionally exclude `tools/*`, so a regular APK still starts the
campaign and does not expose the railway test. For a railway test APK only:

1. Make a separate copy of the updated project folder. In that copy, Project Settings ->
   Application -> Run -> Main Scene = `res://tools/railway_preview.tscn`.
2. In the Android export preset Resources exclusions, remove `tools/*` (keep other exclusions).
   Export all resources. Use a separate test package identifier, for example
   `org.pocketcrossing.railwaypreview`, and a distinct APK filename. Keep your normal
   project's settings/package/signing intact. Export with your already-working Android setup.
3. Install the test APK. Confirm immediate Railway Workshop startup. The separate package
   plus preview filename isolates progress from your normal installed game.
4. Repeat PC steps 2–9 using split-touch buttons, then swipe mode. Test all four directions,
   held input, quick taps, two-thumb use and swipe release. No controls should cover tracks.
5. Test Android Back (pause/resume), Home/background for ten seconds, return, screen lock
   and return. No warning clock or train should jump while paused.
6. Check a small landscape phone and a wider screen: lamps, flashing tint, text, destinations,
   pickups and controls should remain visible. Observe frame pacing for at least two minutes.
7. Close/reopen the test APK and check preview progress. Separately launch the normal game
   and check its campaign save. Do not uninstall the normal app to perform this test.

No native Windows/Android build or physical-device performance certification is claimed.
The production project.godot and export_presets.cfg are unchanged.

## Deferred work / M9 boundary

The board remains 18 columns, 64px cells, origin (96,576), maximum seven rows. Trains
currently enter/exit the fixed 1280px logical viewport. M9 should supply camera-relative
spawn/despawn bounds and persistent off-screen simulation ownership, keeping this state
machine and data schema. Long layouts remain data-only. The compiler retains ordered
spans so the future world can place sections without changing progression IDs.

Water, boats, weather, camera movement, streaming, final level redesign and release work
are not included. Existing legacy Level 5 railway-like traffic remains unchanged; only
new Railway Sections use the new system. No levels or save keys were renumbered.

## Exact file manifest

```text
CREATED
docs/M7_CAMPAIGN_RESULTS.txt
docs/M7_IMPORT_RESULTS.txt
docs/M7_PACK_RESULTS.txt
docs/M7_PROGRESSION_RESULTS.txt
docs/M7_RAILWAY_RESULTS.txt
docs/M7_REGRESSION_RESULTS.txt
docs/M7_RENDER_RESULTS.txt
docs/M7_SECTIONS_RESULTS.txt
docs/RAILWAY_M7.md
docs/screenshots/railway_1920x864.png
docs/screenshots/railway_800x360.png
docs/screenshots/railway_960x720.png
docs/screenshots/railway_passing.png
docs/screenshots/railway_safe.png
docs/screenshots/railway_warning.png
resources/examples/railway_demo.tres
scenes/railway/train.tscn
scripts/actors/railway_train.gd
scripts/actors/railway_train.gd.uid
scripts/world/railway_section.gd
scripts/world/railway_section.gd.uid
scripts/world/railway_signal.gd
scripts/world/railway_signal.gd.uid
scripts/world/railway_track.gd
scripts/world/railway_track.gd.uid
tests/railway_tests.gd
tests/railway_tests.gd.uid
tests/railway_tests.tscn
tools/capture_railway.gd
tools/capture_railway.gd.uid
tools/capture_railway.tscn
tools/railway_preview.tscn
docs/RAILWAY_FILES.txt

MODIFIED
README.md
docs/ARCHITECTURE.md
docs/SECTION_ARCHITECTURE.md
scripts/data/railway_track_config.gd
scripts/data/section_layout_compiler.gd
scripts/world/road_level.gd
tests/section_tests.gd

No files removed. Compared with M6 plus the confirmed preview fix.
```
