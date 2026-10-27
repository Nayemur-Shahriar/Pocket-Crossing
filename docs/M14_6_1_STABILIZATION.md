# Pocket Crossing M14.6.1 — completion and test report

This update continues the saved M14.6.1 work over M14.6. No M15 work or new maps, hazards, progression systems or gameplay modes were added. Physical Windows/Android acceptance remains a manual step.

## What existed before continuation

The saved checkpoint already contained own-client prediction, hidden host authority actors, private owner corrections, sparse hazard replication, the explicit map picker and central navigation. It also contained passing 28-check navigation and three-peer integration results plus before/after profiles. These systems were inspected and preserved, not rebuilt.

The final continuation recovered and completed the navigation edge fixes, real pointer/Escape validation, prediction queue/boundary validation, same-map replay/leave validation, Local regressions, four-player soak, rendered menu checks, packed-resource checks and update packaging. Temporary storage resets required restoration from the saved checkpoint; the implementation was not restarted.

## Exact causes and behavior

| Issue | Original cause | Fix |
|---|---|---|
| Remote characters on each screen | Every device instantiated all racers and received their transforms. | Guests instantiate only their own actor. Host keeps remote physics actors under an invisible parent. |
| Client movement delay | Input waited for the host, a full-world snapshot and interpolation. | Own-client hops begin immediately; host validates and acknowledges; corrections occur at hop boundaries. |
| Excess world traffic | Full hazards and player transforms were serialized repeatedly. | Logical standings/private owner corrections plus timed hazard events and sparse repair anchors. |
| Back/Exit | Existing input only toggled pause, with no menu hierarchy or Exit button. | Central Back/Escape owner, explicit Exit/leave confirmations and cleanup before quitting. |
| Change Map seemed broken | Silent cycling returned to the same map when only one was unlocked. | A four-map picker shows unlocked/locked choices, updates the guest and invalidates readiness. Pointer hit testing passed. |

Final navigation fixes: pending connection has its own page state; Resume restores the race page; Back from manual IP entry returns to discovery, matching its visible button; host lobby-close confirmation explains that everyone disconnects.

## Architecture

- `LanRace`: host authority and independent racers. The local character is the existing world player. Remote host actors have an invisible parent but remain simulation bodies. Their own `visible` flag remains available to the existing collision rules. Guests have no remote player nodes. Existing scoring, lives, shields, destinations and result ordering are reused.
- `LanPrediction`: only the owning guest predicts the existing hop. One buffered direction; at most eight unacknowledged inputs. Host sequence acknowledgements drain the queue. Lifecycle generations clear stale commands on death, destination and respawn. Corrections occur at hop boundaries; water correction references the local platform/deck offset. The host owns damage and rewards.
- `LanReplica`: logical standings for every racer; a private physical correction only for the recipient. No remote player position/hop/animation fields. Other racers remain represented by names, ranks and event messages.
- `LanHazards`: reliable spawn/removal, major road-speed changes, train-state changes and platform-wrap events, with default 2 Hz repair anchors. Roads/trains extrapolate timed motion; boats integrate the existing lane speed variation and expose carry deltas. Small road acceleration variations use sparse anchors rather than generating event spam. The host remains the sole spawn/collision authority. Extrapolation is bounded during a long network stall.
- `ModeNavigation`: one owner for system Back/Escape, modal cancellation and shutdown. Local Back pauses/resumes. Race Back confirms leave; the race keeps running behind menus. Host leave warns that the match ends for everyone. Shutdown closes transport/discovery, clears race state, stops world effects, saves the active profile and quits. Guests receive the existing disconnection notification.
- `ModeHUD`: explicit four-map host picker with locked choices disabled, plus Exit and confirmation UI. Map selection reuses session readiness reset and synchronized countdown; guests may join a map owned by the host.

No MultiplayerSynchronizer/MultiplayerSpawner or duplicate damage/save system was added. Existing map/layout/theme resources, player physics, touch/swipe input, road/train/water components and account/save schema are unchanged. No save migration is needed. The network content revision is `m14.6.1-prediction-1`; update every participating device together.

## Before/after measurements

Godot 4.5.2 Linux, two real ENet processes on localhost, 60 FPS cap, approximately seven seconds per map. These are short diagnostic samples, not mobile performance guarantees. RTT was around 15–16 ms. Input latency measures request to first position change sampled on process frames, not physical input-to-display latency.

| Map | Input start before → after | Compressed gameplay payload bytes/sec before → after | Reduction |
|---|---:|---:|---:|
| Village Crossing | 49.70 → 16.29 ms | 10,021 → 1,873 | 81.3% |
| City Rush | 49.72 → 16.28 ms | 10,422 → 1,995 | 80.9% |
| River Delta | 49.59 → 16.27 ms | 9,720 → 1,723 | 82.3% |
| Night Express | 49.76 → 16.35 ms | 8,577 → 1,810 | 78.9% |

Baseline: approximately 15 full state RPCs/sec in the observed cadence, with two player transform records per message. After: 14 owner/standings messages and 26–36 hazard messages across each seven-second sample, with zero remote transforms. Active hopping/boat riding can raise owner updates to the 10 Hz cap; repair anchors default to 2 Hz. Client actor count fell from two to one. Client movement continued during a deliberate 200 ms incoming-poll suspension on all maps; baseline movement did not.

Both builds ran near the imposed 60 FPS limit. Client mean physics cost increased from 0.23–0.57 ms to 0.59–0.80 ms because it now simulates prediction and smooth hazards. Process cost ranged 0.91–1.42 ms before and 0.79–1.24 ms after. These noisy samples do not establish a CPU improvement.

Bytes count compressed gameplay payloads received by one client, excluding ENet/IP/RPC overhead, discovery, ping and lobby/event traffic. This is not packet-capture bandwidth. Reliable transport queue depth, packet loss, real Wi-Fi jitter and physical mobile FPS were not measured. Raw before/after metrics are included under `docs/m1461_validation`.

## Validation

- Godot import/parser checks and Windows/Android preset PCK generation. Both packed-resource audits load the four maps and normal main menu; developer scenes are excluded. Native EXE/APK installation was not tested.
- Existing 25 Local/account suites, including M6–M9, themes, identity, balance, routes and saves. Final results are included. The old phase4 corrupt-save fixture intentionally logs ConfigFile parse diagnostics; short-lived phase4/rail/water tests also print audio-resource teardown warnings. Their assertions pass; this is not described as a completely clean legacy log.
- Saved three-peer test: 110 + 69 + 69 passed, identical final results across four maps.
- Four real ENet peers, all four maps, plus a 120-second river soak: final per-peer counts, node range and identical-result flag are included in the JSON report. The tests cover logical-only standings, own-only rendering, host hidden simulation bodies, movement, independent lives/rewards/goals, shield, shared host boat carrying, result ordering and Local Play after LAN.
- Navigation state suite: 28 checks, including simulated Android Back notification and duplicate-event suppression.
- Extra suite: 24 checks covering real viewport pointer hits, four map buttons, Escape hierarchy/modal behavior, local pause/resume, immediate prediction, bounded queues, acknowledgements, correction boundaries and death/respawn reset. The suite runs headless and in rendered X11 Compatibility mode; final Exit is clicked through the UI.
- Two real ENet peers: same-map replay, fresh match epoch, cleanup and confirmed host leave/guest notification (8 host + 7 guest checks).
- Seven connection scenarios across 18 processes: duplicate/version/full-lobby rejection, lobby/match/host disconnect and mid-match join rejection.
- Fresh M14.6 project plus this update: import and stabilization smoke checks are included in the verification log.

Early restored-folder tests started before asset import finished and were discarded. Final runs use the completed import cache. No production code was changed to suppress those transient missing-import errors.

Reproduce (replace GODOT with your Godot 4.5.2 executable):

```
python tools/run_stabilization_tests.py GODOT
python tools/run_lan_tests.py GODOT 4 120
python tools/run_lan_connections.py GODOT
python tools/run_lan_regressions.py GODOT
```

The new stabilization runner isolates Linux and Windows user-data environment paths. Older runners were executed under isolated Linux paths here; use a project/profile backup before developer tests on your computer.

## Windows manual acceptance checklist

1. Back up the project, copy the update, import in Godot 4.5.2 and run the main scene. Verify the normal account, wallet, skins, unlocked maps and Local records remain.
2. Escape: Settings → home; Characters → Map Select → home; manual IP → discovery → Friends → home. Cancel a pending connection using Escape. Each press must cause one transition.
3. Click Exit, Cancel, then Exit again and confirm. Relaunch and check saves. Close the window using X while hosting; the guest should return to Friends Play.
4. Connect two devices on the same Wi-Fi. Host Select Map shows all four maps; locked ones cannot be selected. Try every unlocked choice; guest map/readiness must update. A guest need not own the host's map. Countdown/GO must stay synchronized.
5. Move simultaneously on all maps. Each screen should show only its own character, while names/ranks/events still update. Test rapid key changes, held keys, death/respawn and temporary Wi-Fi disruption. No stale buffered movement should occur after respawn.
6. Test road and train contact, warning visibility, shield, water entry, riding and leaving platforms. Check guest platform motion and collision timing on the actual network. Lives, pickups and destinations must remain independent.
7. During a race, Escape must confirm leave; Cancel returns to play. The host warning must be clear. Guest leave must not stop others; host leave must clear every guest session. Start Local Play afterward and test keyboard/pause/retry.
8. Finish and compare results, Play Again, then Lobby / Change Map. Check there are no old actors/hazards/commands; rewards occur once and Local Best Times stay separate.
9. Repeat with four devices for 10–15 minutes over actual Wi-Fi/hotspot. Include water backtracking, train crossings, disconnections and rejoining a new lobby. Record freezes, correction jumps and errors.

## Android manual acceptance checklist

1. Install the updated build without clearing app data; use landscape. Verify account/progression preservation on all phones.
2. Repeat the navigation paths with system/gesture Back. Check text-entry keyboard dismissal and button hit areas at the phone's aspect ratio. One Back action must not trigger two transitions.
3. Test split-touch and swipe in both modes, including gesture release over Pause, rapid input, background/foreground and respawn. Guest hops should begin promptly.
4. Test Android host + Windows guest, Windows host + Android guest, and phone hotspot. Repeat map selection, countdown, replay, change-map and confirmed leave.
5. Play River Delta and Night Express for at least ten minutes. Observe FPS, heat, weather cost, platform riding, hazard timing, warning readability and network correction jumps. Record phone model and Android version.
6. Finish, quit, relaunch and verify saves. Closing the host must remove the session and stale lobby advertisement.

## Limits

Linux software rendering and automated ENet processes were available; physical Windows/Android devices were not. Real-network smoothness, native Back/gesture behavior, touch acceptance, packaged native builds and long mobile performance remain manual. Host corrections can still occur under delay/loss. Sparse road anchors approximate gradual speed changes between updates. Existing LAN finite-map simulation is preserved; Local section streaming is unchanged. No host migration, reconnect-in-place or new multiplayer features were added.

The exact created/modified file list is in `M14_6_1_FILES.txt` beside this report.
