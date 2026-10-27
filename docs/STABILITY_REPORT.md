# Pocket Crossing — multiplayer stability, dog and presentation pass

## 1. Overall status
Implementation and available automated validation are finished. **Device acceptance is pending.** This is a focused update to the delivered refinement build, not M15. The original premature-results trigger was not reproduced in the restored build; do not treat that issue as conclusively diagnosed. The result boundary is now guarded and the reported scenario passes real multi-process tests. No new maps, modes, progression systems or release work.

## 2. Vehicle entry root cause
`LanHazards.receive()` instantiated and added a client vehicle with its default x=0, then only stored its authoritative position anchor. The actual position was assigned in a subsequent physics callback. A render between these events could display the default transform. Sparse repairs also replaced position directly, and improved clock samples could step the synchronized time. Host vehicles were initialized at their spawn position before entering the tree, explaining the asymmetry. There is no MultiplayerSynchronizer competing with this path.

## 3. Exact networking fix
Calculate the current x from the host sample's x, velocity and timestamp before add_child. Set type, direction, color, speed and collision configuration before insertion, disable local movement before and after tree entry, and reset physics interpolation once at creation. Existing IDs prevent duplicate instances. The host already spawns beyond both playfield edges using the vehicle envelope; those fair spawning rules were preserved. Small repair offsets decay exponentially; severe divergence (180 pixels) may snap. Clock refinements slew at at most 0.025 seconds per second during play. The existing host sample is a current authoritative motion anchor, so a separate original-spawn timestamp is unnecessary.

## 4. Before/after synchronization
Before: possible default-transform frame, followed by timestamp reconstruction; later repairs/time synchronization could jump. After: correct timestamp-based position on the first frame, one transform writer, decaying small corrections, gradual clock refinement. This fixes a concrete initial-transform defect; real Wi-Fi jitter still requires the side-by-side acceptance test. Long packet stalls retain the existing two-second extrapolation cap.

## 5. Music
Four original synthesized compositions: Village Breeze (warm plucked tones/pad, 32s), City Steps (soft rhythmic tones, 25.6s), River Drift (slow flowing pad, 48s), Night Rails (soft low electronic pulse, 38.4s). Each EnvironmentProfile has Inspector-editable `music_track`. One persistent player fades out, switches, then fades up; same-track requests never restart it. Independent saved Music/Sound settings remain. Default music -23 dB, important-cue ducking -33 dB. Source synthesis is included; no commercial music/samples. Map changes select music through the existing environment setup. Menus keep the current soft track.

## 6. Graphics by map
Village: extra fine grass tufts and soft prop grounding shadows. City: raised-looking paving edge strips and shadows. River: bank pebbles/striations, shallow ripple arcs and grounded dock props. Night: reflective safe-edge markers and grounding shadows. Existing original houses, stalls, vegetation, boats, headlights, railway signals, themes and weather are reused. No collision/layout changes. Four rendered screenshots are included in `docs/stability_screenshots`; they were visually inspected. This is restrained decorative polish, not an art redesign.

## 7. Dog notification
Compact warm `DOG ALERT! MOVE!` panel beside the player, pulsing indicator and shrinking reaction bar. It stays inside the safe lane. Existing single DogView is reused and cleared on death/reset/menu/result. No new overlay per section.

## 8. Dog lifetime root cause
The generic eligibility/movement branch ran before the running-attack branch. Any valid hop or displacement greater than eight pixels immediately changed phase to idle, deleting the visible committed pass. It was not a short lifetime timer. A completely stationary dog attack did reach its target in automated tests; the device-reported case may include small displacement.

## 9. Dog lifecycle fix
Handle the committed running pass before pre-attack eligibility/movement checks. A running dog traverses its original dry lane until swept contact or full exit beyond the playfield. Moving to another row escapes while the dog continues naturally. Small displacement no longer erases it. Before commitment, valid movement cancels the warning. Death, inactive run and scene reset still clear it. Shield and damage reuse CollisionRules and the existing one-life-loss path.

## 10. Bark
One short two-woof synthesized burst when the warning ID is first displayed, with no repeated bark every frame. The new original bark uses voiced harmonics and a short noisy breath. SOUND OFF suppresses it independently of music. Host snapshots continue to expose only the recipient's dog. Quality is subjective: speaker/headphone acceptance remains required.

## 11. Eligible lanes
Village and City: safe_2, safe_4. River and Night: safe_2, safe_4, safe_6. Each map supplies its own DogConfig with explicit section IDs. `allows()` also requires SAFE_SECTION; Start, Destination, Road, Railway and Water never qualify. Standard defaults remain 3s stationary grace, 1s warning, 300px/s speed and 5s cooldown. No automatic dog on every future safe section unless its map opts in.

## 12. Water sound
Replaced `water_entry.wav` with a 1.15s layered low body impact, broad splash and decaying turbulence/bubbles. New file uses the same centralized cue, so accepted water contact selects it once and existing damage/respawn guards prevent duplicates. No scream or drowning audio. Four-peer tests verified one accepted water death and one owner-only sound. Real speaker listening is needed to judge whether it meets your requested natural person-sized splash feel.

## 13. Premature-result root-cause findings
The inspected normal race loop already checks all racer states; it did not contain a last-survivor or first-finisher rule. No automatic path reproducing the exact device symptom was found. However, `LanSession.finish(rows)` trusted any host caller and did not itself reject active/missing participants. That was a real validation gap, now closed. Do not confuse this defensive fix with proof of the device trigger. If the symptom returns, note map, ranking mode, timer value, participant statuses and whether host used End Match/Back.

## 14. Match-end logic
Capture the match participant roster at prepare. The authority's final-result boundary rejects empty rows, duplicate peers, active/respawning/finishing states, missing original participants and missing connected members. Allowed states are finished/out/disconnected; time_up is accepted only after actual expiry. The race's own completion check uses the same predicate. Finishers see `FINISHED · WAITING FOR OTHER PLAYERS…`; remaining players keep input. Ranking and scores are unchanged. Explicit host End Match remains the existing separate cancellation behavior.

## 15. Automated totals
1502 passing assertions, zero failing assertions across the listed final runs. Resource loading: 328 scripts/scenes/resources loaded in the final clean-copy parser sweep. 792 concrete res:// references checked, none missing. Final clean-copy editor import, parser sweep and all 208 focused checks succeeded. Windows-preset PCK export and headless startup succeeded; this is not a Windows executable or Android-device test. Detailed assertion counts: `STABILITY_VALIDATION.json`. Repeated focused runs are not added twice.

## 16. Multi-instance tests
Three actual ENet processes: first two finish, last stays active eight seconds; an explicit premature finish attempt is rejected; last finishes and all receive results. 28 assertions pass. Final two clients: maximum per-physics-tick vehicle displacement 4.59/4.65px, 16 peak vehicle replicas, no duplicate replica creation. Four-process dog/water test: 59 assertions pass, own-only chase/audio plus shared feed preserved. Four-process competitive regression: real 60s expiry, ranking/coin rules, all-player result agreement and a second round pass. Detailed per-peer totals are included. Loopback networking is not a substitute for Wi-Fi testing.

## 17. Windows/manual tests actually performed
No physical Windows device was available. Godot 4.5.2 Linux headless execution, software-OpenGL rendered captures and pack startup were performed. Four map screenshots were visually inspected for readable hazards, player, controls and safe-lane alert. No Windows playthrough claim.

## 18. Android tests actually performed
No physical Android device was available. Existing Android landscape layout, split-touch/swipe code, renderer choice and export settings were preserved. No measured Android FPS or speaker-quality claim.

## 19. Exact physical-device checklist
1. Back up the project; close Godot; apply this update to the previous refinement build. Update every LAN device (content revision changed).
2. Put Host and Client side-by-side. On all four maps watch slow rickshaw, CNG, car, bus and truck enter both edges for several minutes. Record any first-frame flash, reverse snap or later repair jump. Test real Wi-Fi distance as well as near-router.
3. Play each map and listen to its distinct soft loop. Open/close pause/settings without an unnecessary restart. Switch maps and listen for a smooth fade. Toggle Music independently from Sound, close/reopen and verify persistence. Listen to warnings over music.
4. Inspect grass, paving, bank ripples, night markers and shadows. Verify coins, train warning lights, water platforms and selected character remain readable. Compare Android performance with your prior build.
5. In every intermediate eligible dry safe lane, stay still for 3s: alert and bark should start together, then dog entry after about 1s. Do not move: dog must reach/hit you once. Verify one life loss, feed message and normal respawn.
6. Move during warning: cancel safely. Move to another row after dog begins: dog must continue across its original lane and exit. Move only slightly in the same row: it must not disappear. Try shield, pause/resume, Retry and death from another hazard; no stale dog or alert.
7. Stand at Start and on noneligible road/rail/water/destination areas: no dog warning. Repeat River testing only on dry banks.
8. Fall into River water repeatedly. Listen for one strong body-sized splash aligned with contact/visual, one life loss and one respawn. Test Sound OFF. Check platform riding remains unchanged.
9. Three-player Friends Play, Time ranking: finish Host and one client first, leave the last client at 4/5. They must continue; finishers wait. Finish the last player and confirm final rank/time/score.
10. Repeat with Host as the last unfinished player; repeat in Score ranking. Then repeat allowing actual timer expiry, last-player life exhaustion and last-client disconnect. Results must follow valid terminal resolution, not the second finisher.
11. Check Local Play all five crossings, coins, characters, save/reload, road/rail/water death, Back/Exit, Retry and map selection. In LAN verify own-only rendering and dog sound, shared dog feed and host map/duration selection.

## 20. Performance findings
No additional hazard/prop physics nodes or weather systems. Decorations are cached draw commands for the camera window. Dog remains one view per device with bounded state per racer. Music remains one persistent player plus the existing four effect voices; loops cached once per selected Resource. Result predicate sends no extra RPCs. Final headless clients had about 1204 render-process samples over the short race with p95 frame intervals 6.91/6.92ms; these are loopback headless timing, NOT graphics FPS or Android benchmarks. Initial-transform and repair bounds are asserted. No long Wi-Fi soak or baseline Android FPS comparison was possible.

## 21. Known limitations
Device-reported premature-results cause remains unconfirmed despite hardened finalization and a passing reproduction scenario. Audio naturalness and real Wi-Fi entry smoothness need your acceptance. Extremely late packets beyond the existing two-second extrapolation horizon can still pause/snap hazards. Some older test/startup harnesses emit ObjectDB shutdown warnings; new focused and three-peer tests exit cleanly. Intentional corrupt-save tests log their expected parse errors. An initial route-test wall-time budget was too short; the successful accelerated deterministic rerun replaces that timeout result.

## 22. Local Play regression
All four maps complete five automated crossings across three seeds each. Phase 3/4, sections, rail, water, long-level/theme, map campaign/routes and contact suites pass. Progression schema, account system, selected characters, controls and layout resources remain compatible. Only explicit dog opt-ins and presentation assignments changed map data.

## 23. Friends Play regression
Host/Join, map selection, rule selection, movement prediction, navigation, owner-only rendering/audio, dog feed, score/time rankings, actual expiry and replay covered by retained suites plus new three-peer tests. Final boundary accepts only terminal participants. All devices must use the update because the content revision is m14-stability-2.

## 24. Update ZIP and installation
`PocketCrossing_Stability_Update.zip` is a copy-over update for the already-installed refinement build. Close Godot, back up, extract, copy CONTENTS of PocketCrossing into the existing folder containing project.godot, replace files, reopen and allow import. No manual deletion or save reset. Python generator is optional development source, not required to run/export the game. Tests/tools/docs stay excluded by existing export settings. No M15 work.

## Exact files changed
Created:

- assets/audio/STABILITY_AUDIO_LICENSE.txt
- assets/audio/city_steps.wav
- assets/audio/city_steps.wav.import
- assets/audio/night_rails.wav
- assets/audio/night_rails.wav.import
- assets/audio/river_drift.wav
- assets/audio/river_drift.wav.import
- assets/audio/village_breeze.wav
- assets/audio/village_breeze.wav.import
- docs/STABILITY_REPORT.md
- docs/STABILITY_VALIDATION.json
- docs/stability_screenshots/city_rush.png
- docs/stability_screenshots/city_rush.png.import
- docs/stability_screenshots/night_express.png
- docs/stability_screenshots/night_express.png.import
- docs/stability_screenshots/river_delta.png
- docs/stability_screenshots/river_delta.png.import
- docs/stability_screenshots/village_crossing.png
- docs/stability_screenshots/village_crossing.png.import
- tests/stability_pass_tests.gd
- tests/stability_pass_tests.gd.uid
- tests/stability_pass_tests.tscn
- tests/stability_peer_tests.gd
- tests/stability_peer_tests.gd.uid
- tests/stability_peer_tests.tscn
- tests/stability_visual.gd
- tests/stability_visual.gd.uid
- tests/stability_visual.tscn
- tools/generate_stability_audio.py

Modified:

- assets/audio/dog_bark.wav
- assets/audio/water_entry.wav
- resources/environments/city.tres
- resources/environments/railway.tres
- resources/environments/river.tres
- resources/environments/village.tres
- resources/maps/city_rush.tres
- resources/maps/night_express.tres
- resources/maps/river_delta.tres
- scripts/core/audio.gd
- scripts/core/mode_game.gd
- scripts/data/environment_profile.gd
- scripts/network/lan_config.gd
- scripts/network/lan_hazards.gd
- scripts/network/lan_race.gd
- scripts/network/lan_session.gd
- scripts/presentation/dog_view.gd
- scripts/presentation/environment_layer.gd
- scripts/world/dog_encounter.gd
