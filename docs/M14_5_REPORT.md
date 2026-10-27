# Pocket Crossing — M14.5 map campaign

## Status and continuity

M14.5 implementation is complete, with automated and rendered Linux validation. Physical Windows/Android acceptance remains required. M15 was not started.

The interrupted implementation had already designed the four-map campaign, local profile store, map HUD/controller, destination occupancy and tests. The resumed workspace contained only the preserved post-M14 checkpoint, so the recorded M14.5 work was restored onto that checkpoint, then revalidated. No road, railway, water, camera, weather or character system was rebuilt. The source baseline retains the post-M14 boat-edge correction, original CNG/rickshaw art, destination facades and rocket celebration.

This delivery finishes scene integration, correct boat/train references, transaction and migration checks, real five-crossing route tests, visual verification, documentation and a cumulative update ZIP. It also includes the discovered nested character-button tap fix, properly sized map thumbnails, and a progress counter placed clear of the right touch controls.

## Install and normal flow

Follow `M14_5_INSTALL.txt`. Copy the update's `PocketCrossing` contents over the existing project containing `project.godot`, replacing matching files. Keep your game user data. Use **Run Project**, not an old developer preview.

Normal flow: Choose/Create Player → Map Select → five sequential crossings → total-time result → Play Again or Map Select. There is no sequential Next Level action and no stars in this campaign's UI.

The old 15-level Resources remain unchanged for compatibility and regression coverage. `scenes/legacy_main.tscn` preserves their original entry point. Existing test and capture scene references were redirected there; the normal `scenes/main.tscn` now uses `MapGame` and `MapHUD`. Tests still check that the production entry point is `main.tscn`.

## Files and architecture

The complete created/modified lists are in `M14_5_FILES.txt`, including a cumulative list against the supplied M14 ZIP. No deletions are required.

Principal additions:

| File/group | Purpose |
| --- | --- |
| `scripts/data/map_config.gd` | Extends LevelConfig with map economy, preview and destination presentation |
| `scripts/core/local_profiles.gd` | Versioned, validated local multi-profile database and transactions |
| `scripts/core/map_game.gd` | Five crossings, elapsed timer, best-time results; inherits shared gameplay |
| `scripts/ui/map_hud.gd` | Profile chooser, four cards, progress and results |
| `resources/maps/catalog.tres` and four map Resources | Normal campaign data |
| `assets/maps/*.svg` | Four original location preview illustrations |
| `scenes/legacy_main.tscn` | Retained legacy campaign entry point |
| `tests/map_campaign_tests.*`, `tests/map_route_tests.*` | New progression and real-route coverage |
| `tools/capture_maps.*` | Isolated rendered QA workflow |

Principal shared changes: `save_data.gd` adds an optional profile save callback; `destination.gd` draws an arrived character and configurable occupied colors; `road_level.gd` applies those colors; `environment_layer.gd` accepts optional per-slot destination art/tint; `level_list_scroll.gd` detects nested character buttons; `project.godot` registers Profiles; `scenes/main.tscn` selects the new controller/HUD. Existing controls and hazard scripts are preserved.

## Profiles and migration

Usernames are trimmed and must contain 3–16 ASCII letters, digits or underscores. Lowercase keys enforce case-insensitive uniqueness; original capitalization is retained for display. These are **offline, device-local profiles**, not internet accounts.

`user://map_profiles.cfg` stores schema version 1, the last active key and a Dictionary of profiles. Each profile contains username, coins, map unlocks, owned/selected characters, best map times, sound/vibration settings and a legacy archive. Profiles share no progression. Startup still offers a player chooser, with the last selected player highlighted.

On the first successful named-profile creation only, the old SaveData values migrate: coins, owned characters, selected character, sound and vibration. Old per-level scores, stars, completions and overall best score are retained in that profile's `legacy` dictionary; they do not unlock the new maps or become map times. The original `profile.cfg` is never overwritten by the new campaign, including before profile creation. Existing backup-based legacy reading remains in use.

Writes validate schema, typed fields, known map/skin IDs, nonnegative bounded coins and positive finite times. They write a temporary file, reopen and validate it, preserve the previous valid file as `.bak`, then replace the primary. Purchase and completion failures roll back their in-memory transaction. A corrupt/empty primary falls back to a valid backup. If both files are unusable, the chooser reports the problem, retains evidence (`.unreadable` when writing a replacement) and does not grant legacy migration again. This is local recovery, not cloud backup.

## Four distinct maps

All columns below are zero-based (0–17). Every map has Start and Destination rows and three lives. Short routes still use the existing M9 camera/activation system.

| Map | Theme/environment | Ordered hazard layout between Start and Destination | Goal columns | Price / completion reward |
| --- | --- | --- | --- | --- |
| Village Crossing | Day; rural homes, vegetation and courtyard facades | Road ×2 → Safe → Road ×3 → Safe | 1, 5, 8, 12, 16 | Free / 20 coins |
| City Rush | Evening; urban buildings and plaza facades | Road ×3 → Safe → Road ×3 → Safe | 2, 6, 9, 13, 17 | 65 / 25 coins |
| River Delta | Rain; river/ghat scenery and landing facades | Road ×1 → Safe → Water ×2 → Safe → Water ×2 → Safe | 0, 4, 7, 11, 15 | 100 / 30 coins |
| Night Express | Night; highway, railway and station facades | Road ×2 → Safe → Railway ×2 → Safe → Road ×2 → Safe | 1, 4, 8, 11, 16 | 155 / 35 coins |

Village has five traffic lanes emphasizing rickshaws/CNGs, local buses, pickups and small cars. Road config speeds are 145–190, with longer spawn gaps and modest speed variation. City has six lanes, 175–240 config speeds, more variation and alternating traffic waves; CNGs, rickshaws, buses, microbuses, vans and pickups share the route. Vehicle-specific speed differences remain active.

River has only one road lane and four opposing water lanes: speeds 58/75/65/85, platform lengths 192/224/160/256 and 38-pixel minimum spacing. The four boat visual Resources are reused. Weather does not alter physics.

Night combines faster highway traffic with two independent tracks (390/460 speed, 3-second warnings, 3/7-second initial delays, 10–14/12–16-second clear intervals and 4-second safe delay). Existing railway fairness coordination remains authoritative. Safe rows flank the railway. Night is intended as the hardest human route; predictive test-bot time is not a human difficulty measurement.

## Five-character objective and destinations

Each MapConfig validates exactly five distinct destination choices. The compiler retains the existing Destination Section columns. Any character may enter any free goal, in any order. Occupied goals reject movement and cannot increment progress again. A selected-skin marker remains in the occupied slot; occupied colors and border are configurable.

Success increments progress once, hides the current actor and starts a 0.55-second respawn delay. The next actor appears at Start using the same selected skin. Camera reset is handled through the existing spawn signal. Traffic/platforms/train cycles and elapsed time continue; hazards and pickups are not rebuilt. Death uses the existing collision/shield/life-loss path and preserves prior successful goals. Losing all lives ends the attempt. The fifth distinct arrival performs one terminal transition and one completion award.

Full Retry/Play Again resets occupied slots, timer, run coins, lives, hazards and pickup availability. It does not pay the previous attempt again. Coins already saved from a failed/abandoned run remain owned.

Destination facades come from the independent Environment Resource. MapConfig additionally exposes optional `destination_art_overrides`, per-slot tints, occupied colors/border and `show_arrived_character`. These use slot order, not map-number conditionals.

## Timer, coins, unlocks and results

Elapsed time starts at run start and stops at completion/failure. It includes success/death respawn delays. Pause, background pause and menus freeze it. There is no countdown failure in the new campaign. The inherited time-limit field remains available to legacy gameplay but does not cap map attempts. The UI displays minutes, seconds and centiseconds; best-time comparisons use the stored elapsed seconds.

Only a lower valid completion time replaces the personal best. First completion establishes a best. Equal/slower times and failure do not trigger rockets. Successful new records reuse the bounded rocket celebration until the result screen closes; Retry, Map Select, scene exit and hiding the result stop it. Results show total time, best time, coins and two actions: Play Again and Map Select.

Pickups save through the existing coin system into the active profile. Each authored pickup can be taken once per attempt; success/death respawns do not restore it. Full retry makes pickups available again but awards nothing until collected. The double-reward power-up affects pickups; the configured completion bonus is a fixed once-per-completion reward. Shield and Slow Traffic retain existing behavior.

Village and City have eight authored coins; River and Night have twelve. Coins sit on safe side detours instead of all following the fastest middle path, creating a time-versus-wallet choice. Prices were chosen against those pickups, fixed completion awards and existing 20/40-coin cosmetic prices. Automated representative runs earned 26–27 / 30–31 / 33 / 39 coins respectively. From Village earnings, City takes roughly three successful runs, River four and Night six (more if collecting fewer coins). These are initial economy targets, not a claim of human playtest balancing.

Village is free. Other maps may be bought in any order. A purchase checks funds, debits once, marks ownership and saves immediately. Repeated requests on an owned map do not charge again. Failed writes return coins and restore the lock. Characters remain cosmetic and independently owned per profile.

## Map Select and Inspector editing

Map Select is a fixed 2×2 layout without a map scrollbar. Each card contains original preview art, location name, theme description, lock/price or best time, and a large Play/Unlock button. Profile and character lists can scroll; their tap/drag handling supports nested character buttons. Windows keyboard, Android split touch and swipe controls use the existing input system.

In Godot, open `resources/maps/<map>.tres` in the Inspector. Edit Unlock Cost, Completion Coins, Preview Art and Atmosphere Label directly. Expand Sections to edit road/rail/water Resources or destination columns. Keep exactly five unique columns. Change Presentation to another `resources/themes/*.tres`, and Environment to a compatible environment Resource; layouts need not be copied. Destination Presentation exposes optional overrides/tints and occupied appearance. Keep the four stable IDs unchanged to preserve saves.

## Validation and evidence

Godot 4.5.2 Compatibility renderer was used. Current-run results are in `m14_5_validation/` and the screenshots in `screenshots/map_*.png`.

- 24 automated suites: all passed, no failed suite. Their printed RESULT summaries total 4,299 passing assertions/route checks and zero failures (performance/repro logs without assertion counts are separate).
- 110 new map/profile integration assertions passed.
- 12 real five-crossing routes passed: all four maps with seeds 42, 2026 and 1405. The controller emits ordinary hop requests and predicts nearby hazards; it does not teleport, suppress collisions or grant extra lives during these routes.
- The 22 retained suites cover core controls/gameplay, M3–M14 progression, sections, railway, water, long levels/camera, themes, campaign layouts, identities, balancing, contacts and stress.
- New checks cover migration, invalid/duplicate names, save/reload, profile independence, purchased skins, non-sequential unlocks, insufficient funds, purchase/completion rollback, malformed and corrupt files, safe goals, duplicate arrivals, continuous timer, pause, death, shield, retained pickups, full retry, result cleanup and best-time rules.
- A 120-second **simulated-time** rocket soak verifies bounded records and one audio node; this is not a physical-phone performance result.
- Rendered inspection covers profile entry, locked/unlocked cards, characters, start/destination views for all four environments, occupied markers, pause, failure and new-best rockets.
- Applying the cumulative ZIP over the original M14 files reproduced the tested working source. Fresh editor import and normal startup passed with no parser/resource failures. The clean overlay also passed all 110 map/profile checks. Both Windows and Android resource-pack exports succeeded and started under the Linux runtime; this checks packaged resource/script loading, not native device execution.

Some preserved legacy negative tests intentionally emit corrupt-file parse diagnostics; a few legacy harnesses report resource-in-use warnings at shutdown. Their assertions pass. New campaign tests and the rendered campaign have no script/parser failures. These old diagnostics are distinguished from production errors in the evidence.

To run the new checks in Godot: open `tests/map_campaign_tests.tscn` or `tests/map_route_tests.tscn`, then use the Run Current Scene toolbar button. They use isolated save paths and exit with a printed result. `tools/capture_maps.tscn` writes rendered QA screenshots and exits; it is not a playable campaign entry point.

### Suite results (passed / failed)

| Suite | Result |
| --- | --- |
| test_runner | 135/0 |
| phase3_tests | 103/0 |
| phase4_tests | 62/0 |
| section_tests | 68/0 |
| railway_tests | 88/0 |
| water_tests | 73/0 |
| water_route_tests | 3/0 |
| long_level_tests | 142/0 |
| long_route_tests | 2/0 |
| theme_tests | 109/0 |
| theme_route_tests | 6/0 |
| campaign_route_tests | 75/0 |
| campaign_tests | 372/0 |
| identity_tests | 987/0 |
| balance_tests | 516/0 |
| balance_water_routes | Exit 0; see log |
| qa_validation | 359/0 |
| qa_contacts | 90/0 |
| qa_stress | 539/0 |
| qa_repro | Exit 0; see log |
| qa_perf | Exit 0; see log |
| post_m14_tests | 448/0 |
| map_campaign_tests | 110/0 |
| map_route_tests | 12/0 |

## Exact Windows manual checklist

No native Windows session was available here. The rendered checks were on Linux, not Windows.

1. Back up and overlay the update. Run Project. Create `Nayemur`; verify the first player's previous wallet, skins and settings.
2. Return to Players. Try `nayemur`, blanks, two letters and punctuation; verify useful validation. Create `Test_2`; verify a separate fresh wallet and only Village unlocked. Switch back.
3. Check all four cards, locked prices, Characters and Players with mouse; test keyboard focus/Enter where applicable.
4. Play Village using WASD and arrow keys. Reach any goal, not necessarily slot 1. Verify 1/5, a character marker and the next actor at Start; time continues.
5. Try the occupied goal. It must block without awarding another success. Fill the other slots in a different order.
6. After two successes, deliberately hit traffic. Verify a life is lost, 2/5 remains and elapsed time continues. Repeat with shield and verify one hit is absorbed.
7. Collect a coin; traverse its cell again after success/death. Verify no repeat reward in that attempt. Full Retry restores the pickup, not an automatic payout.
8. Pause for ten seconds, then resume. Verify timer, trains, platforms and weather pause correctly. Retry must reset to 0/5 and zero elapsed time.
9. Complete five. Verify one completion reward and time result. Leave/reopen result through Play Again/Map Select and verify no duplicate reward.
10. Complete a slower run: no rockets and unchanged best. Beat the best: rockets. Leave the new-best panel open for two minutes, then leave it; verify effects/audio stop.
11. Save enough for River or Night and buy it before City. Restart the app: ownership and wallet must persist. Test insufficient-funds feedback and repeated clicks without double charge.
12. Play City traffic waves, River boat transfers/edge exits, and Night warnings in both directions. Verify darkness/rain do not hide hazards; test water/train deaths with prior goals occupied.
13. Check both skins and mute settings remain correct after profile switching and app restart. Alt-tab during gameplay must pause safely.

## Exact physical Android checklist

No Android device, touchscreen keyboard or native APK execution was available here. Resource-pack validation is not an Android playtest.

1. Install your normal test export without clearing app data; verify first-player migration. Back up before uninstalling (uninstall may erase Android user data).
2. Create a name with the touchscreen keyboard; verify keyboard dismissal, invalid/duplicate feedback, profile scrolling and switching.
3. In landscape, verify all four cards and purchase buttons fit, are readable and respond once. Buy an affordable map; close/reopen the app and verify persistence and the other profile's independence.
4. Use both split-touch controls and swipe in Village and City. Test held buttons, alternating thumbs and rapid direction changes; no stuck movement or UI-triggered hop.
5. Ride and transfer between all four River lanes. Test leaving a boat at both screen edges and water death after two successful goals.
6. In Night Express, observe both warning cycles before crossing. Test warnings muted and unmuted; verify trains, player and safe bays remain readable on your screen brightness.
7. Fill five different goals. Verify persistent occupied markers, blocked occupied cells, success respawns, lives and timer. Repeat with a purchased skin.
8. Collect coins/power-ups; test Shield against traffic/train/water and verify existing fair behavior. Verify coins do not respawn between the five crossings.
9. Pause/resume, switch apps, return, press Android Back, and retry during rain/train warning/boat riding. Verify no duplicate effects, timer advance while paused or carried input.
10. Establish and beat a best time. Watch new-best rockets for two real minutes. Watch FPS, temperature, responsiveness, audio and memory stability; leave and verify cleanup. A slower run must not celebrate.
11. Repeat profile/map/result navigation and all four maps at your phone's actual aspect ratio. Check the bottom 5/5 counter does not overlap the touch controls or system inset.

## Performance, limitations and next milestone

The existing pooled platforms/train reuse, bounded weather, camera-window activation and lightweight drawn lights remain in place. New occupied markers add only five texture draws. Map cards use four small SVG textures. A single celebration owns at most four rocket records and one audio voice; no per-goal celebration systems were added. Save operations occur on progression/settings changes, not every timer frame.

These finite maps intentionally use the existing 18-column, 64-pixel landscape grid. Long vertical levels remain supported, but this campaign favors compact 9–11-row layouts. No endless/procedural mode, new hazards, online accounts, leaderboard, ads, IAP or release-store configuration was added. Profiles are local; best times are not tamper-proof online records. The save database stores progression, not an in-progress attempt. Human difficulty/economy and physical-phone performance need your acceptance tests.

The architecture is ready for the separate M15 planning step after the Windows/Android checklist passes. This is not a release-readiness certification, and M15 has not begun.
