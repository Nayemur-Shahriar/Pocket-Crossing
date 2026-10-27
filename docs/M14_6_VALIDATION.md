# M14.6 validation — 7 October 2026

Environment: Godot **4.5.2 stable**, Linux x86-64. Real independent ENet processes on localhost, isolated user-data paths. Rendered checks use X11/Xvfb and the Compatibility renderer. No physical Windows or Android device was available.

## Final results

| Check | Passed | Failed |
| --- | ---: | ---: |
| 24 preserved Local regression suites | 24 suites; 4313 reported assertions/routes | 0 assertions |
| Account, migration, rewards, feed and ranking unit checks | 29 | 0 |
| UDP discovery query/reply and cleanup | 3 | 0 |
| Rendered host + one headless guest, all four maps | 143 | 0 |
| Host + two guests, all four maps, including 180-second soak | 217 | 0 |
| Host + three guests, all four maps | 297 | 0 |
| Seven connection scenarios, 18 processes | 54 | 0 |
| Windows resource pack export + packed startup | pass | 0 |
| Android resource pack export + packed startup | pass | 0 |

Counted assertion/route total: **5056 passed, 0 failed**. This excludes two legacy diagnostic/performance jobs without assertion totals, parser/import scans, byte comparisons, pack checks and duplicate development runs. It counts the final two-peer rendered integration, not the earlier additional two-peer headless run. Host/client final result tables matched exactly in every counted 2/3/4-peer run.

Connection scenarios: duplicate normalized name, incompatible version, fifth-player rejection, client leaving lobby, client leaving an active race, host leaving an active race and mid-race join rejection. Each verifies cleanup. The four-peer test previously exposed an ENet shutdown diagnostic during simultaneous client departures. Disabling unused client-to-client relay fixed it; final four-peer and connection reruns contain no such errors.

## Performance observations

Final three-peer soak held the River Delta race active for **180 one-second samples**, in addition to four complete fixture-driven match cycles. Host nodes ranged from **152 to 158**; the bounded-growth check passed. Maximum compressed snapshot payload was **803 bytes**; guests received **3040 / 3041** snapshots across the run. Final four-peer maximum payload was **751 bytes**, with **338** snapshots per guest.

These are payload lengths before ENet/UDP overhead, not bandwidth or Android FPS measurements. Node counts are a bounded-growth check, not a complete memory-leak proof. One host's stdout was truncated by the execution environment; its explicitly written JSON summary records 103 passing checks, four result tables, zero failures and measured node/payload values. The runner validates the JSON separately from stdout and compares every peer's results.

## What the automated integration actually does

Real ENet connection/handshake, map revisions/readiness, five-second future countdown, pre-GO input lock, authoritative hop RPCs, independent actors, client snapshots, local pause without global pause, swipes surviving render frames, stale/invalid movement rejection, shield/life isolation, respawn, independent pickup and destination ledgers, duplicate destination rejection, two riders on one moving platform, four-map replay, host rank ordering, continued race after first finish, once-only settlement, guest map lock preservation and cleanup followed by Local Play.

Controlled host fixtures invoke damage and coin/goal arrivals to obtain reproducible results. Finish times in screenshots are consequently short test times, not natural race records. This does **not** replace human playthroughs on real LAN devices or verify real Wi-Fi latency, Android background lifecycle, broadcast reception, hotspot routing, APK permissions or touch hardware.

Discovery testing sends the actual query/reply protocol through localhost UDP. It verifies discovery parsing and cleanup, **not** physical Wi-Fi broadcast reachability.

## Parser, references, exports and baseline

All project GDScript imports completed without new parser errors. The static audit found no missing literal scene/resource references. The four map Resources, six theme Resources, original Local controller, SaveData, player controller, input router, camera and section activation match the supplied M14.5 ZIP byte-for-byte. No baseline files were deleted.

Both configured Windows/Android resource packs exported and loaded through Godot. Packed checks loaded all four maps, verified their configuration and normal offline startup, and checked that tests/tools scenes were excluded. These are resource-pack checks, **not** native EXE/APK installation tests.

The final update is applied to a fresh extraction of the user's M14.5 ZIP and imported/started separately. See `overlay_verification.log` for the final import/startup/account check results.

## Existing test diagnostics, separated from regressions

Three old test fixtures print resource-in-use-at-exit diagnostics despite passing assertions. Phase 4 intentionally feeds a corrupt ConfigFile and prints two parse diagnostics. The same behavior was reproduced on the **untouched user-supplied M14.5 baseline**: Phase 4 reports 2 resources, railway 4, water 4; the updated water fixture reports 3. These are retained legacy test teardown diagnostics, not new parser errors or failed gameplay assertions. They have not been silently classified as clean logs. Normal packed startup and final multiplayer runs did not report these diagnostics.

The rendered software display prints a V-Sync support warning. It is a limitation of the test display, not an Android/Windows frame-pacing result.

## Preserved suites

| Suite | Reported passing assertions/routes | Exit code |
| --- | ---: | ---: |
| test_runner | 135 | 0 |
| phase3_tests | 103 | 0 |
| phase4_tests | 62 | 0 |
| section_tests | 68 | 0 |
| railway_tests | 88 | 0 |
| water_tests | 73 | 0 |
| water_route_tests | 3 | 0 |
| long_level_tests | 142 | 0 |
| long_route_tests | 2 | 0 |
| theme_tests | 109 | 0 |
| theme_route_tests | 6 | 0 |
| campaign_route_tests | 75 | 0 |
| campaign_tests | 372 | 0 |
| identity_tests | 994 | 0 |
| balance_tests | 516 | 0 |
| balance_water_routes | 5 | 0 |
| qa_validation | 361 | 0 |
| qa_contacts | 90 | 0 |
| qa_stress | 539 | 0 |
| qa_repro | diagnostic/performance job | 0 |
| qa_perf | diagnostic/performance job | 0 |
| post_m14_tests | 448 | 0 |
| map_campaign_tests | 110 | 0 |
| map_route_tests | 12 | 0 |

## Reproduce

Open/import the project in Godot 4.5.2 first. From the project folder, pass your Godot console executable's path:

```text
python tools/run_lan_regressions.py /path/to/Godot
python tools/run_lan_tests.py /path/to/Godot 2
python tools/run_lan_tests.py /path/to/Godot 3 180
python tools/run_lan_tests.py /path/to/Godot 4
python tools/run_lan_connections.py /path/to/Godot
```

`LAN_TEST_LOGS` can select a fresh output folder. The runners use isolated test save directories. Unit/discovery scenes may also be run as individual scenes; they use isolated test save names. Do not run the test harness against your normal personal save directory.

For native Windows/Android and exact hotspot steps, follow the 14-step checklist in **M14_6_REPORT.md**. Physical Android performance and cross-platform LAN acceptance remain outstanding. M15 has not started.
