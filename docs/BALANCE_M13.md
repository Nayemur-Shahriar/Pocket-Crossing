# M13 — Campaign balance and repeating high-score celebration

## Status and installation

The M13 implementation and local automated/render validation are finished. **Native Windows hands-on balance testing and physical Android performance/touch acceptance remain pending.** Predictive automated routes prove tested opportunities exist; they do not prove the intended difficulty feels right to a human. M14 has not been started.

This is ONE incremental ZIP for the completed M12 project. Close Godot, back up the project, and extract/merge the ZIP directly into the folder containing `project.godot`, replacing matching files. Do not create a nested project folder. No files need deleting. Reopen Godot 4.5.2 and wait for imports. Run Project still opens the campaign. Existing player saves are not included or reset.

For isolated testing, open `tools/campaign_preview.tscn`, select the root, set **Starting Level** (1–15), and click **Run Current Scene** in the toolbar; an F6 key is not required. This existing preview uses `user://campaign_preview_profile.cfg`, not the normal `user://profile.cfg`. Open `tools/speed_preview.tscn` the same way to watch all nine vehicle categories move together from a common starting line. Its root exposes Lane Speed and Lane Modifier; the Restart Together button repeats the comparison without save writes.

## Inspection and scope

M12 already supplied shared road motion/collision, pooled train and water runtimes, finite section layouts, camera/activation, themes, environment art, coins, power-ups, character ownership, saves and result UI. These were inspected alongside all 15 campaign Resources before editing.

The audit found three actual hazard lanes in Level 1, one shared runtime speed for all vehicles within a road lane, 320-pixel platforms in the first river, and a four-burst finite celebration. M13 changes those points and tunes the authored campaign. It preserves the section compiler, camera, streaming, railway warnings/damage, WaterSupport/carry logic, weather, Bangladesh art, controls and save schema.

The old scoring owner also reset forward progress after a hit/rescue, allowing repeated forward points for recrossing the same rows. M13 retains the run's furthest row through damage; retry still resets it. Existing legacy multi-destination levels can still complete, but recrossed rows no longer award duplicate progress points.

## Campaign table

Hazards count only Road lanes, Railway tracks and Water lanes. Start/Safe/Destination are excluded. No extra campaign levels were added.

| # | Level | Hazards | Road | Rail | Water | Time | Difficulty |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Easy Road | 5 | 5 | 0 | 0 | 85s | Moderate |
| 2 | City Run | 6 | 6 | 0 | 0 | 95s | Moderate |
| 3 | Sunset Rush | 7 | 7 | 0 | 0 | 105s | Moderate |
| 4 | Night Ride | 8 | 8 | 0 | 0 | 115s | Moderate+ |
| 5 | Train Time | 8 | 7 | 1 | 0 | 125s | Moderate+ |
| 6 | Double Track | 9 | 7 | 2 | 0 | 135s | Moderate+ |
| 7 | River Hop | 9 | 7 | 0 | 2 | 145s | Challenging |
| 8 | Rain Run | 10 | 9 | 1 | 0 | 145s | Challenging |
| 9 | River Rush | 11 | 6 | 0 | 5 | 155s | Challenging |
| 10 | Snow Way | 12 | 9 | 3 | 0 | 155s | Hard |
| 11 | Fog Track | 14 | 10 | 4 | 0 | 165s | Hard |
| 12 | Wild River | 15 | 9 | 1 | 5 | 175s | Hard |
| 13 | Midnight Run | 17 | 11 | 3 | 3 | 185s | Very Hard |
| 14 | Danger Zone | 18 | 10 | 5 | 3 | 195s | Very Hard |
| 15 | Final Crossing | 20 | 12 | 3 | 5 | 205s | Final Challenge |

Every level has at least five hazards. Level 1 now has five actual roads with car/CNG traffic in both directions. Later repetitive road rows were trimmed to fit the requested finale length rather than padding the campaign. Section order, safe observation areas, themes, environment profiles and stable level IDs remain.

| # | Balance change |
| --- | --- |
| 1 | 3 → 5 roads in two groups; faster car/CNG mix, alternating directions, central rest strip. Still no rail/water. |
| 2 | 5 → 6 city roads; rickshaw/microbus/van speed differences and optional coin detours. |
| 3 | 6 → 7 roads; wave lanes introduce deliberate openings under Sunset. |
| 4 | 7 → 8 roads; asymmetric direction pattern, visible night traffic and one optional shield. |
| 5 | 6 → 8 hazards; seven roads plus first rail track. Long warning and rest areas introduce observation. |
| 6 | 8 → 9 hazards; seven roads and two independently timed tracks, preserving the section quiet window. |
| 7 | 8 → 9 hazards; first river shortened from 320-pixel decks to 192/224, with slow currents. |
| 8 | 10 hazards retained; Rain road/rail mix, wave intervals and one strategic Slow pickup. |
| 9 | 11 hazards retained; five water lanes with 160/176/192-pixel decks and mixed directions. |
| 10 | 12 hazards retained; Snow plus three tracks. Road speed modestly increased without weather physics. |
| 11 | 14 hazards retained; four tracks under Fog; extra warning allowance compared with the ordinary warning curve. |
| 12 | 16 → 15 hazards; one repetitive road removed. Ferry/fishing/engine/passenger transitions now require smaller-deck timing. |
| 13 | 18 → 17 hazards; one road removed, night highway and 128-pixel log with larger ferry/engine alternatives. |
| 14 | 22 → 18 hazards; redundant road lanes trimmed, all five tracks and three water lanes retained. Varied directions and three optional powers. |
| 15 | 26 → 20 hazards; twelve roads, three tracks, five water lanes. Repetition reduced while retaining all established hazard groups, fastest road tier and two river crossings. |

## Vehicle speeds and safe following

Base speed is the speed in pixels/second at Lane Speed 150 and Speed Modifier 1, before variation or power-ups.

| Vehicle ID | Base px/s | Behavior |
| --- | --- | --- |
| rickshaw | 85 | Slow; clear difference from motor vehicles |
| large_truck | 100 | Slow cargo; large footprint |
| medium_truck | 110 | Medium-slow cargo |
| local_bus | 125 | Medium; larger footprint |
| delivery_van | 130 | Medium |
| cng | 150 | Medium-fast |
| pickup | 150 | Medium-fast cargo |
| microbus | 160 | Medium-fast passenger transport |
| small_car | 185 | Fast |

Nominal cruise speed is:

`vehicle Base Speed × (lane Speed / 150) × lane Speed Modifier × existing level ramp × lane variation × Slow Traffic scale`

Old car/truck/bus/train IDs keep the neutral 150 base for legacy examples. The nine M12 types receive the distinct bases above. Different road Resources have their own speed, interval, direction and pattern; this is not a single campaign multiplier. Representative campaign lane references range from 133 upward to the low 240s; the fastest car cruise approaches 300 px/s before small variation. Buses and cargo vehicles remain slower despite their larger collision envelopes.

TrafficLane keeps a front-to-back vehicle list, maintained on spawn/exit rather than sorted every frame. Each actor requests its own cruise speed. A faster follower slows only when necessary to retain the configured visual-edge gap behind its leader; it cannot overtake through another vehicle or collapse the crossing gap. In congestion, two vehicles may temporarily travel at the same speed. Once unobstructed, each uses its category speed. Spawn-space checks use the largest lane envelope and maximum configured speed. Slow Traffic retains type differences and cannot stop traffic entirely.

Early minimum time gaps are 1.4 seconds, decreasing to 1.05 seconds late; clear-space floors decrease from 240 to 170 pixels. The actual required gap is the larger of the pixel floor and maximum speed × gap seconds. Requested spawn intervals decrease per tier, but a blocked entrance retries without accumulating a burst. Selected lanes retain wave openings. Initial spacing now has a deterministic per-lane seeded phase, preventing identical vehicle positions from forming an accidental straight-through opening across the whole board.

All campaign levels retain three lives. Spawn protection is reduced from 0.9 to 0.25 seconds: the Start row is safe, and the old protection could cover several opening hops. Shield hit protection and existing damage/respawn behavior are unchanged. Legacy example Resources retain their previous settings.

## Smaller watercraft

One grid cell is 64 pixels. Campaign decks now span 128–224 pixels (2–3.5 cells), rather than 224–320. Different sizes are configured per lane; there is no new water movement system.

| Water type | M12 length px | M13 length px | M13 speed px/s | Category |
| --- | --- | --- | --- | --- |
| wooden_boat | 256–320 | 160–192 | 62–66 | Small/medium, slower |
| passenger_boat | 288–320 | 176–224 | 74–90 | Medium/large, medium speed |
| engine_boat | 224 | 160–176 | 98–110 | Medium, faster |
| ferry | 256–288 | 208–224 | 68–74 | Large, slower |
| fishing_boat | 256 | 160 | 80 | Small/medium |
| log | 256 | 128 | 78–82 | Small |

The early river uses the more forgiving 192/224 decks; middle rivers mix 160/176/192 with 224 ferries; later rivers include 128 logs and 160/176/208 boats. The ferry is still larger but slower than the engine boat.

Visual drawing already scales to `platform_length`, and `FloatingPlatform.supports_x()` uses `length / 2 - 18`. Changing the Resource therefore resizes both the picture and the actual horizontal support boundary. Platforms do not use a separate giant physics rectangle. The highlight remains aligned with the support deck. Existing pooling count, wrap/cleanup distance and spatial pitch also derive from length, so they adapt to the shorter boats.

Spawn intervals were recomputed with length and speed: visible open-water gaps are 40–68 pixels, not the old intervals applied blindly to shorter decks. The existing maximum-open-water validation remains; the compiler also checks platform displacement during a hop against usable deck width. M13 lowers the supported authoring length bound to 112 pixels, but the shipped campaign minimum is 128. New backtracking route tests cross the actual smaller platforms forward, backward and forward again without teleporting or changing hazards.

## Railway and timer tuning

Early trains warn for about 3.6 seconds, decreasing to 2.6 late; Fog Track receives an extra 0.2-second allowance. Configured safe delays remain at least about 2.6 seconds. Intervals shorten by tier, directions remain mixed, and individual tracks retain independent timings. The existing section coordinator guarantees a quiet traversal window between batches; no train spawns without its warning. Activation freezes/resumes existing clocks rather than inventing a catch-up train. Existing pause, respawn and reactivation regressions still pass.

Timers follow the campaign table: longer early levels receive more time, while the trimmed finale gets 205 seconds rather than 235. These allow waiting and mistakes; the tighter challenge is the three-star time target, not forced reckless movement. Actual human pacing still needs device feedback.

## Coins, prices, powers, scores and stars

| # | Coins | Powers | 3-star time limit for run | Score target |
| --- | --- | --- | --- | --- |
| 1 | 4 | None | 23.80s | 650 |
| 2 | 5 | None | 26.60s | 695 |
| 3 | 5 | None | 31.50s | 740 |
| 4 | 6 | shield | 34.50s | 785 |
| 5 | 6 | shield | 38.75s | 830 |
| 6 | 7 | shield | 41.85s | 875 |
| 7 | 7 | shield | 46.40s | 600 |
| 8 | 8 | slow | 46.40s | 965 |
| 9 | 8 | shield | 51.15s | 1010 |
| 10 | 9 | slow | 51.15s | 1055 |
| 11 | 9 | shield | 56.10s | 1100 |
| 12 | 10 | shield, double | 61.25s | 1145 |
| 13 | 10 | shield, slow | 64.75s | 1190 |
| 14 | 11 | shield, slow, double | 70.20s | 1235 |
| 15 | 11 | shield, slow, double | 73.80s | 1280 |

Coins remain safely authored on Start/Safe rows. Near-route coins (usually column 7) are easy choices; lateral coins move toward columns 11/5, then 13/3, then 15/1 as the campaign advances. These require extra travel and a different approach to the next hazard. They are optional route/time risks, not coins placed directly in train paths or unsupported water. Pickups never block movement. Counts remain 4–11 per level, totaling **116** base coins across the campaign.

Economy estimates (design assumptions, not player telemetry): collecting 40–60% gives roughly 2–7 coins per run depending on level; collecting 70–100% gives roughly 3–11. At 50% campaign collection the wallet earns about 58 coins; a small replay supplies the remaining two for both paid skins. A full four-coin Level 1 replay remains worth four; coins are banked on collection even if a run fails.

Prices are unchanged: Pip and Mint free, Coral 20, Violet 40. These remain attainable without immediate full ownership. Purchase prices now live in an Inspector-editable CharacterPrices Resource. Save IDs/ownership are unchanged; raising a future price never relocks an owned character. Characters remain cosmetic.

Power placement remains authored, not random. Levels 1–3 have none; 4–11 generally have one strategic pickup; 12–13 two; 14–15 three. Shield remains one-hit/12 seconds, Slow remains six seconds at the existing 0.65 scale, Double remains eight seconds. Slow retains the pre-existing intentional railway scaling; water speed is unaffected. Every level has at least one tested completion without activating a power-up. Powers are useful choices, not a required lucky spawn.

Scoring uses the existing categories: 25 per new forward row, 250 per destination, four per remaining whole second, 100 per remaining life, and a 100-point target reward when earned. Double retains existing behavior on progress/destination rewards and coin collection. Coins remain currency rather than introducing another scoring subsystem. Score targets range from 650 to 1,280. Better time/lives increase score; dying and repeating rows no longer farms progress. Old best scores are retained as historical records; changed balancing means scores from different milestones are not perfectly comparable.

The existing star rule is retained: one star for completion; one extra for meeting the time threshold; one extra for at least two lives. Three stars need both, not perfect lives. Per-level remaining-time fractions are 0.72 down to 0.64, giving the elapsed run limits in the table. Existing saved stars are never reduced. Failed runs still award no completion stars or level unlocks.

## Repeating fireworks

Only successful results whose final score exceeds the **previous** best create ResultCelebration. Equal/lower results and failures create none. The best-score comparison and save order remain in CrossingGame.

The existing lightweight drawn effect now repeats with varied 0.75–1.25-second spacing, position jitter, angle and scale. Bursts live one second; at most two are active by default (a hard configurable cap of three). Each burst uses 18 rays and one short original project blast sound when sound is enabled. One AudioStreamPlayer has polyphony one. A stalled frame emits at most one burst, never a catch-up storm. Local visual RNG does not change traffic RNG.

No Timer or particle nodes are created per burst. Expired drawing entries are removed. `stop()` disables processing, clears bursts and stops the voice synchronously. HUD cleanup invokes it before removing the result panel. Panel visibility changes and `_exit_tree()` also stop it. Play Again, Next Level, Level Select, hidden panels and scene exits therefore cannot leave a running celebration. Repeated completion creates one owned effect per current result panel.

A **61.002-second actual rendered run** produced **58 bursts / 58 sound triggers**, with **at most two active bursts** and **157 scene nodes at both start and end**. Replay immediately stopped/cleared it. The software-rendered Linux run processed 1,507 frames (about 24.7 average FPS); that environment is not a Windows/Android hardware benchmark, and no mobile FPS claim is made. Audio triggers and voice state were checked with the Dummy driver; audible volume/timing still needs device listening.

## Exact Inspector instructions

Always edit `resources/campaign/level_01.tres` through `level_15.tres` for the active campaign. `resources/levels/level_*.tres` are historical examples. Save with Ctrl+S, then run the campaign preview at that level.

1. **Vehicle base speed:** open `resources/vehicles/rickshaw.tres` (or another vehicle Resource) and edit **Base Speed**. The base is normalized to lane Speed 150. Do not resize its collision unless you deliberately want a size change.
2. **Lane speed/modifier:** open a campaign level → **Section architecture → Sections** → a **ROAD_SECTION** → **Road Lanes** → desired LaneConfig. Edit **Speed** and **Speed Modifier**. The type base remains independent. Speed Variation controls the small shared lane variation, not category identity.
3. **Vehicle type, direction and spawning:** in that LaneConfig edit **Vehicle Types** using catalog IDs from the speed table, **Direction**, **Spawn Min/Max**, **Minimum Clear Gap**, **Minimum Gap Seconds**, and **Pattern**/wave cycle values. Repeated type IDs weight selection. Minimum gap checks may delay a requested spawn.
4. **Number of roads:** resize the Road Lanes array. Create/duplicate a LaneConfig for each entry; keep explicit directions/gaps. Safe rows do not count toward the five-hazard campaign rule. Rerun `tests/balance_tests.tscn` after authoring to check counts.
5. **Boat type/size/speed:** Sections → **WATER_SECTION → Water Lanes** → desired WaterLaneConfig. Assign **Visual** from `resources/water/visuals/`; edit **Platform Length**, **Platform Speed**, **Direction**, **Spawn Min/Max** and **Minimum Spacing**. Clear Visual to use legacy Platform Type, such as log. Changing art alone does not change length. For a length L and speed V, `(L + desired gap) / V` is a starting interval; keep pitch gaps under the validated maximum and test real transfers.
6. **Train settings:** Sections → **RAILWAY_SECTION → Railway Tracks** → track Resource. Edit **Speed**, **Direction**, **Warning Seconds**, **Interval Min/Max**, **Initial Delay**, **Safe Delay**, **Train Length** and optional Visual. The warning must cover traversal plus reaction time. The existing section quiet window may extend the nominal schedule for fairness.
7. **Time/lives:** at the level root edit **Time Limit** and **Starting Lives**. Under **Movement feel**, Spawn Protection is a short respawn guard; it is not the shield duration.
8. **Stars/scoring:** root → **Rewards** → **Star Time Fraction** (required remaining fraction) and **Star Lives Required**. For example 0.70 means finish within 30% of the total timer for the time star. Root score properties control Forward Points, Destination Points, Seconds Bonus, Life Bonus; **Progression and environment** contains Score Target/Target Reward. Higher remaining-time fractions are stricter.
9. **Coins/powers:** Sections → a START/SAFE element → **Pickups**. Each PickupPlacement has a section-local Cell. Clear **Power** for a coin; assign `resources/powerups/shield.tres`, `slow.tres` or `double.tres` for a power. Use unique cells, avoid the spawn/blocked cells, and do not put pickups in hazard sections. Explicit placements override automatic Coin Count/Power Ups for these campaign levels.
10. **Character costs:** open `resources/progression/character_prices.tres`; edit **Coral** and **Violet**. Prices affect future purchases only. Existing ownership is retained. The two free skins remain free.
11. **Power duration/strength:** open its existing `resources/powerups/*.tres` file. Edit Duration, Traffic Scale or Reward Multiplier as appropriate. Shared Resources affect all levels using them; duplicate for a specific authored variation.
12. **Fireworks:** open `resources/presentation/celebration.tres`. Edit Delay Min/Max, Burst Lifetime, Max Active Bursts and Rays. Runtime clamps keep count/rays bounded; ship the tested 0.75–1.25 / one-second / two-burst defaults until device-tested.

Theme and Environment assignment remain the M10/M12 workflows. No core script needs editing to tune these values.

## Automated validation and evidence

Godot 4.5.2 on Linux: **2,756 assertions passed, zero failed**, counting each suite once. `docs/validation_m13/` contains complete logs.

| Suite | Passed |
| --- | ---: |
| Core/input | 135 |
| Phase 3 | 103 |
| Phase 4/save/progression | 62 |
| M6 sections | 68 |
| M7 railway | 88 |
| M8 water + route | 73 + 3 |
| M9 long level + route | 142 + 2 |
| M10 themes + route | 109 + 6 |
| Campaign/results | 372 |
| Campaign physics routes | 75 |
| M12 identity integration | 997 |
| M13 balance/runtime/cleanup | 516 |
| M13 water backtracking routes | 5 |

Campaign route checks comprise 45 completed real-physics runs (three seeds per level, with 0/4/9-second waits at Start), 15 three-star attainability checks and 15 power-free completion checks. The driver emits normal hop inputs, predicts nearby actors, and does not teleport, grant immunity, remove hazards or alter clocks. It is more precise than a human. Level 15 completed in all three tested cases; final logged elapsed times were 9.9/10.3/16.5 seconds, showing that a highly predictive driver is not a suitable human difficulty benchmark.

M13 tests measure actual actor movement for every category in both directions, lane scaling/Slow effects, faster-follower headway, hazard counts, time/star settings, price/owned-skin compatibility, water support boundaries, power preservation, 60 simulated seconds of bounded fireworks and synchronous cleanup on navigation/hide. Water routes cover Level 7/9/12/13/15 forward → backtrack → recross with three lives remaining. Older suites retain shield, pause, retry, unsupported water and scene transitions.

The M11 finite-firework assertion was updated to the explicitly requested repeating behavior. M12's old no-gameplay-tuning snapshot assertion was replaced with stable campaign ID/name/theme preservation because M13 intentionally changes those parameters. Its art/collision/streaming checks remain. The route predictor now reads each actor's actual speed instead of assuming a lane-wide speed.

Fresh-cache import passed without parser/script errors. All **451 external scene/resource references** resolved. Windows/Android resource-pack exports and packed headless startup passed; these are not native EXE/APK device playtests. All current source/art files match the fresh-import verification copy. Screenshots in `docs/screenshots/m13_*` cover all 15 representative level views, result/menu variants, the measured speed comparison and live celebration. These were visually inspected; no old M12 artwork was rebuilt.

Older tests occasionally retain audio playback objects when fast-forwarded to engine exit. Final Railway/Water/Phase 4 reruns used normal time and exited cleanly. Phase 4 deliberately logs corrupted-save/write-failure diagnostics to test recovery. Software-renderer V-Sync warnings are environmental, not parser failures. The M13 audio test explicitly stops global cue voices before shutdown.

To rerun: import the project, then run `godot --headless --path <project> --fixed-fps 60 tests/balance_tests.tscn`, `tests/campaign_route_tests.tscn` and `tests/balance_water_routes.tscn`. The remaining scenes correspond to log names. Use an isolated user-data directory for automated runs. Capture tools are developer fixtures and do not constitute native manual testing.

## Windows manual acceptance — pending

1. Open the M12 project with this update, let imports finish, and Run Project. Check your real wallet, skins, stars, best scores and unlock order survived. Use the isolated campaign preview for balance trials.
2. Play Levels **1, 3, 5, 7, 9, 11, 12, 13, 14 and 15** using arrows/WASD. Level 1 must require attention across all five roads while remaining easiest; 3 should add road complexity; 5 readable rail timing; 7 usable smaller decks; 9 varied transfers; 11 readable Fog warnings; 12 advanced river timing; 13/14 mixed mastery; complete 15 at least once. Record completion time/lives and whether a wait felt unavoidable. Human feedback, not only the intended label, decides the final difficulty curve.
3. Open the Speed Preview. Watch all types for four seconds from the same start. Rickshaw must visibly lag car/CNG, and trucks/bus differ. In a real mixed lane, verify a fast vehicle safely follows slower traffic without overlap. Test Slow and normal speed restoration.
4. On water, try small → medium and medium → small, opposite directions, different speeds, waiting for the next deck, backtracking and recrossing. Stand near the visible support boundary, deliberately miss a boat, respawn and Retry. There must be no invisible wide support or drowning while the feet are safely inside the highlighted deck.
5. Test train warnings after waiting, approaching, retreating/backtracking and reactivation. Pause during a warning, a ride and rain/snow, then resume. Check Shield with road/train/water and normal life loss at zero lives.
6. Collect near and detour coins, test all powers, buy a skin on a disposable test profile, quit/reload and verify ownership. Confirm retry/respawn cannot repeatedly score the same forward rows.
7. Earn a real new best by completing a run. Leave its result panel open **60 seconds**. Bursts and short pops must repeat; buttons/text stay readable. Listen for one pop per burst when sound is on. Mute/unmute. Press Play Again, then repeat for Level Select and Next Level: effects/audio must stop immediately each time.
8. Complete with an equal/lower score: normal completion without fireworks. Fail with a high temporary score: no stars, no Next Level, no fireworks. Check final-level completion has no nonexistent Next Level. Test window resizing and standard landscape controls.

## Android manual acceptance — pending

1. Use your existing Android export/signing workflow on a test device with retained app data. No Play Store/release work is included. Verify save/character compatibility after installation.
2. Play **Levels 1, 5, 7, 10, 12 and 15** in landscape. Test split-touch up/down/left/right and swipe. Faster roads and smaller decks must remain readable and touch-playable; neither HUD nor props should cover controls or hazard signals.
3. Cross water, ride, transfer, backtrack, die and retry repeatedly. Check railway + weather + traffic during activation boundaries; watch for stutter and unexpected collisions/support.
4. Earn a new high score and leave the result open for **at least 60 seconds**. Observe FPS/frame time, memory, node count where available, sound repetition and button response. Repeat exit via all three buttons. There must be no increasing particles/audio or effect remaining on menus/gameplay.
5. Test on a representative lower-end device, in normal phone lighting, including Night/Fog. Record device/GPU, resolution, sustained FPS and any difficult input/visibility cases. Linux software rendering does not certify Android performance.
6. Close/reopen and check coins, stars, best scores, selected character and unlocks. Test existing background/focus behavior without treating it as new release certification.

## Known limits and completion boundary

- Windows/Android hands-on acceptance is not performed here; M13 is a locally verified balance candidate until those checks pass. Subjective difficulty labels require human feedback. No claim is made that every possible random seed or human route is proven fair.
- Predictive route tests can cross much faster than a human; three-star limits intentionally leave room for observation and input. If players still find early levels too easy or small decks too demanding on touch, adjust the exposed Resources after measured device trials.
- Mixed-speed vehicles intentionally match a leader's speed in a queue; individual base speeds are observable when unobstructed. Gap protection takes precedence over overtaking.
- Existing best scores/stars remain historical. They are not cleared or renormalized when balance changes, so some old records may be harder to exceed.
- Coins stay on safe ground because the existing authored pickup architecture deliberately rejects hazards. Optional challenge comes from lateral route/time choices, not a new risky-water-coin mechanic.
- No new artwork, weather, camera, streaming, multiplayer, economy subsystem or campaign levels were introduced. The two new supporting Resources are celebration settings and purchase prices. No M14 or publishing work is included.

## Exact files

`docs/M13_FILES.txt` lists every new and modified file relative to M12, including script UIDs, capture evidence and validation logs. `docs/M13_BALANCE_DATA.json` records every level's hazard counts, individual road/rail/water settings, coin/power positions and scoring/rating settings. Those files and this report are included in the single update ZIP.
