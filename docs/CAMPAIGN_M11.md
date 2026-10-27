# M11 — Fifteen-level campaign and results

## Install and start

This ZIP is an incremental update for the completed M10 project. Back up the project, close Godot, extract into the folder containing `project.godot`, and merge/replace matching files. Reopen Godot and let it import. Do not extract into a second nested project folder. No files need deleting. Normal Run Project launches the 15-level campaign.

To inspect every level without changing your normal progression, open `tools/campaign_preview.tscn` and click **Run Current Scene** (the toolbar button; no F6 key required). Its root **Starting Level** property accepts 1–15. This developer scene makes every level available in `user://campaign_preview_profile.cfg`; it never writes `user://profile.cfg`. Level Select in the preview can open any campaign level. The preview's artificial completed flags are for testing, not the real unlock flow.

## Inspection and reuse

M10 already supplied themes/weather, long-level terrain/camera/activation, road/rail/water runtimes, coins, powers, characters, stars and saving. M11 uses them. The old result card lacked a pre-save high-score comparison and a distinct structured failure card. Pickups were automatically placed; the new campaign needed explicit safe-section placement. Level Select already scrolled; it now retains readable card sizes, follows keyboard focus and returns to the played level.

No replacement damage, movement, water, railway, weather, camera, power-up or save system was created. No Bangladesh-content or release milestone was started.

## Campaign

Every route has one destination at column 8. This avoids requiring several complete repeats of a long route. Rows include Start, all hazard/safe rows and Destination. R = road lane count; T = railway track count; W = water lane count; S = one safe row. The following sequences run from Start toward Destination.

| # | Name | Theme | Rows | Time | Purpose |
| --- | --- | --- | ---: | ---: | --- |
| 1 | Easy Road | Day | 6 | 70s | Three slow car lanes and a generous central rest strip teach timing. |
| 2 | City Run | Day | 9 | 85s | Two road groups introduce mixed directions and trucks. |
| 3 | Sunset Rush | Evening | 10 | 100s | Warm evening roads add three different group sizes and wave traffic. |
| 4 | Night Ride | Night | 11 | 110s | Night roads introduce headlights with safe breaks and a shield choice. |
| 5 | Train Time | Day | 11 | 120s | One clearly warned railway track between safe areas introduces trains. |
| 6 | Double Track | Evening | 13 | 130s | Two independent, opposite-direction tracks and two road groups. |
| 7 | River Hop | Day | 13 | 140s | Two wide, slow platform lanes introduce riding and water crossings. |
| 8 | Rain Run | Rain | 15 | 145s | Rain atmosphere, one track and several road groups; movement is unchanged. |
| 9 | River Rush | Evening | 17 | 155s | Two water groups with mixed lengths, currents and speeds. |
| 10 | Snow Way | Snow | 18 | 165s | Snowy roads with a pair of tracks and a later single-track crossing. |
| 11 | Fog Track | Fog | 20 | 175s | Two separated pairs of tracks under gentle fog, with safe observation areas. |
| 12 | Wild River | Rain | 23 | 185s | Three water lanes, a railway and a second river; two optional powers. |
| 13 | Midnight Run | Night | 26 | 195s | Long night route combining road groups, two railway sections and water. |
| 14 | Danger Zone | Evening | 30 | 210s | Three-track crossing, three water lanes and another track pair in evening light. |
| 15 | Final Crossing | Night | 35 | 235s | 35-row night finale with two rivers, varied road groups and multiple railway crossings. |

### Exact section order

| Level | Ordered sections |
| --- | --- |
| 01 Easy Road | Start R2 S R1 Destination |
| 02 City Run | Start R2 S R3 S Destination |
| 03 Sunset Rush | Start R3 S R2 S R1 Destination |
| 04 Night Ride | Start R2 S R3 S R2 Destination |
| 05 Train Time | Start R2 S T1 S R3 S Destination |
| 06 Double Track | Start R3 S T2 S R3 S Destination |
| 07 River Hop | Start R3 S W2 S R3 S Destination |
| 08 Rain Run | Start R3 S T1 S R4 S R2 Destination |
| 09 River Rush | Start R3 S W3 S R3 S W2 S Destination |
| 10 Snow Way | Start R3 S T2 S R3 S T1 S R3 Destination |
| 11 Fog Track | Start R4 S T2 S R3 S T2 S R3 Destination |
| 12 Wild River | Start R3 S W3 S T1 S R4 S W2 S R3 Destination |
| 13 Midnight Run | Start R4 S T2 S R3 S W3 S R3 S T1 S R2 Destination |
| 14 Danger Zone | Start R4 S T3 S R3 S W3 S R4 S T2 S R3 Destination |
| 15 Final Crossing | Start R3 R2 S T2 S R3 S W3 S R4 T1 S R3 S W2 S R3 Destination |

### Main difficulty settings

Speeds and gaps are world pixels and pixels/second; times are seconds. These are lane-specific values, not one campaign speed multiplier. Starting/final road speed scale are both 1.0 in these levels, with small lane speed variation. Road directions alternate across configured lanes; trucks and buses supplement cars after the introduction. From Level 3, every third road lane uses the existing wave pattern (13-second cycle, 4-second no-new-spawn phase). Vehicles already on a road continue moving during that phase.

| # | Road speed | Road minimum gap | Road spawn range | Train speed | Warning | Train interval range | Water speed | Deck length | Water spacing | Coins / Powers | Score target |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 80–117 | 331–355 | 3.4–4.35 | — | — | — | — | — | — | 4 / none | 300 |
| 2 | 87–137 | 322–346 | 3.3–4.25 | — | — | — | — | — | — | 5 / none | 330 |
| 3 | 94–144 | 313–337 | 3.2–4.15 | — | — | — | — | — | — | 5 / none | 360 |
| 4 | 101–151 | 304–328 | 3.1–4.05 | — | — | — | — | — | — | 6 / shield | 390 |
| 5 | 108–158 | 295–319 | 3–3.95 | 300–300 | 4.0–4.0 | 24–28 | — | — | — | 6 / shield | 420 |
| 6 | 115–165 | 286–310 | 2.9–3.85 | 308–348 | 4.0–4.0 | 24–30 | — | — | — | 7 / shield | 450 |
| 7 | 122–172 | 277–301 | 2.8–3.75 | — | — | — | 40–48 | 320–320 | 32–32 | 7 / shield | 480 |
| 8 | 129–179 | 268–292 | 2.7–3.65 | 324–324 | 3.4–3.4 | 20–24 | — | — | — | 8 / slow | 510 |
| 9 | 136–186 | 259–283 | 2.6–3.55 | — | — | — | 46–64 | 224–288 | 40–48 | 8 / shield | 540 |
| 10 | 143–193 | 250–274 | 2.5–3.45 | 340–380 | 3.4–3.4 | 20–26 | — | — | — | 9 / slow | 570 |
| 11 | 150–200 | 241–265 | 2.4–3.35 | 348–388 | 3.4–3.4 | 20–26 | — | — | — | 9 / shield | 600 |
| 12 | 157–207 | 232–256 | 2.3–3.25 | 356–356 | 3.0–3.0 | 17–21 | 55–73 | 224–288 | 52–60 | 10 / shield, double | 630 |
| 13 | 164–214 | 223–247 | 2.2–3.15 | 364–404 | 3.0–3.0 | 17–23 | 58–76 | 224–288 | 56–64 | 10 / shield, slow | 660 |
| 14 | 171–221 | 214–238 | 2.1–3.05 | 372–452 | 3.0–3.0 | 17–25 | 61–79 | 224–288 | 60–68 | 11 / shield, slow, double | 690 |
| 15 | 178–228 | 205–229 | 2–2.95 | 380–420 | 3.0–3.0 | 17–23 | 64–82 | 224–288 | 64–72 | 11 / shield, slow, double | 720 |

Road spacing also enforces a time gap (1.95 seconds early, decreasing gradually to 1.25 seconds in the finale). The spawner waits if the spatial/time gap is not clear. Speed variation is small, 2.4–6.8%. No vehicle overtaking is introduced.

Railway tracks use opposite directions, staggered initial delays (3/7/11 seconds within a section), independent intervals and the existing shared quiet window. Warnings are 4 seconds in the introduction, 3.4 in the middle and 3 in advanced routes. Safe delay is 4 seconds early and 3 later. The existing section scheduler can extend intervals for a guaranteed quiet crossing window.

Water starts with 320-pixel decks moving at 40/48 pixels per second. Later routes mix 224/256/288-pixel decks. Directions alternate. Spawn intervals are tuned to deck length/speed, leaving small gaps; the exact per-lane intervals are listed in `M11_LEVEL_DATA.json`. Existing water validation rejects gaps above 96 pixels and excessive movement during a hop. No slippery or weather-dependent movement was added.

All authored pickups are on Start/Safe sections, never on an unsupported water cell or live track. Center-path coins reward progress; side coins and powers require optional positioning. The campaign has 4–11 coin sites and at most three power sites per level. A multiplier can increase earned coins using the existing rules.

## Scores, stars and save compatibility

The scoring formula is unchanged: forward progress, destination points, time/life bonus and the configured target reward. Every campaign target grants +100 points. Star rules are unchanged: one for completion, one for at least 35% time remaining, one for at least two lives. Three stars therefore do not require retaining all three lives or collecting every coin.

The first five IDs remain `greenway`, `level_02`, `level_03`, `level_04`, `level_05`. Existing completions, stars and best scores remain associated with these campaign positions. Completing the old five levels unlocks the new Level 6. New IDs continue through `level_15`. The save schema, coins, character ownership and selection are unchanged; no migration/reset occurs.

The first five campaign layouts/names are intentionally redesigned for this milestone. Their old Resources remain under `resources/levels/level_01.tres` through `level_05.tres` for compatibility and regression fixtures; the active catalog points to `resources/campaign/`. Previously earned scores may be harder to beat on redesigned shorter routes. They are retained rather than silently erased. Three-star ratings do not depend on those scores.

## Result and failure architecture

`LevelResultPanel` is a reusable screen-space Control created by the existing HUD. CrossingGame still owns score, lives, state transitions and saving. The result card shows a level heading, LEVEL COMPLETE, filled/unfilled stars, Score, Best Score and Coins This Run. The three buttons are PLAY AGAIN, LEVEL SELECT and NEXT LEVEL, with 84-pixel logical height. At Level 15, Next is absent and a campaign-complete message appears.

Failure uses the same reusable presentation component in a separate state: TRY AGAIN, Score, Best Score and Coins This Run, with PLAY AGAIN and LEVEL SELECT only. No stars, Next button or celebration are created. Coins already collected remain banked, and failure scores can still update the saved best, matching the existing economy.

Terminal states disable InputRouter and world simulation. The modal blocks pointer input; explicit focus neighbors keep navigation on the result buttons. The opaque card and background shade preserve readability across all six themes. Weather freezes behind the panel through the existing world pause state. Retry/menu/Next remove the whole result subtree, including celebration and its audio player. Menu hides world atmosphere; retry and Next reuse the existing reset/configuration path for camera, traffic, railway, water and activation.

## High-score celebration and sound

CrossingGame reads the previous saved best before writing. It applies the existing target reward, compares the final score using strict `>`, then saves the result. Only successful runs that exceed that previous best create a celebration. Equal scores, lower scores and failed runs do not.

`ResultCelebration` draws exactly four small bursts, delayed by 0.08, 0.34, 0.62 and 0.94 seconds. Each lasts one second, then the component stops processing. There are 18 simple rays per burst, one reused AudioStreamPlayer and no continuous particle system or dynamic lights. Bursts sit around/behind the card. Cleanup frees the entire subtree on navigation.

`assets/audio/firework.wav` is an original 0.22-second synthesized noise/pop made for this project, covered by the project's MIT license. Each burst plays it when sound is enabled. The existing completion cue is retained. Mute prevents burst playback.

To replace the sound without code:

1. Import your original or appropriately licensed WAV/OGG into `assets/audio/`.
2. Open `scenes/main.tscn`.
3. Select the **HUD** node.
4. In Inspector, drag the audio asset into **Celebration Sound**.
5. Save the scene. Clear the property to intentionally use silent fireworks.

The preview inherits this main scene. Test both SOUND ON and SOUND OFF on your actual device; playback dispatch was automated here, but speaker loudness is a manual check.

## Exact Inspector editing instructions

Campaign order lives in `resources/levels/campaign.tres`, in its **Levels** array. The actual new level files are `resources/campaign/level_01.tres` … `level_15.tres`.

1. Stop the running game and select the desired campaign `.tres` in FileSystem.
2. Edit **Display Name** for the title and **Time Limit** for seconds. Keep **Level Id** unchanged to preserve saved records. **Level Number** controls its visible number; catalog order controls Next/unlock.
3. Expand **Section architecture → Presentation**, or drag a preset from `resources/themes/` into Presentation. The older **Theme** string is not the weather selector.
4. Expand **Section architecture → Sections**, then click the desired section Resource. Ordered array position determines placement. IDs and local pickup coordinates keep rewards attached when whole sections move.
5. In a Road section, expand **Road Lanes**, then a LaneConfig. Edit **Direction**, **Speed**, **Spawn Min/Max**, **Vehicle Types**, **Minimum Clear Gap**, **Minimum Gap Seconds**, **Speed Variation**, **Variation Period** and **Pattern**. Lane count is the array size. Allowed road types are `car`, `truck`, `bus`; trains belong in Railway sections. Duplicate a lane Resource/Make Unique before changing a shared entry.
6. In a Railway section, expand **Railway Tracks**, then a RailwayTrackConfig. Edit **Direction**, **Speed**, **Warning Seconds**, **Interval Min/Max**, **Initial Delay**, **Safe Delay**, **Train Length** and **Timing Variation**. Array size is track count (1–3). Keep warnings at least 2 seconds and enough for section traversal/reaction; the compiler checks this. Train intervals describe safe-clear-to-next-warning delays, not time between train fronts.
7. In a Water section, expand **Water Lanes**, then a WaterLaneConfig. Edit **Direction**, **Platform Speed**, **Platform Type**, **Platform Length**, **Minimum Spacing**, **Spawn Min/Max**, **Spawn Variation**, **Speed Variation** and **Variation Period**. The lane array sets the count. Spawning uses pooled spatial pitch based on speed × interval, bounded by deck length/spacing. If validation rejects a gap, reduce Spawn Max or increase deck length.
8. In a Safe section, **Safe Rows** changes its thickness. Keep deliberate observation areas near difficult transitions. Start and Destination remain exactly first and last.
9. For coins, expand a Start/Safe section's **Pickups** array. Add a **New PickupPlacement** Resource; set **Cell** X to a column and Y to a local row inside that section. Leave **Power** empty for a coin. Column 8 is the central route; cell `(8,0)` in Start is the spawn and is rejected.
10. For a power-up, use another PickupPlacement and drag `resources/powerups/shield.tres`, `slow.tres` or `double.tres` into **Power**. Pickups must be unique, unblocked Start/Safe cells. The compiler rejects hazard placements. Use sparse powers; do not increase every lane's speed to compensate for them.
11. Any authored section pickups replace the automatic LevelConfig **Coin Count/Power Ups** placement for that level. New campaign files set those automatic fields to zero/empty. Legacy/example levels with no authored placements continue using automatic placement unchanged.
12. Edit **Score Target**, **Target Reward**, **Star Time Fraction** or **Star Lives Required** only after testing. Save the Resource, set the campaign preview's Starting Level, and use Run Current Scene. These resources need no gameplay script edits.

## Automated and rendered validation

Godot 4.5.2 on Linux, using headless real-node/physics tests and a Compatibility software-rendered window. This is not a physical Windows/Android test.

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Core/M1–M2 | 135 | 0 |
| Phase 3 | 103 | 0 |
| Phase 4/progression | 62 | 0 |
| M6 sections | 68 | 0 |
| M7 railway | 88 | 0 |
| M8 water | 73 | 0 |
| Water routes | 3 | 0 |
| M9 long levels | 142 | 0 |
| Long routes | 2 | 0 |
| M10 themes | 109 | 0 |
| Theme routes | 6 | 0 |
| M11 campaign integration | 372 | 0 |
| M11 route checks | 60 | 0 |
| **Total** | **1223** | **0** |

The M11 route suite performs 45 ordinary-input, real-physics runs (three seeds × 15 levels) and 15 checks that each level has a three-star run. All 45 runs completed; 44 earned three stars, and Level 14 seed 711 earned two stars after losing two lives. The first route test required every sampled run to earn three stars; that was stricter than the design requirement. The final test separately verifies completion for every sample and three-star achievability for every level. No gameplay parameters or player state were altered to make those runs pass. The pilot predicts nearby hazards, so its fast completion times do not represent human difficulty.

Integration tests cover unique IDs/names, configuration validity, theme assignment, safe pickups, unlock 1–15, final-level bounds, score/best/stars/coins, strict pre-save record detection, equal/lower scores, finite muted/audible burst dispatch, failure economy, retry/menu/Next cleanup, final-level backtracking, pause and save compatibility. Tests use isolated profiles. Existing five-level regression assumptions use an explicit legacy catalog fixture instead of being deleted or weakened; M11 tests exercise the actual new catalog.

The Phase 4 corrupted-save fixture intentionally logs parse diagnostics while its recovery tests pass. Final editor import completed without parser/script errors, and all 359 complete literal file references resolved. Logs are recorded in `validation_m11/`. A Windows Desktop resource-pack export validates packaging; it is not an executable or Android build.

28 real rendered captures include each campaign level, completion cards under all six themes, normal completion, failure, final completion and top/bottom Level Select. Failure was also rendered at 1920×864 and 800×360. Representative gameplay and result frames were visually inspected for readability and overlap. Staged captures are separate from route tests. See `screenshots/m11_*.png`.

To rerun: `godot --headless --path <project-folder> --fixed-fps 60 res://tests/campaign_tests.tscn` and `res://tests/campaign_route_tests.tscn`. Other regression scenes remain in `tests/`.

## Windows manual checklist

1. Back up your project/save, install the patch, reopen Godot and confirm clean import. Run Project and verify the 15 cards, names, locks, stars and existing wallet/characters.
2. With a fresh test profile, complete Levels 1–15 in order. Confirm each completion unlocks the next without requiring three stars. With your existing profile, verify old unlocks/results survive. Do not delete your normal save to test this; use a separate project/user-data test copy.
3. Run `tools/campaign_preview.tscn` for quick access to any route. Try every level with keyboard arrows/WASD. Compare early/middle/late difficulty and report sections that feel repetitive, too fast or too forgiving.
4. Observe every train warning, both directions and triple tracks on Danger Zone. Wait on the adjacent safe row, then cross a quiet window.
5. Ride boats/logs on River Hop, River Rush, Wild River and the finale. Test lateral hops, lane transitions, water death/respawn and shield rescue.
6. Move forward and back through long routes. Check camera bounds, offscreen activation, reappearing traffic/platforms and continuous rain/snow. Test pause/resume on Rain Run and Snow Way.
7. Collect center and side coins; try shield, slow traffic and double rewards. Check the wallet immediately and after restart. Switch characters and verify equal gameplay behavior.
8. Finish with at least two lives and 35% time left: expect three stars. Finish slowly or with one life: check lower ratings. Inspect Score, Best Score and Coins This Run.
9. On a first/new-best successful run, confirm NEW HIGH SCORE and exactly four brief bursts with sound. Replay below/equal to that score: no celebration. Toggle mute and repeat. Existing legacy best scores can be higher than a redesigned route's typical score; use a fresh preview profile to test the first-record case.
10. Lose all lives, then separately run out of time. Expect TRY AGAIN, no stars/Next/fireworks, correct score/best and retained collected coins. PLAY AGAIN must immediately reset the same level; LEVEL SELECT must work.
11. From completion, exercise all three buttons. Check no duplicate actors, weather or bursts. Confirm Level Select shows new records and returns to the played card. Test keyboard focus, Enter and held/released input around each transition.
12. Complete Level 15: expect campaign-complete text and only PLAY AGAIN / LEVEL SELECT. No Level 16 request.
13. Resize the window; check result cards and scrollable menus. Return to normal Run Project and verify preview testing did not change normal progress.

## Android landscape manual checklist

1. Export a normal debug build with your existing SDK/templates/settings and use a test install/profile. No release/publishing work is part of this milestone.
2. Swipe-scroll all 15 Level Select entries, including bottom cards. Check names/stars/lock contrast and character navigation. Unlock in order or use a separate developer build for quick access.
3. For the developer build, use a temporary project copy, change main scene to `tools/campaign_preview.tscn`, remove `tools/*` from Android export exclusions, and use a different package ID such as `org.pocketcrossing.m11preview`. Keep your production project/export settings unchanged.
4. Test split-thumb buttons, swipe controls and finger release near UI. Test actual Road/Railway/Water play, water riding/rescue, camera scrolling and backtracking.
5. Play Rain Run, Snow Way, Fog Track, Midnight Run and the finale. Check night/fog readability at normal phone brightness, steady frame pacing, heat and weather continuity.
6. Pause/resume, background/restore the app, die and retry several times. Check timers and hazards resume correctly without duplicated effects.
7. Verify completion card Score, Best Score, Stars and Coins. Tap PLAY AGAIN, LEVEL SELECT and NEXT LEVEL; check large targets and no movement behind the modal. Verify failure lacks Next/stars/fireworks.
8. Beat a prior best with sound on: observe four brief bursts and four quiet pops; repeat muted. Check no serious frame drop during weather plus celebration. Judge speaker volume on the actual device.
9. Complete Level 15 and verify only replay/select. Return to Level Select, quit/reopen, and verify wallet, stars, high scores, unlocks and selected character persist.
10. Test on the smallest target phone and a wider/notched landscape device. Confirm controls/cards remain reachable, focus does not get stuck and scrolling does not accidentally select another level.

## Performance and remaining limitations

Existing activation freezes distant hazards without destroying their pools. Weather remains one camera-local system, independent of level length. Rewards are small fixed collections. Celebration is four bounded bursts with 72 rays total and one audio voice; it stops in about two seconds and is removed on navigation.

Human difficulty/pacing feedback and physical Android/Windows checks remain necessary. Sampled automated routes demonstrate completion and three-star achievability, not a mathematical proof for every random traffic seed or every human decision. No device FPS/battery claims are made. The original placeholder train/platform art remains. Coins are deliberately safe-section rewards; moving-platform-attached or live-hazard coin placement is not implemented. Existing best scores are retained across redesigned layouts and may no longer be directly comparable.

No new weather system, movement penalties, procedural campaign, Bangladesh content, progression redesign or Play Store release work was added. The next milestone is not started.

## File changes

`M11_FILES.txt` lists every created/modified path relative to completed M10, including all import sidecars, screenshots and validation logs. `M11_LEVEL_DATA.json` gives exact per-lane balancing data for every authored level. The main changes are the 15 new campaign Resources/catalog, optional PickupPlacement Resource, result/celebration components, HUD and game integration, preview/capture tools and tests.

### Created source/configuration files

- `assets/audio/FIREWORK_LICENSE.txt`
- `assets/audio/firework.wav`
- `resources/campaign/level_01.tres`
- `resources/campaign/level_02.tres`
- `resources/campaign/level_03.tres`
- `resources/campaign/level_04.tres`
- `resources/campaign/level_05.tres`
- `resources/campaign/level_06.tres`
- `resources/campaign/level_07.tres`
- `resources/campaign/level_08.tres`
- `resources/campaign/level_09.tres`
- `resources/campaign/level_10.tres`
- `resources/campaign/level_11.tres`
- `resources/campaign/level_12.tres`
- `resources/campaign/level_13.tres`
- `resources/campaign/level_14.tres`
- `resources/campaign/level_15.tres`
- `scripts/data/pickup_placement.gd`
- `scripts/ui/level_result_panel.gd`
- `scripts/ui/result_celebration.gd`
- `tests/campaign_route_tests.gd`
- `tests/campaign_route_tests.tscn`
- `tests/campaign_tests.gd`
- `tests/campaign_tests.tscn`
- `tests/fixtures/legacy_campaign.tres`
- `tools/campaign_preview.gd`
- `tools/campaign_preview.tscn`

### Modified files

- `README.md`
- `resources/levels/campaign.tres`
- `scripts/core/game.gd`
- `scripts/data/level_section_config.gd`
- `scripts/ui/game_hud.gd`
- `scripts/world/road_level.gd`
- `tests/long_level_tests.gd`
- `tests/phase3_tests.gd`
- `tests/phase4_tests.gd`
- `tests/section_tests.gd`
- `tests/theme_tests.gd`
- `tools/capture_campaign.gd`
- `tools/capture_campaign.tscn`

New `.uid`/`.import` sidecars, this guide, balancing JSON, captures and test records are individually enumerated in `M11_FILES.txt`. No pre-existing files were deleted.
