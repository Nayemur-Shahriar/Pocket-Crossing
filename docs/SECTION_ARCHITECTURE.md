> M9 update: Long ordered section layouts now run with camera follow and section activation. See LONG_LEVELS_M9.md. Rail and water use the working M7/M8 components. The M6 notes below are historical: the seven-row restriction and configuration-only hazard statements no longer apply.

> Historical M6 guide. M7 enables Railway Sections; see RAILWAY_M7.md for current railway behavior. Water and oversized layouts remain blocked.

# Advanced section architecture — Pocket Crossing

## Install

Close Godot and back up your working Phase 4 project. Extract the CONTENTS of
PocketCrossing_Sections_Update.zip into the folder containing project.godot,
replacing matching files. Reopen Godot 4.5.2 and wait for import. F5 still runs the
same five campaign levels. Export a fresh APK using your existing settings.
The patch excludes project.godot and export_presets.cfg. Keep the existing Android
package ID/signing key and update-install rather than uninstalling to retain saves.

## Inspection findings and approach

The current project used LevelConfig.lanes, with each LaneConfig carrying a global
row. RoadLevel created TrafficLane instances and destination nodes; player/grid,
controls, coins, powers and saves were already modular. Save keys were stable IDs.
Greenway's special artwork was selected by level_number == 1. The world renderer,
HUD and traffic entry positions still used a fixed 1280x720 board.

This milestone extends those systems. It adds authoring resources and a compiler,
not another player, traffic spawner, scoring system or progression database.
Existing flat-lane resources remain supported and retain their object identity.

## Architecture

| Component | Role |
| --- | --- |
| LevelConfig | Level ID, time/lives/scoring/rewards; optional ordered sections and presentation resource |
| LevelSectionConfig | START, ROAD, SAFE, RAILWAY, WATER or DESTINATION band; type-specific data |
| LaneConfig | Reused road vehicle types, direction, speed, spawn range, variation and safe gaps |
| RailwayTrackConfig | Data-only direction, train speed, warning and train interval range |
| WaterLaneConfig | Data-only platform type/direction/speed and spawn interval range |
| LevelThemeConfig | Separate environment/time-of-day/weather metadata and optional ground tint |
| SectionLayoutCompiler | Validate section order, calculate contiguous rows and produce transient runtime data |
| CompiledLevelLayout | Runtime config, section spans, safe rows, errors and deferred feature requirements |
| RoadLevel | Existing world adapter; builds existing lane/destination components from compiled data |

The array is ordered from the player's starting area toward the destination.
Grid row zero is at the bottom; increasing row numbers move upward. Each section
occupies full-width horizontal rows. ROAD row count is road_lanes.size(); RAILWAY
is railway_tracks.size(); WATER is water_lanes.size(). SAFE has configurable
safe_rows; START and DESTINATION each occupy one row. There is no redundant
lane_count field that can drift away from the actual lane data.

The compiler accumulates rows, clones each road lane before assigning its global
row, translates section-local obstacles, sets the start and goal cells, and keeps
section descriptors for future world adapters. It does not mutate source resources.
The derived LevelConfig is transient and is never saved over your editable file.
RoadLevel, TrafficLane, DestinationZone, CrossingPlayer and the same game controller
then handle actual play. No per-section copy of traffic or collision logic exists.

## Valid data versus playable data

These are deliberately separate:

- `config.validation_errors()` checks authoring consistency, endpoints, dimensions,
  lane/track/platform parameters, destination uniqueness and static reachability.
- `config.compile_layout()` returns the structured derived result.
- `config.playability_errors()` also checks whether the current runtime supports it.

Railway and water resources validate as authoring data, but new RAILWAY/WATER
sections cannot run in this milestone. They are never silently treated as safe
walkable ground. The current road-only runtime supports the existing 18-column,
64px-cell board at origin (96,576), up to seven total rows including endpoints.
Larger valid layouts are explicitly blocked until the camera/world milestone.

This runtime limit is not a restriction on section combinations. Long mixed
recipes compile into section descriptors now. Invalid/unsupported configuration
is rejected before replacing a working world. An authored future layout added to
a catalog is disabled and labelled LAYOUT ONLY, with reasons in its tooltip.
The example preview uses the same gate. No camera scrolling, streaming, trains,
boats, carrying, drowning, weather effects or new campaign levels were implemented.

The existing Phase 3 railway prototype remains playable through legacy flat-lane
compatibility. Its behavior was not extended or moved into the new railway schema.
The old `pattern = railway` remains valid only in that legacy route; new ROAD
sections reject railway patterns and train vehicles so they cannot bypass the gate.

## How to configure a level

Start with resources/examples/road_sections_demo.tres. This non-campaign example is:

```text
START                1 row, spawn column 8
ROAD                 2 lanes, independently configured directions/speeds/gaps
SAFE                 1 resting row
ROAD                 2 lanes
DESTINATION          1 row, columns 2, 6, 11, 15
```

The resource references reusable files under resources/sections/. Its sections
property is a typed Array[LevelSectionConfig]. A minimal code equivalent is:

```gdscript
var level := LevelConfig.new()
level.level_id = "my_stable_route_id"
level.time_limit = 110.0
level.sections = [
    load("res://resources/sections/start.tres"),
    load("res://resources/sections/road_pair.tres"),
    load("res://resources/sections/safe.tres"),
    load("res://resources/sections/road_pair.tres"),
    load("res://resources/sections/destination.tres"),
]
level.presentation = load("res://resources/themes/day.tres")
var layout := level.compile_layout()
print(layout.errors)
print(layout.runtime_errors())
```

For designer editing:

1. Duplicate the example .tres as your own resource and give it a unique stable
   level_id. Do not rename an already-released level ID: it is the save key.
2. In its Sections array, arrange LevelSectionConfig resources in traversal order.
   START must be first and unique; DESTINATION must be last and unique.
3. For ROAD, add one LaneConfig per lane. Configure vehicle_types, direction, speed,
   spawn_min/max, minimum_clear_gap, minimum_gap_seconds, speed_variation and
   variation_period. The old lane.row field is ignored and generated for sections.
4. For SAFE, set safe_rows. blocked_cells use local (column,row) coordinates and are
   permitted only inside START/SAFE. A full-width obstruction is rejected.
5. Set spawn_column in START and destination_columns in DESTINATION. When sections
   is populated, the legacy level lanes/obstacles/spawn_cell/goal_row/goal_columns
   fields are ignored in favor of section data. Time, lives, scoring, rewards and
   progression ID continue to come from LevelConfig.
6. Assign presentation independently. Time-of-day/weather fields are metadata only.
   Ground tint is supported; changing a tag to Night or Rain does not create those
   lighting/weather systems or change gameplay.
7. Validate/playtest the resource in the isolated preview before considering it for
   a campaign. This milestone does not append examples to campaign.tres.

Shared resource references are intentional: both road bands in the supplied
example reuse road_pair.tres. Editing that shared template changes both bands.
To vary one band independently, duplicate the section and its lane resource files
and reference those copies (or make unique resources in Godot's Inspector).
Explicit section_id values are optional; if assigned, they must be unique in that
level. This allows stable author labels without forcing duplicate resources just
to reuse an unnamed template. Compilation always gives every occurrence its own
runtime lane instances.

## Future configuration examples

resources/examples/mixed_layout_data_only.tres contains:

```text
Start → Road(2) → Rail(2) → Safe → Water(2) → Road(2) → Rail(2) → Destination
```

Tests also validate Road→Rail→Road, Road→Water→Rail, Road→Rail→Water→Road and
Road→Rail→Water→Rail→Road, surrounded by START/DESTINATION. Reordering data changes
section spans; no new controller code is required. Rail sections accept 1–3 track
resources, each with independent direction, speed, warning_seconds and
interval_min/max. Water lanes expose platform_type, direction, platform_speed and
spawn_min/max. These are schemas only, not gameplay or safety guarantees about
future moving hazards.

Difficulty therefore has independent per-lane speed/density/gap/type settings,
per-track frequency/warnings, platform speeds and a level time limit. The existing
smooth global difficulty ramp is retained as an additional layer, not the sole
control. Increasing fields has not been used to rebalance the current campaign.

Future world/camera adapters can consume the section spans and safe-row metadata.
Nothing in save data or rewards requires those layouts to remain on one screen.
Authoring has a protective cap of 4096 rows and 256 columns to bound validation;
there is no chunk streaming implementation in this milestone.

## Preserved systems and migration

- Same five campaign entries, names, IDs, lane configurations and completion flow.
- Existing player movement/collision, traffic behavior, lives, timer and scoring.
- WASD/arrows, Android split buttons and swipe routing; no input action changes.
- Coins, stars, scores, unlocks, cosmetic characters, power-ups and local profile.
- Existing assets, landscape orientation, project settings and export presets.

No save migration was required: SaveData is byte-for-byte unchanged from Phase 4.
Empty sections means the original flat-lane format, so old .tres files keep working.
The only supplied level-resource change is adding `classic_greenway_art = true`
to level_01.tres. BoardArt reads that explicit flag instead of checking the level
number. This preserves Greenway while allowing any new level number to use sections.
LaneConfig's inspector row range was widened for derived layouts; current row values
are unchanged. New schemas validate unsupported content before any world mutation.
The HUD's deferred-focus argument was made tolerant of a control freed between
screen transitions, fixing an error exposed by rapid campaign tests.

## Validation completed

Godot 4.5.2 on Linux:

- 135 existing gameplay/input checks passed.
- 103 existing campaign/transition/traffic checks passed.
- 62 Phase 4 reward/save checks passed.
- 68 section compiler/runtime/integration checks passed.
- Total: 368 checks, zero test failures.
- No GDScript/parser errors in final editor import.
- No missing static scene/resource references.
- Exported resource pack launches successfully.
- All five legacy levels and the section example rendered successfully.
- Section example control layout passes at 1280x720, 1920x864, 960x720 and 800x360.

Reward tests deliberately log two corrupted-profile parse diagnostics and one
write-failure warning while checking recovery. Those expected negative tests are
not normal-play script errors. Rendered checks use software OpenGL, not an Android
GPU. Native performance and touch comfort still need your device checks.

## Exact manual tests

1. Apply the patch over Phase 4, reopen Godot and wait for import. Confirm there
   are no red parser errors. Press F5: the same five levels should be listed, with
   your previous unlocks, scores, stars, wallet and selected courier retained.
2. Play Greenway: check original scenery, all four traffic directions, one hop per
   swipe/tap, intentional hold-repeat, collision/lives, destinations and timer.
   Try WASD and arrows. Pause with P/Esc, then resume; try Retry and Level Select.
3. Load every currently unlocked campaign level. Verify Highway/Village layouts
   and the already-existing railway prototype still behave as before. Complete a
   route and check Next Level; reopen the app to verify progress persists.
4. In Godot's FileSystem dock, open tools/section_preview.tscn, then press F6.
   It should start Section Example: two road lanes, a safe strip, two more lanes,
   and the existing destination bays. This scene uses a separate test profile.
5. In that example, collect a coin/power-up, reach all destinations, retry, and
   check results/stars. Ensure it did not add a sixth level to the real campaign:
   stop F6 and press F5 to return to the normal game/profile.
6. Optional architecture check: duplicate road_sections_demo.tres and its section
   resources. Assign your copy to the preview scene's Example property. Increase
   SAFE to two rows and reduce the later ROAD to one lane, keeping seven total
   rows. F6 should show the changed arrangement without editing game scripts.
7. Optional configuration-only check: assign mixed_layout_data_only.tres to the
   preview's Example property. F6 should show it disabled as LAYOUT ONLY and should
   not start fake rail/water gameplay. Restore road_sections_demo.tres afterward.
8. Export a fresh APK with the same package ID/key and update-install. Check both
   thumbs, four swipe directions, small-screen margins, pause/app switching,
   coins/skins and save persistence. Play several full runs to assess smoothness.

## File list

SECTION_FILES.txt lists every created and modified package file, including scripts,
resources, documentation, tests, screenshots and generated Godot UID companions.

```text
CREATED FILES
docs/SECTION_ARCHITECTURE.md
docs/SECTION_CAMPAIGN_RESULTS.txt
docs/SECTION_FILES.txt
docs/SECTION_IMPORT_RESULTS.txt
docs/SECTION_PACK_RESULTS.txt
docs/SECTION_REGRESSION_RESULTS.txt
docs/SECTION_RENDER_RESULTS.txt
docs/SECTION_REWARD_RESULTS.txt
docs/SECTION_TEST_RESULTS.txt
docs/screenshots/sections_configuration_only.png
docs/screenshots/sections_example.png
docs/screenshots/sections_layout_1280x720.png
docs/screenshots/sections_layout_1920x864.png
docs/screenshots/sections_layout_800x360.png
docs/screenshots/sections_layout_960x720.png
docs/screenshots/sections_legacy_01.png
docs/screenshots/sections_legacy_02.png
docs/screenshots/sections_legacy_03.png
docs/screenshots/sections_legacy_04.png
docs/screenshots/sections_legacy_05.png
resources/examples/mixed_layout_data_only.tres
resources/examples/road_sections_demo.tres
resources/sections/destination.tres
resources/sections/railway_pair.tres
resources/sections/road_pair.tres
resources/sections/safe.tres
resources/sections/start.tres
resources/sections/water_pair.tres
resources/themes/day.tres
scripts/data/compiled_level_layout.gd
scripts/data/compiled_level_layout.gd.uid
scripts/data/level_section_config.gd
scripts/data/level_section_config.gd.uid
scripts/data/level_theme_config.gd
scripts/data/level_theme_config.gd.uid
scripts/data/railway_track_config.gd
scripts/data/railway_track_config.gd.uid
scripts/data/section_layout_compiler.gd
scripts/data/section_layout_compiler.gd.uid
scripts/data/water_lane_config.gd
scripts/data/water_lane_config.gd.uid
tests/section_tests.gd
tests/section_tests.gd.uid
tests/section_tests.tscn
tools/capture_sections.gd
tools/capture_sections.gd.uid
tools/capture_sections.tscn
tools/section_preview.gd
tools/section_preview.gd.uid
tools/section_preview.tscn

MODIFIED FILES
README.md
docs/ARCHITECTURE.md
resources/levels/level_01.tres
scripts/core/game.gd
scripts/data/lane_config.gd
scripts/data/level_config.gd
scripts/ui/game_hud.gd
scripts/world/board_art.gd
scripts/world/road_level.gd

No files removed. Cache/import metadata, user saves and native builds excluded.
```
