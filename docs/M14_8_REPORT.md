# Pocket Crossing M14.8 — Map depth, mastery and challenges

Implementation and automated validation completed against the stable M14.7 project. Physical Windows/Android acceptance testing remains. No new normal maps, cosmetic system, networking redesign, ranking formula, account system, timer redesign, or M14.9 work.

## Recovery and work completed

The interrupted work had already introduced map tuning, valued pickups, mastery Resources, challenge Resources, account fields and UI integration. Its temporary working directory was lost between sessions. The durable M14.7 checkpoint/update and the retained implementation details were used to recover that work. Existing M5–M14.7 systems were reused, not rebuilt.

This continuation restored the changes and previous fixes, completed validation, checked all coin placements and challenge routes, inspected rendered UI/gameplay, and packaged a verified M14.7-to-M14.8 update. Fixes included dependency ordering in the .tres files, One Life's inherited star/lives validation, keeping the original night/day presentation when applying fog, rejecting mastery evaluation with missing/invalid stats, and identifying train deaths during a hop. The old single-coin test now explicitly selects a normal-value coin.

## 1. Files changed

`M14_8_FILES.txt` is the exhaustive list, separated into created and modified files. Nothing is deleted. The ZIP contains only these differences from M14.7, including Godot UID files, test scenes, documentation and validation evidence.

Main code groups:

- New Resources: `scripts/data/mastery_goal.gd`, `scripts/data/challenge_config.gd`.
- New services: `scripts/core/map_depth_progress.gd`, `map_run_stats.gd`, `challenge_catalog.gd`.
- New UI component: `scripts/ui/map_depth_hud.gd`.
- Integration: existing MapGame/ModeGame, MapHUD/ModeHUD/ModeNavigation, profile validation, pickup rendering/placement, lane phase offset, and host race pickup/stat accounting.
- Data: existing four `resources/maps/*.tres`; six new `resources/challenges/*.tres`.
- Tests: `map_depth_tests`, `map_depth_routes`, `map_depth_visual`; adjusted normal-coin selection in `map_campaign_tests`.

`lan_session.gd`, `lan_match_rules.gd`, input scripts, camera/streaming implementation, water support, train mechanics, character data, map catalog and export settings remain byte-identical to M14.7.

## 2. Four map signatures

| Map | Mechanical differences |
|---|---|
| Village Crossing | Five road lanes, baseline speeds 140/175/165/195/155; weighted rickshaw groups alongside CNG, local bus, pickup and small car. Two congestion-wave lanes use 14-second cycles, 4.5-second no-new-spawn windows and phase offsets 0/6. Existing vehicle-specific speeds and safe following distance remain active. |
| City Rush | Seven road lanes instead of six, alternating directions, 195–255 baseline speeds, 12% configured speed variation, 1.6–2.4 spawn interval requests. Phased 16-second cycles with six-second no-new-spawn windows and alternating offsets 0/8, separated by a safe median. Existing vehicles finish crossing during a closed spawn window. |
| River Delta | Four alternating water lanes with deck lengths 144/208/176/240, speeds 60/82/72/96 and spacing 48/64/80/56. No oversized boats or changes to riding, landing, edges, drowning or respawn. Coins encourage optional lateral positioning and timed landings. |
| Night Express | Four highway lanes at 260/290/275/300, 10% variation, 1.7–2.5 interval requests; two rail tracks at 420/500 with warnings 3.2/3.6 seconds, initial delays 3/8, intervals 9–13/11–15 and safe delays of four seconds. Night lights, warnings and safe islands remain. |

These are configuration differences, not only different graphics. Existing fairness guards still clamp actual spawn spacing and constrain rail/water configurations. Roads keep at least 1.4 seconds of configured gap. No guarantee is made that an arbitrary reckless route or every possible seed is survivable without waiting; tested routes demonstrate viable choices, not an exhaustive proof of all random states. Night has the strongest hazard parameters; human difficulty ordering still needs playtesting.

## 3–4. Coins and risk/reward

| Pickup | Currency | M14.7 competitive score contribution |
|---|---:|---:|
| Normal | 1 | +50 |
| Ringed risk coin marked “3” | 3 | +150 |

Temporary Double Rewards multiplies pickup value by two. Double Coins challenge also multiplies pickup value by two; both together yield normal=4 and risk=12. Neither multiplier affects mastery or map-completion rewards. Existing pickup effects and currency saves are reused.

Village and City retain eight coin objects: two safe and six hazard placements, with two of the hazard coins worth three. Base available pickup currency is 12 per attempt. River and Night retain twelve coin objects: three safe and nine hazard placements, including two risk coins. Base available currency is 16. There is no coin-node increase.

Hazard placement requires explicit `PickupPlacement.on_hazard=true`; power-ups remain on safe sections. All positions are interior, unique and unblocked. River coins pay only after a valid supported hop; merely riding past a fixed coin position does not collect it. All 40 authored coin positions were reached by an automated player issuing ordinary movement through real physics.

Pickups are once per player per attempt. Each host racer retains its own collected-cell dictionary. A peer taking a coin does not logically remove it for others. Retry restores pickups, as before; legitimate later attempts can earn coins again. This is not an anti-farming system. Network receipts and completion state guards prevent duplicate result payouts; mastery has permanent one-time flags.

## 5–6. Mastery goals and rewards

All goals require finishing five crossings in normal Local or Friends Play. Challenge runs intentionally do not award normal-map mastery. Coin targets count earned pickup currency, including a temporary coin multiplier; risk targets count distinct risk pickups, not multiplied currency.

| Map | Goal 1 | Goal 2 | Goal 3 |
|---|---|---|---|
| Village | Finish in ≤80 seconds | Collect ≥10 coin value and finish | Finish with zero deaths |
| City | Finish in ≤95 seconds | Collect both risk coins and finish | Finish with ≤1 death |
| River | Finish without water deaths | Collect both river risk coins and finish | Finish in ≤120 seconds |
| Night | Finish in ≤125 seconds | Finish without train deaths | Collect ≥12 coin value and finish |

Every goal gives **15 coins once**, plus its completed marker. Maximum 45 per map / 180 across all four maps. Worse runs never remove completion. Shield absorption does not count as a death. No goal is needed to unlock or complete a map. Existing coin unlock prices remain 0/65/100/155; normal completion rewards remain 20/25/30/35.

Each map has Inspector-editable `mastery_goals: Array[MasteryGoal]`. Stable goal IDs identify account flags; do not change IDs casually after release. Conditions use a generic completed-run stats dictionary. Evaluation happens at results, not in per-frame scans.

## 7. Local-only challenges

| Variant | Maps | Modifier |
|---|---|---|
| Rush Hour | Village, City, Night | Road speeds ×1.12 (cap 350); interval requests ×0.8 (floor 0.8); existing minimum-gap rules unchanged |
| Fast River | River | Platform speeds ×1.12 (cap 110), spacing ×0.9 (floor 24); deck sizes and edge rules unchanged |
| Heavy Fog | Village, Night | Existing lightweight fog at 0.22 strength / 0.55 intensity; original time-of-day palette retained, player highlight and vehicle/train lights enabled |
| One Life | All four | One life; shield still absorbs a protected hit; one actual life-losing hit ends the attempt |
| Double Coins | Village, River | Pickup value ×2; normal completion rewards; stacks with the temporary Double Rewards pickup |
| No Shield | City, Night | Shield placements and fallback shield list entries removed for that attempt only |

Fourteen curated map/variant combinations; no modifier stacking menu. Main menu → Challenges → map → PLAY. Locked maps remain locked until purchased in normal Local Play. Retry retains the chosen variant and resets attempt stats. Returning to normal Local/Friends clears the variant.

`ChallengeConfig.apply()` deep-copies the existing map Resource. No duplicated map layouts and no mutation of the normal map Resource. Change variant definitions in `resources/challenges/`; extend the catalog for future variants.

## 8. Challenge records and scoring

Per-account records use `map_id/challenge_id`: completed marker, fastest completed time, highest attempt score. An unsuccessful later attempt cannot remove completion or replace a completed best time. Its score can improve the challenge best score. Normal Local Best Time and Friends time records are not overwritten.

Scoring calls the unchanged `LanMatchRules.score()`:

`max(0, safe*1000 + collected_coin_value*50 - deaths*150 + completion_bonus)`

Completion bonus is `2500 + floor(remaining)*25`, only at five safe crossings. For local challenges, `remaining = max(0, map.time_limit - elapsed)`; the four existing resources specify 600 seconds. This is a bonus reference, not a new countdown or timeout. Local gameplay continues using its existing elapsed timer. Challenge scores are separate and should not be compared with Friends matches using a different selected time limit. Completion/mastery wallet bonuses are excluded from pickup score.

## 9. Automated validation

Godot 4.5.2 stable, Linux x86_64, isolated test save directories:

- Editor import: no GDScript/parser errors.
- All 25 preserved regression suites passed: 4,344 reported assertions in this run, plus successful route/performance helpers without assertion summaries. Counts involving generated presentation can vary between runs.
- New focused suite: **203 passed, zero failed**. Covers all definitions, phase windows, independent copies, normal/risk/multiplied coins, once-only collection, goal boundaries, incomplete/missing stats, one-time rewards, account isolation, reload, malformed-field backup recovery, failed-write rollback, separate best records, pause, Retry, modifier cleanup, One Life, No Shield and host per-player stats.
- Normal map route suite: **12/12** five-character completions (four maps × three seeds), real movement/physics.
- New route suite: **68/68**: 28 five-character challenge completions (14 variants × two seeds), plus all 40 authored coin positions reached through real movement. No teleport, invulnerability override, hazard removal or extra lives in these route tests. Per-coin probes are separate attempts; they do not prove every coin can be taken on one crossing.
- Competitive rules tests: **24/24**; competitive flow: **27/27**.
- Real four-process competitive ENet suite: **52/59/56/61 passed**, zero failures, identical final results across peers. Includes full 60-second expiry and score-mode completion.
- Real four-process map/race suite: **122/74/74/74 passed**, zero failures, identical results.
- Navigation/stabilization: **28/28** and **24/24**. Host/client replay: **8/8** and **7/7**.
- Packaged update applied over fresh M14.7: see `clean_validation.log` for import, main-scene smoke, reference validation and focused tests.

Existing deliberately corrupt legacy-save fixtures emit expected parse diagnostics, and two older test scenes emit resource-at-exit diagnostics already present before this milestone. They are not new game parser errors; clean import/main/focused runs are checked separately. No blanket claim that every historical test log contains zero `ERROR` strings.

## 10. Visual/manual inspection performed here

Inspected Compatibility-renderer captures of the main menu, four map cards, mastery details, challenge selection, challenge results, River gameplay/coin markings, City lanes and Night/Fog warning visibility. Small-window captures render at a 640×360 gameplay viewport after requesting an 800×360 window; controls and text stayed within the canvas. Screenshots are included in `m148_screenshots`.

Gameplay validation here uses automated movement through real physics. It is not a human Windows or Android play session. The automated player's predictive routing is better than human reaction and does not establish human mastery-time difficulty or the ideal hardest-map ordering.

## 11–12. Android testing and performance

Physical Android devices tested: **none**. Physical Windows devices tested: **none**. No APK build or phone battery/thermal measurements performed here. Existing Android/Windows export settings, split-touch controls, swipe handling and keyboard input are unchanged.

No new per-frame mastery scans, particle systems, dynamic lights, shaders, physics bodies or per-level weather nodes. Risk coins reuse the same drawn pickup node; counts remain eight/eight/twelve/twelve. City adds one road lane; all other hazard counts stay unchanged. Challenge Resource copies are created on selection, not every frame.

Software-rendered low-resolution Heavy Fog sample: 180 frames, median 20.0 ms, p95 27.45 ms, peak total scene nodes 134. This is Mesa llvmpipe on the test container, not Android performance and not a GPU benchmark. A prior higher-resolution/concurrent test was slower; do not extrapolate phone FPS from these numbers. Existing traffic headway performance helper completed successfully. Confirm sustained performance on your target Android hardware.

## 13–15. Local, Friends and save compatibility

Normal Local still uses five arrivals, elapsed time, existing lives/collision/shield, character selection, camera, water support and completion behavior. Normal best-time records remain distinct from challenge records. Friends retains authoritative host movement, per-peer pickups, selected time/ranking, score formula, receipts and session flow. Only valued-coin/stat fields and final mastery evaluation were added to that flow.

The LAN **content revision** is `m14.8-depth-1`; every peer must use the same M14.8 build. This intentionally rejects mixing old map/coin content with new content. Transport/protocol architecture is unchanged.

Existing version-1 account database remains version 1. Optional `mastery` and `challenges` dictionaries are added inside each existing profile; absent fields mean empty progress. Wallet, selected character, unlocks, normal times, Friends times, receipts and legacy data retain their existing paths/keys. Existing backup/atomic-save handling is reused. Flags/record updates and rewards roll back together on write failure. No theme data or duplicated account files are introduced.

## 16. Exact acceptance tests on your devices

### Windows

1. Back up M14.7, merge the update as in `M14_8_INSTALL.txt`, open `project.godot`, wait for import and click main Play. Confirm username, coins, unlocked maps, skin and previous normal times are retained.
2. Open Local Play. Confirm exactly four maps. Open each MASTERY button; check three goals and return without changing account or map unlocks.
3. Finish five crossings on each map. Observe Village's mixed traffic/waves, City's seven lanes/medians/phases, River's varied moving decks, and Night's highway speeds/two independent rail warnings. Tell me if Night does not feel hardest in human play.
4. Collect a normal coin (+1), then ringed “3” (+3). Revisit the cell before Retry: no second payout. In River, land on a deck under a coin; unsupported landings must still fail normally. Ignore risk coins and confirm completion remains possible.
5. Complete an eligible mastery goal. Check +15 once and the card count. Replay with a worse result, quit/reopen, and confirm the marker remains without another one-time reward.
6. Try every available challenge/map combination. Rush Hour should change roads; Fast River boats; Fog visibility. One Life must end on one actual unshielded death. No Shield must have no shield pickups. Double Coins: normal +2/risk +6, or +4/+12 with temporary Double Rewards. Completion reward remains normal.
7. Pause mid-challenge for ten seconds, resume, die, Retry and complete. Check paused timer, fresh attempt counts and no duplicate reward. Result return goes back to Challenges. Verify separate challenge records survive restart and never replace normal Best Time.
8. After One Life/No Shield/Fog/Double Coins, return to normal Local. Confirm three lives, original theme, normal shield placements and normal coin values.
9. Test keyboard, mouse buttons, Escape/Back and confirmation cancellation on new screens. Resize the landscape window; no hidden PLAY/MASTERY buttons.
10. With 2–4 devices all on M14.8, test both ranking modes and a timed match. Have two players take the same risk coin: each earns its own +3/+150. Finish five crossings, check results/mastery, replay and rejoin; no duplicate receipt or mastery bonus. Return to Local afterward.

### Android

1. Export/install over your working app using the same package/signing setup, preserving app data. Confirm account, wallet, maps and selected character remain.
2. Test split-touch and swipes on all four normal maps. Finish five crossings; check scrolling, water edge/riding, rail warnings, shield and respawn.
3. Tap each map tab and challenge row; verify labels/buttons in your landscape aspect ratio and Android Back navigation. Check locked maps cannot launch a challenge.
4. Run Night Heavy Fog and River Fast River for several minutes. Judge warning readability, boat edges, frame pacing, heat and battery use on the actual phone. Do not accept hidden hazards or missed input.
5. Pause/background/resume, Retry, complete a challenge, return to normal play, force-close/reopen. Confirm modifiers clean up and records/mastery persist.
6. Test Android↔Windows and Android↔Android Friends Play on the same LAN/hotspot with matching M14.8 content. Check per-player risk pickups, deadline/results and replay.

Keep feedback about human difficulty, mastery targets and low-end device visibility for tuning. No additional milestone has been started.
