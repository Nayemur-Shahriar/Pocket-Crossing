# Pocket Crossing M14.7 — completion report

This update extends the confirmed M14.6.1 project. It does not rebuild gameplay, add maps, or start M14.8/M15.

## Inspection and recovery

The saved M14.7 checkpoint already contained host match settings, the host-clock countdown, score/ranking rules, Time Up, result awards, and bounded 4–6-rocket fireworks. Those systems were preserved. The interruption had cleared the temporary final package. This continuation recovered the prior finishing changes: batched spark drawing, readable result panels, a distinct original Time Up sound, consistent completion-time calculation, corrected test fixtures, and final validation/packaging.

The underlying M14.6.1 LAN transport, player prediction, own-character-only rendering, map selection, collision/shield logic, water riding, account system and Local Play were reused. No map, movement/hazard configuration or save schema migration was required.

## Install this source update

1. Close Godot and back up your working PocketCrossing folder.
2. Extract `PocketCrossing_M14_7_Update.zip`.
3. Merge the **contents of its PocketCrossing folder** into your existing project folder containing `project.godot`. Replace matching files and retain all other files. Do not create a nested PocketCrossing/PocketCrossing folder or delete the old project.
4. Open your existing `project.godot` in Godot 4.5.2. Wait for imports, then use the main Play button.
5. Export/install the same update on every Friends device. The LAN content version is now `m14.7-competitive-1`; older versions are intentionally rejected.

This ZIP is source code, not an APK or Windows executable. It contains no normal player saves. `M14_7_FILES.txt` lists every delivered new/modified file with its purpose.

## Match settings and synchronization

The host can select **60, 90, 120 or 150 seconds**, and **FASTEST TIME or HIGHEST SCORE**, while in the lobby. Guests see the authoritative selection but cannot change it. Selected buttons and the mode label make the choice explicit.

Both values travel in the existing reliable lobby state. Changing just these settings does not reload the map, alter its seed/revision or invalidate map readiness. They are locked when loading/countdown begins.

The existing future host timestamp drives 5→1→GO. Each device derives remaining time from the synchronized host clock:

`max(0, duration - max(0, host_now - start_at))`

The HUD displays the ceiling of remaining seconds as MM:SS, rather than decrementing an independent timer. A small label identifies the ranking mode. At ten seconds the timer becomes prominent and a small TIME RUNNING OUT message appears. One lightweight tick plays for each second 5–1; a separate original two-note cue marks Time Up. All honor the existing sound preference.

## Exact Friends score

```
max(0,
    safe_characters * 1000
  + (2500 if safe_characters == 5 else 0)
  + collected_coins * 50
  + (floor(remaining_at_completion) * 25 if safe_characters == 5 else 0)
  - deaths * 150)
```

Only host-accepted destinations, pickup cells and genuine life losses change these inputs. Each destination/pickup is once-only per player. Shield absorption is not a death; the existing respawn/out state prevents duplicate death penalties. Completion time and remaining-time bonus use the same timestamp when the fifth destination is accepted.

There is no sixth character and no post-finish farming. Friends no longer includes forward-hop or remaining-life score bonuses. Existing coin-multiplier power-ups still increase earned coins; each credited coin contributes 50 points. Safe/completion bonuses are not multiplied.

The existing map-completion wallet coin reward is retained separately as `reward_coins`, so it is not miscounted as collected coins in competitive scoring. Existing receipt deduplication and Friends Best Time saving remain. Local Best Time, unlocks and Local scoring are unchanged.

## Ranking and ties

| Group | Ordered priorities |
|---|---|
| TIME, overall | Finished 5/5 above unfinished |
| TIME, finished | Lower completion time; higher score; more coins; fewer deaths; lower peer ID |
| TIME, unfinished | More safe characters; higher score; more coins; fewer deaths; lower peer ID |
| SCORE | Higher score; more safe characters; lower completion time if both completed; fewer deaths; more coins; lower peer ID |

The last tie-break is deterministic within the match using host-assigned peer IDs. It is not a permanent account advantage. Finished-player ranks remain provisional until final results, allowing later higher scores to move ahead in SCORE mode.

## Time Up and final results

At the host deadline, active participation ends once. Direction submission/validation, command entry, arrivals and damage reject expired play. Actors/world freeze and pending movement is cleared. Clients stop prediction at the host-derived deadline while awaiting host confirmation.

TIME UP! appears for approximately **1.25 seconds**, then the host sends final ranked rows and awards in the existing reliable authority-only result RPC. Repeated expiry cannot add score, replay the transition or duplicate rewards. If all racers finish, lose all lives or disconnect, results can appear earlier.

TIME mode shows Rank | Player | Time | Score; SCORE mode shows Rank | Player | Score | Time. Every row also includes safe progress, coins and deaths. Unfinished expired rows show TIME UP; an early-ended race can retain OUT/DISCONNECTED statuses.

Compact awards are fastest finish (finishers only), highest positive score, most positive coins, and fewest deaths among players with meaningful progress/coins. Meaningless awards are omitted. Award ties use peer ID. One player can receive several without repeated large cards.

Only the local winner with a positive score gets Friends fireworks, after final results. Active gameplay and nonwinner result screens do not get that celebration. Local NEW BEST TIME retains its original trigger and cleanup.

## Fireworks

- Random **4–6 rockets** per wave.
- **0.45–0.80-second** launch-to-launch interval.
- Default stagger **0.10 seconds**, configurable between **0.07 and 0.18**.
- Hard maximum **six active waves / 36 retained rocket records**. Capacity delays launches without accumulating catch-up waves.
- One reusable audio node, one voice, minimum **0.25 seconds** between explosion sounds.
- Original rising trails, varied positions/heights, large colored bursts, center flash and falling secondary sparks remain.
- Vertex buffers are reused per rocket; three batched spark draws replace many individual draw calls. No per-rocket nodes or timers.
- Information panels keep results and awards readable. Leaving/replaying clears the effect immediately.

## Automated verification and performance

Tests were run with Godot 4.5.2 on Linux. Final logs and result packets are included in `docs/m147_validation`.

- Editor import/parser and scene/resource reference checks.
- Pure competitive rules suite: **24 passing checks**, covering requested ranking examples, formula/floor, tie priorities, awards, variation and a simulated 120-second firework run.
- HUD/expiry/audio flow: **27 passing checks**, covering one tick per second, mute, warning text, rejection before phase transition, Time Up once, final results and return to Local Play.
- Four real ENet processes: all eight duration/mode combinations, host-only settings/finalization, no map reload for settings, synchronized GO, a real 60-second expiry, no duplicate deaths/pickups, late-event rejection, a SCORE-mode finish, identical rows and awards, and unchanged Local Best.
- Existing four-process/four-map ENet regression: movement prediction, own actor visibility, shield/death/respawn, once-only rewards/goals, road/train/water replication, shared platform riding, locked guest maps and Local Play after LAN.
- Stabilization/navigation/replay suites and all seven connection/rejection scenarios.
- **25 existing Local/account/regression suites**, covering roads, railway, water, long levels, themes, campaign, progression, identity, saves and Local celebrations. Old 3/4-rocket assertions were updated to the intentional bounded 36-record cap; an old standalone result fixture was updated for the new fields.
- A real **120-second rendered** winner-result soak, screenshot inspection of lobby/results, effect bounds and cleanup.

Current recovered-build results: **25/25 regression suites passed; 4,331 counted assertions**, plus suites without assertion counts. Competitive peer checks: 52 / 60 / 58 / 56, zero failures and identical rows/awards. Existing four-map peer checks: 122 / 74 / 74 / 74, zero failures. Stabilization/replay: 28 + 24 + 8 + 7 passed. All seven connection scenarios passed. **584 external scene/resource references, zero missing files.** Clean baseline-plus-update editor import and normal main-scene launch completed without errors.

Rendered 120-second measurement (software graphics):

`RENDER duration_ms=120000 frames=2590 median_ms=41.6666666666667 p95_ms=69.152 max_records=24 wave_count=186 nodes=1..1 audio_events=342`

The effect had one child audio node throughout; records stayed below the 36-record hard cap. Cleanup passed. Screenshots were inspected for selected settings, result columns, readable awards and visible large fireworks. The earlier deterministic simulated soak peaked at 26 records/five waves with 193 waves and intervals 0.467–0.800 seconds.

The restored-build rendered soak overlapped automated checks and a clean asset import, so its software frame timings include CPU contention. The earlier finishing run measured 22.855 ms median and 30.556 ms p95 in the same software renderer; neither run is a physical-device benchmark.

The network tests use real processes with controlled host fixtures for selected deaths/pickups/goals, not human playthroughs. Render timings are from Mesa llvmpipe software rendering, not physical Android/Windows GPU measurements. They do not establish 60 FPS on your devices. The unsupported V-Sync warning in this environment is expected.

### Reproduce

Replace GODOT with your executable, from your project directory:

```
GODOT --headless --editor --path . --import --quit
GODOT --headless --path . res://tests/competitive_tests.tscn
GODOT --headless --path . res://tests/competitive_flow_tests.tscn
python tools/run_competitive_tests.py GODOT
python tools/run_lan_tests.py GODOT 4
python tools/run_stabilization_tests.py GODOT
python tools/run_lan_connections.py GODOT
python tools/run_lan_regressions.py GODOT
```

Run network runners separately because they use the same LAN port. Their player-data directories are isolated.

For the rendered preview, open `tests/competitive_visual.tscn` and use **Run Current Scene** in Godot. It uses `user://visual.cfg`, captures lobby/results, holds fireworks for 120 seconds, verifies cleanup and exits. `-- quick` is an optional command-line argument for a short capture.

## Exact Windows checks

1. Merge the update and launch normally. Confirm your account, wallet, selected character, map unlocks and Local best times remain.
2. Host and join with another PC/phone on this version. Select every duration and both modes. Verify immediate guest display, read-only guest settings and no map reload. Change the map once and check normal readiness.
3. Start 1:00 TIME mode. Compare 5→1→GO and timer values on both screens. Move with keyboard. Open the race menu and resume; the shared timer must continue.
4. Complete five crossings before your friend. Confirm no sixth spawn or early fireworks; the friend continues. Finish both and check earlier completion wins in TIME mode.
5. Replay in SCORE mode with different coin/death totals. Verify the formula and that higher score can beat faster completion. Compare table order, values and awards across devices.
6. Leave players unfinished in a 1:00 match. Check the ten-second warning, ticks 5–1, Time Up cue, movement freeze and results after about 1.25 seconds. Hold movement across zero; no late coin/goal/score should count.
7. Test a shield and road/train/water deaths: a shield is not a death and one collision must not count twice. Check power-up coin behavior.
8. Leave winner results open two minutes. Check varied 4–6 rockets, trails/large bursts, readable text and acceptable animation/audio. Nonwinners should not celebrate. Replay/leave repeatedly; no lingering effects.
9. Mute and repeat the final countdown/results. Check no ticks/Time Up/explosion sound. Test Back/Exit confirmations, cancel and accept.
10. Return to Local Play on all four maps. Verify normal elapsed Best Time objective, pause/retry, five destinations, rewards, new-best celebration and persistence after restart.

## Exact Android checks

1. Export/install on all participating phones and one Windows host. Test both shared Wi-Fi and a phone hotspot.
2. In landscape, check all time/mode selectors, map/start/leave buttons, four-player result columns and awards for clipping and reliable touch targets.
3. Repeat timing, expiry and ranking tests using **split-touch and swipe**. Hold a touch at zero; controls must release. Verify no sixth spawn.
4. Use Android Back from lobby/race/results; cancel and confirm. Background/resume a guest; the match should continue, or normal connection-loss handling should appear when appropriate.
5. Check speaker audio and mute, shields/deaths, coin rewards and persistence after relaunch.
6. On your weakest phone, keep winner fireworks open two minutes, then replay/leave repeatedly. Check frame rate, heat, sound frequency and memory stability. Report device model and Android version if performance is poor.
7. Return to Local Play and verify controls, saved progression, pause, Best Time and celebration.

## Limitations

**No physical Android or Windows device tests were performed.** No APK/export-signing/store work was performed. Real hotspot latency, mobile readability, speaker mix and low-end GPU behavior require the manual tests above. LAN remains host-authoritative and local-network-only. No layout, movement physics, hazard timing or progression redesign was introduced.
