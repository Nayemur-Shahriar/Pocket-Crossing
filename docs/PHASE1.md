# Phase 1 — Gameplay polish

## Install into your working Windows/Android project

Close Godot and back up your working project. Extract
PocketCrossing_Phase1_Update.zip directly into the project folder containing
project.godot, merging folders and replacing matching files. Reopen Godot 4.5.2,
wait for import, run F5, then export a fresh APK with your working preset.

This patch is based on the split-controls version. It includes the split-control
scripts as well, so it can also update the original Level 1 project directly.
It contains no project.godot, export_presets.cfg, keystores, or editor settings.
Your working Android setup is retained. The full project archive remains available,
but does not contain the export-setting changes you made locally on your PC.

## Gameplay improvements

The original 0.14-second grid hop is retained. Ground movement now uses a
smooth ease-in/ease-out curve; the existing airborne arc is configurable.
Landing adds a brief subtle squash and expanding ring. A single buffered
direction remains the limit while hopping. Zero, diagonal and multi-cell
commands are rejected; valid board boundaries and destination restrictions
still use the original entry rule.

Collision feedback uses a brief expanding amber marker and a softer screen
flash, with the original sound. No violent effects. The existing controller
still disables input during respawn and returns the player to the spawn cell.
All pose/animation state is reset there. Collision shapes were reviewed and
retained: player 26x28, car 92x38, van 116x38, smaller than their art.
The hop is a visual arc, not temporary immunity; collision uses the ground
footprint throughout the hop. Existing spawn protection remains.

Spawning now checks a conservative 144-pixel vehicle envelope and refuses
spawns without enough clear space. A blocked timer retries without accumulating
a burst. Initial vehicles also respect spacing. Both lane directions work.
Every vehicle in a lane shares its smoothly changing speed, preventing
overtaking and vehicle overlap. Each lane has a slow, bounded speed variation.

Level 1 begins at 72% of its nominal traffic speeds, then eases toward 100%
over 60 active seconds. Pausing freezes the ramp, traffic, timer and any
in-progress hop. Difficulty resets on replay. Traffic continues during the
existing brief respawn/destination delay, as before.

Destination arrivals add a short celebration ring. Menu, pause, game-over
and completion overlays fade in over 0.18 seconds; their input blocking is
immediate. Split buttons, swipe input, keyboard controls, score, lives,
destinations, time limit, persistence and sounds remain.

## Configurable values

Open resources/levels/level_01.tres in the Godot Inspector.

| LevelConfig property | Level 1 value |
| --- | --- |
| hop_seconds | 0.14 seconds |
| hop_height | 11 logical pixels |
| spawn_protection | 0.9 seconds |
| hit_reset_seconds | 0.9 seconds |
| destination_reset_seconds | 0.65 seconds |
| starting_speed_scale | 0.72 |
| final_speed_scale | 1.0 |
| difficulty_ramp_seconds | 60 active seconds |

Each embedded LaneConfig also exposes:

| Property | Default |
| --- | --- |
| minimum_clear_gap | 220 logical pixels |
| minimum_gap_seconds | 1.4 seconds at maximum configured lane speed |
| speed_variation | 0.06 (up to +/-6%, faded in with the ramp) |
| variation_period | 18 seconds |

The existing speed, spawn_min/spawn_max and color settings remain available.
The actual minimum gap is the larger of minimum_clear_gap and maximum possible
speed times minimum_gap_seconds. This preserves recurring openings even as
speed increases. These are lane-level spacing guarantees, not a guarantee
that every move from an unsafe player position can succeed. Waiting and using
the safe median remain part of the road-crossing concept.

## Files changed from the split-controls version

- scripts/actors/player.gd: eased hop, landing feedback, pose reset, cardinal input guard.
- scripts/world/traffic_lane.gd: spacing gate, initial placement, shared lane speed and ramp.
- scripts/world/road_level.gd: passes the existing level resource to lanes.
- scripts/world/destination.gd: arrival pulse.
- scripts/data/level_config.gd: movement/reset and difficulty settings.
- scripts/data/lane_config.gd: minimum gap and bounded speed variation settings.
- resources/levels/level_01.tres: explicit Level 1 tuning.
- scripts/core/game.gd: uses configured reset delays/protection and passes impact position.
- scripts/ui/game_hud.gd: impact marker and overlay fade.
- scripts/ui/collision_feedback.gd (new): short cosmetic impact effect.
- tests/run_tests.gd: additional movement, pause and traffic regression checks.
- tools/capture_preview.gd: hop/impact screenshots and waits for overlay fades.
- docs/PHASE1.md, docs/PHASE1_TEST_RESULTS.txt, docs/VALIDATION.md and screenshots.
- Generated .uid sidecar for the new script.

The patch also carries the unchanged split-control scripts and their sidecars
for users applying it directly to the first Level 1 download.

## Verification

Godot 4.5.2 Standard/GDScript, Linux:
- 135 assertions passed, 0 failures; no script or physics errors.
- All 80 prior gameplay, keyboard, split-button, native synthetic multitouch,
  swipe, mode and safe-area checks retained.
- Mid-hop pause freezes movement/difficulty and resumes to the exact target.
- Invalid movement vectors rejected; respawn clears animation state.
- Shape dimensions checked against artwork.
- Sixteen 90-second simulated traffic runs: four seeds x four lane configurations.
  Every run maintained conservative spacing, generated ongoing traffic, used
  common lane speed and changed speed gradually.
- Actual Godot rendering of gameplay, hop, impact and all menu/end screens.
  Software-renderer V-Sync warning only.

No updated native APK/EXE was built here. Synthetic tests and Linux rendering
do not replace physical Windows/Android acceptance testing.

## Manual Android checks

1. Tap each split arrow and swipe each direction: one tap/swipe, one hop.
2. Hold/release buttons with both thumbs; release off a button; confirm no stuck input.
3. Try movement near cars: judge whether collisions match the ground footprint.
4. Take hits until game-over; check clear impact feedback, three lives and clean respawn.
5. Pause during a hop; resume. Switch apps while holding a button; return and resume.
6. Reach all destinations; check the arrival pulse, completion transition and replay reset.
7. Play the full 90 seconds: traffic should start gently and increase gradually,
   with useful openings in both directions and no stacked vehicles.
8. Check thumb reach and safe margins, sound, haptics and frame rate on your phone.

Phase 2 has not started. No coins, shop, additional levels or power-ups were added.
