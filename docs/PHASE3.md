# Phase 3 — resource-driven campaign

## Install the update
Close Godot and back up your working Phase 2 project. Extract the CONTENTS of
PocketCrossing_Phase3_Update.zip directly into the folder containing project.godot,
replacing matching files. Reopen Godot 4.5.2 and let it import. Export a new APK.
The patch does not replace project.godot, export_presets.cfg, input actions, art,
audio, signing settings, or Android texture settings. Existing best score, sound,
and vibration preferences are preserved. Older profiles begin with Level 1 unlocked.

## Campaign
1. Greenway: four lanes, original board and beginner speed curve.
2. City Rush: four faster lanes, generous time allowance.
3. Highway: five lanes and longer bus placeholders.
4. Village Road: waves of traffic, a safe median with two visible planters.
5. Railway Crossing: four road lanes and one periodically active railway lane.

Each level starts gently and ramps up. One speed per lane prevents overtaking.
Spawner spacing accounts for the longest configured vehicle and peak speed;
its clear gap is at least the configured minimum seconds of travel. Static
obstacles cannot block live traffic escape cells and all destinations are checked
for geometric reachability. This is not a formal proof of every time-dependent
route: player timing and device playtesting still matter.

Railway: 10 seconds of open track, then a 3-second warning, then one train per
24-second cycle. Amber stays on while a train exists; green marks an empty open
interval. Stay OFF the rails during warnings. Trains and buses deliberately reuse
the original truck artwork at larger sizes, with matching inset collision shapes.

## Architecture / adding level 6 and beyond
There is ONE game controller and ONE world scene. No per-level scripts/scenes.
Create a LevelConfig resource under resources/levels; add LaneConfig subresources,
then append it to resources/levels/campaign.tres. Keep level_id unique and stable:
profile completion and best scores use it. Do not rename IDs after release.
Campaign order controls the predecessor required to unlock a level. New resources
are automatically listed by the scrolling level-select screen.

LevelConfig exposes name, number, stable ID, theme, difficulty label, lanes,
columns, goal row/columns, start cell, cell spacing, time/lives, obstacle cells,
movement parameters, difficulty speed curve, forward/destination/bonus scoring,
score target and target reward. Lane count is lanes.size(), never a duplicated
integer. Missing traffic rows are safe grass. Initial layouts use the established
18-column, six-step board (up to five traffic rows), preserving readable art sizes.
Different geometry must fit the 1280x720 logical canvas and existing gameplay area.
A taller world/camera is outside this phase.

LaneConfig exposes row, direction, speed, spawn interval range, palette, clear-gap
rules, variation, vehicle_types and pattern. Repeated vehicle type entries are
weights. Supported types: car, truck, bus, train. Patterns: steady, waves, railway.
Waves/railway use cycle_seconds, open_seconds and warning_seconds. Railway emits
one train per cycle after the warning, even if a frame misses the exact boundary.

Score targets are OPTIONAL completion bonuses, not extra unlock requirements.
Normal score/time/life bonuses remain. If the total meets score_target, add
 target_reward once. Any successful completion unlocks the next route.

SaveData extends the existing user://profile.cfg with progress.completed and
progress.scores dictionaries. A failure never unlocks a route. Replaying cannot
reduce a best score. The last level offers replay and return to selection.

## Files changed
- scripts/data/level_config.gd, lane_config.gd; new level_catalog.gd
- resources/levels/campaign.tres and level_02.tres through level_05.tres (new)
- scripts/core/game.gd and save_data.gd
- scripts/world/road_level.gd, traffic_lane.gd and board_art.gd
- scripts/actors/vehicle.gd
- scripts/ui/game_hud.gd
- tests/phase3_tests.gd/.tscn; tools/capture_campaign.gd/.tscn (new)
- README and Phase 3 documentation, verification logs and screenshots
Player movement, input router, split-touch button code, art/audio assets, existing
scenes and Level 1 resource are unchanged.

## Verification
Godot 4.5.2 headless import; existing 135 checks; new campaign suite (103 checks).
Campaign checks include real scene transitions, completion/retry/next/final replay,
locked-level denial, save/reload, old-profile migration and 90-second traffic
spacing simulations for every lane. Four rendered landscape layout sizes:
1280x720, 1920x864, 960x720 and 800x360. Resource PCK export and standalone load.
See PHASE3_*_RESULTS.txt. Linux-rendered checks are not native Android or Windows
hardware performance certification.

## Manual phone/Windows checks
- First launch: only Greenway is playable. Complete it, close the application,
  reopen it and confirm City Rush is unlocked and the best score is retained.
- Next Level, Retry and Level Select work after wins, failures and pause.
- Swipe and both thumbs still work; no carried-over held direction on transitions.
- Windows WASD/arrows, P/Esc, R and M retain their functions.
- Five-lane crossings remain comfortable; wait for larger gaps on Highway.
- Village planters block only their visible cells. All four bays remain reachable.
- Railway warning appears before trains; pause also freezes its cycle.
- Verify menu scrolling, notch margins and text on your smallest landscape screen.
- Play several runs to assess difficulty and frame rate on your Android device.

Phase 4 has not been started.
