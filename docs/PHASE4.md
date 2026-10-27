# Phase 4 — interrupted-work audit and completion

## Installation

Close Godot and back up your project. Extract the CONTENTS of
PocketCrossing_Phase4_Update.zip into the folder containing project.godot,
replacing matching files. This patch applies to either the working Phase 3 project
or the interrupted Phase 4 source. Reopen Godot 4.5.2, wait for import, then export
a new APK. Existing project/input/export/signing settings are not replaced.
Keep the same Android package ID and signing key; install over the existing app
instead of uninstalling if you want to retain local progress.

The full project ZIP is also provided. Its original generic export settings are
not a replacement for the Android settings already configured on your own PC.

## What existed before this resumed run

The interrupted source folder contained 17 additions/edits relative to Phase 3.
It had not reached a working, verified Phase 4 build. A preserved pre-fix import
log is included as PHASE4_BEFORE_IMPORT.txt.

| Feature | Exact state at audit |
| --- | --- |
| Coins | RewardField and RewardPickup existed, with drawn icons/ring effects, coin banking callbacks and once-per-run removal. Placement still depended on fixed screen coordinates; HUD integration was missing. Partial and unverified. |
| Stars | LevelConfig already contained configurable time/life thresholds and a 1–3-star formula. Game/SaveData code attempted to record best stars; the result UI fields did not exist. Partial. |
| High scores | Working per-level records originated in Phase 3. Phase 4 added typed score records and result integration, but the broken save autoload prevented operation. |
| Characters | Four catalog entries and three original SVG palette variants existed. Purchase/selection methods and player texture loading existed. No character screen or its HUD signals existed. Partial. |
| Power-ups | PowerUpConfig, three resources (shield, slow, double), PowerUpController, collision absorption, shared traffic scaling and reward multiplication existed. No HUD countdown integration or verification existed. Partial. |
| Save system | Versioned profile fields, migration/default logic, temporary file, previous backup and purchase rollback code existed. Mixed tabs/spaces caused a parse error, which also broke dependent scripts and the autoload. Broken. |
| Progression UI | Entirely missing: game code referenced characters_pressed, character_selected, show_characters, update_progression, result_stars and result_coins, but GameHUD had none of them. |
| Validation/delivery | No Phase 4 tests, captures, audit guide, or finished update package existed. |

Existing pre-interruption files were reused. No Phase 1–3 gameplay was rebuilt,
no new levels were created, and the existing five level resources remain unchanged.

## What this run completed or fixed

- Fixed SaveData indentation and dependent compilation. Reset save-error state
  when loading a profile. Verified typed defaults, numeric bounds, old-profile
  migration, backup fallback, and purchase rollback on write failure.
- Added the missing character selection screen, signals, wallet display, unlock
  prices, selected-skin feedback and return button. Purchases require earned coins.
- Added best stars/scores to level selection and results. Results show this run's
  stars/coins and the wallet, plus the configurable star criteria.
- Added the compact gameplay coin/effect footer and shield ring. Existing thumb
  controls and keyboard/swipe input are unchanged.
- Fixed deferred focus calls that targeted a modal removed during a rapid screen
  change; focus now checks that the control is still valid and inside the tree.
- Removed layout knowledge from RewardField. RoadLevel is now the sole adapter
  selecting safe sites for the existing static board. RewardField accepts arbitrary
  pickup keys and positions, and saves accept arbitrary stable level IDs.
- Removed a redundant result save; improved per-level score retention when leaving
  a run/keyboard restarting, save-failure result messaging and multiplied-point tips.
- Added real-scene reward/save integration tests, rendered menu checks, a resource
  reference scan, and a packed-resource startup check.
- Updated the main README/architecture to remove obsolete advice to duplicate
  scenes per level and describe the actual shared systems and extension boundaries.

## Current reward rules

### Coins

Up to six coins per run, subject to available safe positions. The current board
adapter places them only on safe rows, not in traffic, obstacles, destinations or
the player's initial cell, and keeps them clear of the HUD/thumb controls. Coins
bank immediately, including on failed runs. A pickup can be collected once per run;
respawn does not recreate it. Retry starts a new run with fresh pickups. Replays
can earn more coins. These are cosmetic earnings, not real-money purchases.

### Stars and scores

Successful completion grants one star. At least 35% of the configured time limit
remaining grants one more; at least two lives grants one more. Thresholds are
editable in LevelConfig. A failed run grants no stars. Best stars and best score
are stored independently, so replaying badly never lowers either. Completed and
failed runs can improve the per-level high score. Existing Phase 3 completion and
scores migrate; stars cannot be inferred from old scores, so replay earns them.

### Characters

| Skin | Price | Gameplay |
| --- | --- | --- |
| Pip / Amber | Free | Original courier |
| Mika / Mint | Free | Cosmetic recolor |
| Rio / Coral | 20 coins | Cosmetic recolor |
| Nova / Violet | 40 coins | Cosmetic recolor |

All share the existing hop timing, hitbox, lives and collision rules. An owned
skin can be selected again for free. Selected character and ownership persist.
No ads, purchases with money, premium power-ups or pay-to-win stats were added.

### Temporary power-ups

| Icon | Effect | Default duration |
| --- | --- | --- |
| S | Shield absorbs one hit, with 1.2 seconds of hit grace after absorption | 12 active seconds, or until used |
| T | All vehicles move at 65% of their current lane speed; original spacing remains | 6 active seconds |
| 2 | Double collected coins and forward/destination points | 8 active seconds |

Completion/time/life/target bonuses are not multiplied. A repeated effect refreshes
its duration instead of stacking strength. Timers run during play and short
respawn delays, pause during pause/focus loss, and clear on retry/selection/results.
Power-up definitions are editable resources. No extra gameplay buttons are needed:
hopping onto the icon activates it. Power-ups cannot be purchased.

## Save recovery and modularity

The existing user://profile.cfg retains its identity. Version 2 adds coins,
characters/selection, stars and typed score/completion dictionaries. Saves write
.tmp, keep the previous parseable profile as .bak, and replace the main file.
Missing or syntactically broken main files load the backup if possible; otherwise
defaults are safe. Wrong individual types and out-of-range values are sanitized.
Backup recovery may lose the latest transaction. No recovery can reconstruct data
when both copies are unusable. A purchase whose save fails is rolled back.

Completion, scores and stars are keyed by stable IDs, with no list of five IDs in
SaveData. The test suite saves an arbitrary future route ID. RewardField also
accepts opaque string keys and off-screen world positions. A future world only
needs to supply safe sites and pickup/completion events. Current layout bounds
remain in RoadLevel.reward_sites, not the wallet, stars, character or power timer
systems. See ARCHITECTURE.md for the interfaces.

No new railways, water, platforms, scrolling/chunks, weather, Bangladesh content or
release work was started. Existing Phase 3 railway behavior remains in place.

## Verification

Godot 4.5.2 on Linux:

- 135 existing gameplay/control checks: passed.
- 103 campaign/transition/traffic checks: passed.
- 62 new reward, cosmetic, save and integration checks: passed.
- Total: 300 automated checks, zero failures.
- Final editor import: no GDScript errors.
- Static resource reference scan: no missing references.
- Exported resource pack: starts successfully without missing-resource/script errors.
- Level select, character selection, gameplay/effect and result captures reviewed.
- Four landscape sizes: 1280x720, 1920x864, 960x720 and 800x360 passed layout checks.

PHASE4_REWARD_RESULTS.txt intentionally contains two ConfigFile parse diagnostics
from truncated-save fixtures and one write-failure warning. Each is followed by a
passing recovery/rollback assertion. They are expected negative tests, not script
errors in normal play. Rendering uses software OpenGL here; phone performance and
native Windows/Android execution still require physical device checks.

## Manual tests on your Android phone / Windows PC

1. Update over the existing app/project; confirm previous unlocked routes, scores,
   sound and vibration preferences remain. Older profiles begin with zero coins
   and no invented stars, with Pip/Mika available for free.
2. Collect a coin, revisit that spot and confirm it cannot pay twice. Lose a life,
   then lose/retry the run; banked coins should remain. Close/reopen the app and
   check the wallet again.
3. Finish with different time/life results. Check 1–3 stars, per-level best score,
   Next Level, Retry and Return to Level Select. A worse replay must not erase a best.
4. Select the free Mint skin, reopen the app, and confirm it is equipped. Earn
   20 coins, unlock Coral and check the exact deduction. Re-selecting it is free.
5. Collect S: check the visible ring and one protected collision. A later hit after
   the grace period should cost a life. Let an unused shield expire once.
6. Collect T and 2: check traffic slows/restores, coins/points double only temporarily,
   and timers freeze during pause/app switching. Retry must clear all effects.
7. Check both thumbs, swipes, WASD/arrows, no accidental menu-to-game movement,
   small-screen text, notch margins and menu scrolling. Play several full runs to
   assess frame rate and the balance of the new optional pickups.
8. Keep using the same package ID/signing key and update-install if preserving app
   data. Do not deliberately corrupt your real save; recovery was tested using
   isolated fixture files.

## Every file changed

The exact manifest below distinguishes this resumed run from the complete Phase 4
patch relative to Phase 3. The patch also includes the already-existing interrupted
work so it installs cleanly onto a working Phase 3 copy. Generated .uid files are
listed; .godot cache, .import metadata, personal saves and native builds are excluded.

```text
PHASE 4 FILE MANIFEST

Runtime/source files edited in this resumed run (relative to the audited interrupted source):
README.md
docs/ARCHITECTURE.md
scripts/actors/player.gd
scripts/core/game.gd
scripts/core/save_data.gd
scripts/ui/game_hud.gd
scripts/world/reward_field.gd
scripts/world/road_level.gd

New verification/documentation/capture files from this run:
docs/PHASE4.md
docs/PHASE4_BEFORE_IMPORT.txt
docs/PHASE4_CAMPAIGN_RESULTS.txt
docs/PHASE4_FILES.txt
docs/PHASE4_IMPORT_RESULTS.txt
docs/PHASE4_PACK_RESULTS.txt
docs/PHASE4_REGRESSION_RESULTS.txt
docs/PHASE4_RENDER_RESULTS.txt
docs/PHASE4_REWARD_RESULTS.txt
docs/screenshots/phase4_characters.png
docs/screenshots/phase4_characters_1280x720.png
docs/screenshots/phase4_characters_1920x864.png
docs/screenshots/phase4_characters_800x360.png
docs/screenshots/phase4_characters_960x720.png
docs/screenshots/phase4_effects.png
docs/screenshots/phase4_gameplay.png
docs/screenshots/phase4_results.png
docs/screenshots/phase4_select.png
docs/screenshots/phase4_select_1280x720.png
docs/screenshots/phase4_select_1920x864.png
docs/screenshots/phase4_select_800x360.png
docs/screenshots/phase4_select_960x720.png
tests/phase4_tests.gd
tests/phase4_tests.gd.uid
tests/phase4_tests.tscn
tools/capture_phase4.gd
tools/capture_phase4.gd.uid
tools/capture_phase4.tscn

Complete Phase 4 patch relative to Phase 3 (includes reused interrupted work):
README.md
assets/art/courier_coral.svg
assets/art/courier_mint.svg
assets/art/courier_violet.svg
docs/ARCHITECTURE.md
docs/PHASE4.md
docs/PHASE4_BEFORE_IMPORT.txt
docs/PHASE4_CAMPAIGN_RESULTS.txt
docs/PHASE4_FILES.txt
docs/PHASE4_IMPORT_RESULTS.txt
docs/PHASE4_PACK_RESULTS.txt
docs/PHASE4_REGRESSION_RESULTS.txt
docs/PHASE4_RENDER_RESULTS.txt
docs/PHASE4_REWARD_RESULTS.txt
docs/screenshots/phase4_characters.png
docs/screenshots/phase4_characters_1280x720.png
docs/screenshots/phase4_characters_1920x864.png
docs/screenshots/phase4_characters_800x360.png
docs/screenshots/phase4_characters_960x720.png
docs/screenshots/phase4_effects.png
docs/screenshots/phase4_gameplay.png
docs/screenshots/phase4_results.png
docs/screenshots/phase4_select.png
docs/screenshots/phase4_select_1280x720.png
docs/screenshots/phase4_select_1920x864.png
docs/screenshots/phase4_select_800x360.png
docs/screenshots/phase4_select_960x720.png
resources/powerups/double.tres
resources/powerups/shield.tres
resources/powerups/slow.tres
scripts/actors/player.gd
scripts/core/game.gd
scripts/core/power_up_controller.gd
scripts/core/power_up_controller.gd.uid
scripts/core/save_data.gd
scripts/data/character_catalog.gd
scripts/data/character_catalog.gd.uid
scripts/data/level_config.gd
scripts/data/power_up_config.gd
scripts/data/power_up_config.gd.uid
scripts/ui/game_hud.gd
scripts/world/reward_field.gd
scripts/world/reward_field.gd.uid
scripts/world/reward_pickup.gd
scripts/world/reward_pickup.gd.uid
scripts/world/road_level.gd
scripts/world/traffic_lane.gd
tests/phase4_tests.gd
tests/phase4_tests.gd.uid
tests/phase4_tests.tscn
tools/capture_phase4.gd
tools/capture_phase4.gd.uid
tools/capture_phase4.tscn
```
