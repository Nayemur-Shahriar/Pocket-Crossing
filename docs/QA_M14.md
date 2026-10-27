# Pocket Crossing — M14 QA candidate

## 1. Overall status and scope

**Local QA and fixes complete. Final release classification: NOT READY FOR M15 until native build/device qualification is completed.**

This is a provisional release-candidate update over the completed M13 project. No new feature, level, vehicle, character, weather, economy or difficulty change was introduced. M15 has not started. There are no known unresolved blocker/high gameplay-code defects after the fixes below. The remaining release gates are actual Windows/Android builds and native/device acceptance; the available Linux environment cannot certify those.

M13 is preserved at the original working copy. Work took place in a separate `PocketCrossing_M14_RELEASE_CANDIDATE` copy. All **200 asset, scene and Resource files** from M13 are byte-for-byte preserved. `project.godot`, `export_presets.cfg`, keyboard mappings, Android package/signing settings, prices, score/star rules, campaign IDs and save schema are unchanged. No save reset or migration is required.

Evidence labels used in this report:
- **AUTOMATED TESTED:** actual Godot execution driven by scripts, including physics/input events where explicitly stated.
- **STATICALLY VERIFIED:** code, configuration, reference and byte-comparison inspection.
- **VISUALLY REVIEWED:** generated Linux screenshots inspected, not hands-on playtesting.
- **NOT TESTED / REQUIRES DEVICE:** native Windows interaction and physical Android behavior/performance/audio.

## 2–3. Files created and modified

Exactly five existing production scripts changed:

| File | Why |
| --- | --- |
| `scripts/core/save_data.gd` | Recover empty/unrecognized primary profiles from an existing good backup; avoid replacing that backup with an empty file; retain access to a level whose own completion survives an incomplete profile. |
| `scripts/data/level_config.gd` | Reject invalid movement, origin, life, ramp and reward/rating numeric values before runtime. Inspector ranges alone did not validate hand-edited Resources. |
| `scripts/world/section_activation.gd` | Notify an already-initialized railway when it returns from inactive to active. |
| `scripts/world/railway_section.gd` | Reuse and park a frozen busy train, then give a full fresh warning on streaming reentry. Preserve SAFE track clocks. |
| `scripts/world/traffic_lane.gd` | Calculate the shared following-gap value once per speed-update call, retaining the same values and ordering. |

Created: focused `qa_validation`, `qa_contacts`, `qa_stress`, `qa_repro`, and `qa_perf` test scripts/scenes; `tools/capture_qa.gd/.tscn`; their Godot UID files; this report, requirement coverage, file manifest, screenshots and validation logs. README adds installation and QA instructions. No existing regression test expectations were changed. The exact final per-file list is `docs/M14_FILES.txt`.

## 4–6. Bugs, priorities, fixes, and unresolved items

| ID | Priority | Reproduction in pre-fix code | Resolution |
| --- | --- | --- | --- |
| QA-01 | HIGH | Put a railway into PASSING, move beyond its activation window, return: frozen passing train reappears without a fresh warning. | On actual streaming reentry, park existing busy train and restart its full configured warning. A nearly expired warning also restarts. No train/timer added. Normal pause/resume and uninterrupted railway timings are unchanged. |
| QA-02 | HIGH | Write valid profiles so `.bak` exists; truncate primary to zero bytes; load: ConfigFile reports OK, game loads defaults despite valid backup. | Recognize established profile keys; empty/unrelated files use backup; such files cannot overwrite the last-good backup. Typed malformed fields still follow existing sanitization/defaults. |
| QA-03 | MEDIUM | Keep completion for Level 6 but omit Level 5 in a partial recovered profile: Level 6 displays completed yet is locked. | Own completion also grants access. It does not unlock arbitrary later levels. |
| QA-04 | MEDIUM | Set road-only LevelConfig `hop_seconds = 0`: validation accepts a value that cannot produce valid hop interpolation. Related nonfinite fields are also unchecked. | Validate finite positive hop/ramp/scales, finite origin, supported life count, nonnegative movement/reset/score values and valid star thresholds. All shipping configs remain unchanged and valid. |
| QA-05 | LOW, deferred | Project/export descriptions still refer to four lanes / Level 1; version remains 0.1.0. | Non-gameplay packaging metadata, deferred to M15 so this update does not replace local project/signing settings. No publishing work performed. |

No observed crashes, duplicated managers, normal-flow save corruption, or unbounded particle/train/platform growth remain in tested scenarios. The backup remains a last-good previous-save backup, not a history/database; a valid but manually altered profile may intentionally sanitize to defaults. Physical storage failure cannot be eliminated by code; failed-purchase rollback and user-facing save-failure reporting are tested.

**Unresolved qualification gates (not invented gameplay bugs):** Windows native export template unavailable; Android templates/SDK/JDK paths unavailable; no Windows runtime or physical Android device attached. EXE/APK attempts failed for those environmental prerequisites. Export viability is proven only at the resource-pack level here. Complete sections 21–23 and 29 before declaring the candidate release-ready.

## 7–8. Parser, runtime and automated results

Final clean import and normal-flow tests reported no parser/runtime errors. All 457 external scene/Resource references resolve. Deliberately corrupt ConfigFile fixtures print expected parser diagnostics; deliberately unwritable fixture paths print expected save warnings. They are logged as negative tests, not hidden. Accelerated railway/water tests emitted audio-resource shutdown warnings; rerunning both at normal wall-clock speed completed cleanly with the same 88/73 assertions. This was not reproduced during normal gameplay or the wall-clock soak. See their separate realtime logs. The software-rendering driver also prints a harmless unsupported V-Sync warning; no warning was suppressed.

**Assertions executed: 10456; passed: 10456; failed: 0.** Counts include repeated stress assertions, not unique test cases. Identity tests count actual randomly seeded spawned actors, so their total can vary between runs. Two packed-startup audits and reference checks are additional pass/fail validations, not added to this assertion total.

| Suite | Passed | Failed | Timing |
| --- | ---: | ---: | --- |
| test_runner | 135 | 0 | fixed 60 Hz / accelerated |
| phase3_tests | 103 | 0 | fixed 60 Hz / accelerated |
| phase4_tests | 62 | 0 | fixed 60 Hz / accelerated |
| section_tests | 68 | 0 | fixed 60 Hz / accelerated |
| railway_tests | 88 | 0 | fixed 60 Hz / accelerated |
| water_tests | 73 | 0 | fixed 60 Hz / accelerated |
| water_route_tests | 3 | 0 | fixed 60 Hz / accelerated |
| long_level_tests | 142 | 0 | fixed 60 Hz / accelerated |
| long_route_tests | 2 | 0 | fixed 60 Hz / accelerated |
| theme_tests | 109 | 0 | fixed 60 Hz / accelerated |
| theme_route_tests | 6 | 0 | fixed 60 Hz / accelerated |
| campaign_route_tests | 75 | 0 | fixed 60 Hz / accelerated |
| campaign_tests | 372 | 0 | fixed 60 Hz / accelerated |
| identity_tests | 986 | 0 | fixed 60 Hz / accelerated |
| balance_tests | 516 | 0 | fixed 60 Hz / accelerated |
| balance_water_routes | 5 | 0 | fixed 60 Hz / accelerated |
| qa_validation | 353 | 0 | normal clock |
| qa_contacts | 90 | 0 | fixed 60 Hz / accelerated |
| capture_qa | 63 | 0 | rendered wall clock |
| capture_qa --ui-only | 66 | 0 | rendered wall clock |
| qa_stress --soak-seconds=1200 | 6600 | 0 | wall clock |
| qa_stress final code | 539 | 0 | normal clock |

The existing tests retain their original purpose: core keyboard/touch/swipe/physics; Phase 3/4 persistence and progression; M6 compiler; M7 rail; M8 water; M9 camera/streaming; M10 theme; M11 campaign; M12 identity; M13 balance/routes. Direct callback fixtures test state transitions and are not presented as proof of human playability. Route suites separately use real physics and ordinary movement without immunity/hazard edits.

## 9. All 15 campaign Resources

Every entry has a unique stable ID, correct number/name, valid Start/Destination, valid theme/environment, time/spawn/goals, safe pickup placement, and valid ordered progression. Each compiles and loads. Road/rail/water counts exclude Start/Safe/Destination.

| Level | Name | Road/Rail/Water | Hazards | Rows | Time (s) | Validation |
| --- | --- | --- | ---: | ---: | ---: | --- |
| 1 | Easy Road | 5/0/0 | 5 | 8 | 85 | PASS |
| 2 | City Run | 6/0/0 | 6 | 10 | 95 | PASS |
| 3 | Sunset Rush | 7/0/0 | 7 | 11 | 105 | PASS |
| 4 | Night Ride | 8/0/0 | 8 | 12 | 115 | PASS |
| 5 | Train Time | 7/1/0 | 8 | 13 | 125 | PASS |
| 6 | Double Track | 7/2/0 | 9 | 14 | 135 | PASS |
| 7 | River Hop | 7/0/2 | 9 | 14 | 145 | PASS |
| 8 | Rain Run | 9/1/0 | 10 | 15 | 145 | PASS |
| 9 | River Rush | 6/0/5 | 11 | 17 | 155 | PASS |
| 10 | Snow Way | 9/3/0 | 12 | 18 | 155 | PASS |
| 11 | Fog Track | 10/4/0 | 14 | 20 | 165 | PASS |
| 12 | Wild River | 9/1/5 | 15 | 22 | 175 | PASS |
| 13 | Midnight Run | 11/3/3 | 17 | 25 | 185 | PASS |
| 14 | Danger Zone | 10/5/3 | 18 | 26 | 195 | PASS |
| 15 | Final Crossing | 12/3/5 | 20 | 29 | 205 | PASS |

All 45 real-physics campaign route runs completed: 15 levels × seeds 42, 2026, 711, with respective initial waits 0, 4 and 9 seconds. Every level has a three-star route and a power-free route in this sample. This finite sample is evidence of playability, not a proof for every random sequence or human skill level. The final result panel has no Level 16 target; the catalog rejects indices -1 and 15.

## 10. Save/progression

AUTOMATED TESTED: missing save defaults; every sequential completion/unlock with reload; per-ID best scores/stars; worse replay retaining best; arbitrary future IDs; coins; all selected/owned skins; settings; fifty repeated owned-skin selections with no recharging; M13 v2 schema fixture; sparse completion recovery; empty/unrelated primary backup recovery; malformed scalar/map values including nonfinite values; failed-purchase rollback. Existing Phase 4 tests also cover truncated syntax with/without backup. No new save fields were introduced.

All tests use named QA/preview profiles and isolated test application-data directories. The normal `user://profile.cfg` is not packaged, modified, migrated or deleted. Actual user's private phone/PC save was not available; compatibility is tested against v2 and older fixtures, not claimed as a read of that private data.

## 11. Road and vehicle collision

AUTOMATED TESTED: all nine M12 vehicle types, both directions; type-specific one-second displacement; Slow Traffic ratio/restoration; mixed-speed safe following; spawn rejection; streaming freeze/resume; collision geometry matches Resources. M14 adds actual Area2D contacts for every vehicle type in each direction: a body just outside the combined hitbox stays safe; overlap consumes exactly one life; repeated overlap during respawn cannot cause extra death. Ninety contact/skin/input assertions pass. Cosmetic bodies remain larger than collision footprints intentionally. No spawn speed/interval/gap Resource changed.

## 12. Railway

AUTOMATED TESTED: one/two/three tracks, both directions, WARNING→PASSING→SAFE, batch quiet window, full warning, collision/shield, pause, reset and streaming. M14 specifically reproduces passing-train and expiring-warning reentry. Only reentry after actual inactivity refreshes a busy warning. SAFE track timers survive, and ordinary pause/resume does not reset warning/position. One train node per track remains reused; no new Timer nodes or train pooling redesign.

## 13. Water and support accuracy

AUTOMATED TESTED: both directions, authored 128–224 px M13 platforms, exact `length/2 - 18` support boundary, carrying, hopping off, transfer/landing, edge exit/drowning, shield rescue, respawn, pause/reset and retained pools. Five real forward/backtrack/recross routes on Levels 7/9/12/13/15 passed with three lives. Visual deck sizes and movement rules are byte-identical to M13. VISUALLY REVIEWED: small/large boats and their readable deck edges in six themes. Hands-on phone transfer precision remains a manual acceptance check.

## 14. Camera, streaming and backtracking

AUTOMATED TESTED: short fixed levels, long campaign routes and 1,024-row authoring fixture; deterministic rows/world positions; horizontal stability; start/destination clamps; forward dead zone/backtracking; reset on death/retry; retained road/rail/water components; collected pickups staying collected; no duplicated decorations/weather/spawners. Soak repeatedly relocates through forward/backward activation windows to stress lifetime management; ordinary movement route tests provide separate end-to-end crossing evidence.

## 15. Themes/weather and Bangladesh identity

AUTOMATED TESTED: all six presets, missing/invalid theme/environment fallback, owner reuse, activation, retry/next/menu cleanup, weather pause. M12 checks all five environment profiles, train modules, five boat designs, nine vehicle designs, optional ambience and decorative clearance. STATICALLY VERIFIED: all original art/theme/environment Resources unchanged; all SVG/audio references resolve. VISUALLY REVIEWED: Day/Evening/Night/Rain/Snow/Fog screenshot grid. Weather remains a capped camera-local pool, not one instance per section. No design/readability change was made.

## 16. Characters and power-ups

AUTOMATED TESTED: all four skin selections, free/locked/insufficient funds/purchase/ownership persistence; repeated texture switching preserves the same player instance and collision shape. Shield consumes once with existing grace, including water rescue. Slow Traffic and Double Rewards retain their existing duration/refresh/pause/expiry and Retry/Next cleanup. Prices 20/40, two free skins and all effect Resources remain unchanged. No pay-to-win changes.

## 17–18. Score, stars, coins, results and failure

AUTOMATED TESTED: score reset; no repeated forward-point farming; coin pickup once per run and immediate persistence; existing death/Retry banking; multipliers; one destination bonus; 1/2/3 star boundaries; per-level best retention. Successful cards show correct score/best/stars/coins, Replay/Select/Next, and final-campaign message. Failed runs retain existing best-score behavior but do not unlock, award completion stars, show Next, or celebrate. Modal input is blocked. Genuine new successful record uses pre-save best comparison after target bonus. Worse/equal replay does not celebrate.

## 19. Continuous fireworks

AUTOMATED TESTED with actual rendered Linux wall time, Dummy audio output (trigger/state verified, not audible listening):

```
FIREWORK_SAMPLE seconds=30.014 nodes=157 memory=45750713 bursts=32 sounds=32 active=1
FIREWORK_SAMPLE seconds=60.158 nodes=157 memory=45735877 bursts=60 sounds=60 active=0
FIREWORK_SAMPLE seconds=90.741 nodes=157 memory=45738889 bursts=90 sounds=90 active=1
FIREWORK_SAMPLE seconds=120.78 nodes=157 memory=45738889 bursts=120 sounds=120 active=1
FIREWORK_WALL seconds=120.864 frames=3251 max_bursts=2 nodes=157
```

At most two live burst records, one reusable audio voice, no accumulating particle nodes. Result text/buttons remain readable in reviewed screenshots. Replay cleanup was rendered; Replay/Next/Select/hide immediate cleanup is also asserted in M13 and M14 stress tests. Repeated record screens use one celebration controller. The requested two-minute native Windows/phone listening and interaction test remains open.

## 20. Retry/death and long-session stress

Ten consecutive longest mixed-level retries explicitly verify one player/HUD/camera/weather/presentation/activation owner, configured spawner count, one pooled train per track, fixed boat pool count, reset score/lives/timer/camera, and cleared support/powers. Repeated contact bursts across road/rail/water callback paths lose one life and respawn once; separate suites verify real physics contacts.

Long wall-clock lifecycle run:

```
QA STRESS RESULTS: 6600 passed, 0 failed; cycles=368; wall_seconds=1201.58
```

Comparable sampled menu node counts: 256–280; orphan nodes: 0–0; static allocator memory first/last: 46,514,982 / 47,538,170 bytes. Moving road populations can differ between samples; manager/pool counts are asserted separately. Memory readings are allocator snapshots, not an Android RSS guarantee.

The long soak started after railway/validation/unlock fixes; the final empty-profile recovery and equivalent traffic-loop optimization were subsequently covered by final-code save/regression/stress runs. Long-soak claims concern valid-profile navigation and lifecycle retention, not corruption injection. No claim is made that a human played continuously for twenty minutes.

## 21. Windows QA and performance

NOT TESTED on native Windows: this environment is Linux. VISUALLY REVIEWED / AUTOMATED RENDERED: 1280×720, 1366×768, 1600×900, 1920×1080, 1920×864 and 800×360. Level Select, Character Select, pause, failure, result and split-control bounds were captured/checked. Pause captures wait for the existing fade before inspection. No UI redesign was necessary. Window aspect changes retain the logical landscape framing; device cutouts still require actual phone checks.

Software-rendered Linux samples (two-second capture windows after warmup; not Windows/Android FPS claims):

```
RENDER_PROFILE level=1 frames=94 p50_ms=20.033 p95_ms=31.489 max_draw_calls=134.0 nodes=108 active_sections=10 total_entries=10
RENDER_PROFILE level=5 frames=82 p50_ms=22.508 p95_ms=38.323 max_draw_calls=174.0 nodes=133 active_sections=16 total_entries=16
RENDER_PROFILE level=7 frames=74 p50_ms=24.724 p95_ms=39.658 max_draw_calls=208.0 nodes=150 active_sections=18 total_entries=18
RENDER_PROFILE level=10 frames=60 p50_ms=31.832 p95_ms=49.219 max_draw_calls=581.0 nodes=177 active_sections=22 total_entries=22
RENDER_PROFILE level=12 frames=68 p50_ms=27.6 p95_ms=46.039 max_draw_calls=307.0 nodes=210 active_sections=24 total_entries=28
RENDER_PROFILE level=15 frames=73 p50_ms=25.467 p95_ms=40.3 max_draw_calls=341.0 nodes=247 active_sections=22 total_entries=34
```

Frame pacing on software-rendered CI hardware is not representative of a mobile GPU. No visual quality was reduced based on these numbers. Use the device checklist below to assess actual heat, latency, stutter and sustained pacing.

## 22–23. Android checks actually done / still required

Done: STATIC inspection of production input mapping and landscape/canvas layout; automated native Godot touch/swipe event dispatch, simultaneous fingers, cancellation, UI priority, held-repeat, release-outside-control and simulated safe-area bounds; app-pause/back notification callbacks; Android resource pack export and packed startup. Same compatibility renderer and native project/export settings preserved.

Not done: APK creation/installation in a configured Android toolchain; update signing/install preservation; real touchscreen/IME/system interruptions; physical notch/nav-bar handling; audible mixing; mobile GPU/frame/thermal/memory behavior. No physical Android device was available. No Android-device testing is claimed.

## 24. Measured optimization and preservation

Only one small hot-loop optimization: `TrafficLane.update_vehicle_speeds()` calculated `required_gap()` separately for each follower, repeatedly scanning type settings. Compute it once per update when followers exist, retaining local runtime edits and the same gap formula. No cross-frame cache, stale config, ordering or speed change.

Benchmark: all twelve final-level road lanes, 10,000 speed updates, seven samples on this Linux host. Median before **1,477,191 µs**, after **1,137,827 µs** (~23% less time for this specific workload; about 0.148→0.114 ms per twelve-lane update). This is not a 23% whole-game FPS claim. The benchmark and identical safe-gap/type-speed regressions are included. No major optimization/rewrite or art downgrade was justified.

## 25. Memory/lifecycle findings

Existing section activation freezes distant simulation and collision participation; pooled boats and one train per track remain retained. Decorations use bounded visible-row draw lists. Weather is one fixed camera-sized pool. Fireworks use one voice and bounded burst records. Existing delayed UI focus guards handle freed controls. No production `await` timers/deferred ownership leak was reproduced. Native global audio has four reusable voices; optional ambience uses one voice; train warnings remain visual and do not require sound. Pause/modal transitions clear held input.

Short collision/destination effects allocate only for brief feedback; retained world nodes are intentional, not orphan leaks. There was no evidence requiring broad architecture replacement or object-pool rewrites.

## 26. Export safety

Production entry: `res://scenes/main.tscn`, opening normal Level Select. Developer/test scenes are excluded by both export presets. Both Windows and Android resource packs exported, loaded all fifteen Resources, opened the normal menu and excluded test/preview scenes in a packed runtime audit. Production code has no machine-specific absolute path dependency. No normal save is bundled.

Native Windows EXE export was attempted and blocked by missing matching 4.5.2 templates. Android development export was attempted and blocked by missing templates and configured Java/Android SDK paths (adb/build-tools/apksigner). These are reproducible environment limitations, not successful native exports. No EXE/APK is supplied or claimed. Existing package ID, version, signing configuration and permissions are untouched. No Play Store work was started.

## 27. Security/privacy and assets

STATICALLY VERIFIED: no credential-pattern findings or production machine-path findings in audited project scripts/configs; report does not expose secret values. This is a source audit, not a penetration-test guarantee. No analytics/network SDK/cloud service added. Existing Android internet permission remains false; vibration permission remains unchanged. Audio is six existing original synthesized WAVs; no new copyrighted content. WAV peaks are below clipping; audible balance still needs listening on speakers/headphones. Texture assets are small existing SVGs; no oversized replacement textures introduced. Gameplay-critical UI uses the existing font pipeline; no new Bengali font dependency introduced.

## 28. Known limitations

- Native build and device qualification remain unverified; see readiness decision below.
- Authored finite campaign, fixed horizontal landscape board and existing 4,096-row/256-column authoring safety guard remain; no dynamic-world redesign.
- Test route seeds cover samples, not every possible random arrival or player strategy.
- Existing saves cannot recover information absent from both primary and backup.
- Marketing descriptions/version metadata remain historical until the separately authorized release milestone.
- Screenshot review is not hands-on Windows/phone usability testing.

## 29. Exact manual acceptance checklists

### Windows

1. Close Godot. Back up your complete M13 folder and normal save. Copy that project to `PocketCrossing_M14_RELEASE_CANDIDATE`. Extract the update into the folder containing `project.godot`, merging/replacing supplied files. Keep your existing export/signing settings. Open using the same compatible Godot 4.5.x installation, allow import, then use the toolbar **Run Project** button.
2. Confirm normal Level Select, fifteen entries and your saved coins/stars/bests/owned character. New player should only access Level 1. Do not delete your main save for testing: use a separate QA OS account/profile or the isolated preview.
3. Open `tools/campaign_preview.tscn`; set root **Starting Level** to 1, 3, 5, 7, 9, 11, 12, 14 and 15 in turn. Use toolbar **Run Current Scene** (no F6 required). Preview progress is separate from the normal profile.
4. On each: cross road gaps, observe differing vehicle speeds, collect a coin, pause/resume, die, respawn, Retry and finish. Use arrows/WASD, hold/release, rapid alternation, mouse/split buttons and swipe. Confirm one-cell hops and no movement behind modals.
5. Railway: wait off tracks through SAFE→WARNING→PASSING→SAFE in both directions. Pause during warning and passing. Move far away and back: a formerly busy reactivated track must give a fresh full warning before its next train. Test shield then a later unshielded contact.
6. Water: land on small/medium/large decks, ride, hop sideways/forward/back, transfer, and step to land. Try a visible gap and being carried beyond the allowed bank. Confirm one life loss or existing shield rescue, never floating on invisible support. Backtrack across Levels 7/9/12/13/15.
7. Level 15: perform ten consecutive Retry operations, then several road/train/water deaths. Check timer/lives/score reset, no doubled hazards/weather, camera returns to Start. Finish and confirm no Next/Level 16 button.
8. Use `tools/theme_preview.tscn` / its theme picker for all six presets. Advance and backtrack during rain/snow/fog. Check night/fog visibility, readable warning lamps/platform edges, weather freezing on pause, and no weather over menus.
9. Test free character selection; insufficient funds; purchase with earned coins; select each owned skin. Close/reopen and verify ownership/selection/wallet/bests/stars. Compare values before/after. Do not use a preview wallet as evidence of normal campaign persistence.
10. Collect Shield/Slow/Double. Pause during each, resume to expiry; Retry and Next must clear effects. Verify coins are awarded once, replay does not lower stars/best, and death cannot farm forward points.
11. Earn a genuinely new successful best. Leave the result open **two minutes**: watch continuous readable bursts, listen for one short cue per burst, then test Play Again. Repeat with Level Select and Next Level. No continuing blast/audio afterward. Also test failure and an equal/worse successful score: no celebration.
12. Resize to 1280×720, 1366×768, 1600×900 and 1920×1080. Inspect HUD, pause, scrolling Level Select, all character rows and both result panels; keyboard focus must remain usable. Alt-Tab/minimize while moving and resume deliberately.
13. In Godot with matching export templates installed, export a normal Windows build using the existing preset. Run it outside the editor and repeat startup, one road/rail/water crossing, save/relaunch and result navigation. Record any Output/Debugger errors and exact reproduction.

### Physical Android

Record phone model, Android version, RAM, screen resolution/refresh rate, Godot/build version and whether this is a fresh install or an update. Use the same signing identity/package for an update; back up valuable progress before install testing. Do not uninstall your only progress-bearing install to simulate a clean install—use a spare device/test profile.

- [ ] Build/install a development APK using the existing Android preset and your configured SDK/JDK/templates. Test a clean test-profile launch and an update over M13 separately. Confirm landscape, normal Level Select and retained wallet/bests/stars/unlocks/selected skin after update.
- [ ] Run Levels **1, 5, 7, 10, 12, 15**. If locked in the normal profile, test via an isolated development preview build; do not ship the preview as production startup. Repeat release-startup check afterward.
- [ ] Left thumb Up/Down and right thumb Left/Right: tap, hold, alternate rapidly, use two fingers, release one outside its button, then both. No stuck hold or extra diagonal/double hop.
- [ ] Swipe all four ways: short motion ignored, long swipe one hop, quick repeated swipes, releases over UI. Menu/result touches must never move the player behind the screen.
- [ ] Check small-platform land→ride→transfer→land and backtracking; run off a deck/bank; test road/train contact and shield rescue. Exactly one life loss per incident and one respawn; camera returns correctly.
- [ ] Pause during train warning, train passing, boat ride, rain, snow and each power-up. Wait, resume, verify no jumping hazards, expired instant warning or permanent slowdown/multiplier.
- [ ] On Level 15 press Retry **ten times**, then play forward/backward through road/rail/water. No multiplied trains/boats/spawners/particles, collected coins do not reappear from streaming, no frozen controls.
- [ ] Check every theme, especially Night/Fog readable hazards and Rain/Snow frame pacing. Verify safe controls and all important HUD/menu/result buttons on the phone's notch/navigation area, including alternate gesture/navigation modes if available.
- [ ] Purchase/select a character if coins permit; verify insufficient-funds behavior and all owned skins. Collect coins, finish for stars/best, force-stop/relaunch only after returning to menu, and compare saved totals/unlocks.
- [ ] Complete a level, use Play Again/Level Select/Next. Lose all lives and time out separately. Failure must have no Next/stars/fireworks. Level 15 completion must have no Level 16 target.
- [ ] Earn a successful new best; leave fireworks open **two minutes** with sound on, then test all three exits. Listen for clipping/overlap; mute/unmute, confirm no continuing cue after leaving. Try equal/worse result and failure: no celebration.
- [ ] Home/minimize during movement and during a train warning; reopen; gameplay should remain paused until resume. Test a screen interruption and return. No duplicated managers/sound, no progression loss.
- [ ] Play/retry/navigate for **20–30 minutes**, concentrating on Level 15 and rain/snow. Note stutters, heat, touch latency, audio dropouts or crash, and whether performance degrades over time. Compare beginning/end. Do not assume Linux FPS numbers predict your phone.
- [ ] Report each failure with level, theme, state, exact steps, device/build version and screenshot/video; include Godot/Android logs if available, without publishing signing passwords or credentials.

## 30. Final classification

**NOT READY FOR M15 — pending native build and device qualification.**

Known remaining BLOCKER/HIGH gameplay-code bugs: **none found in executed tests**. Unclosed release gates: obtain successful native Windows EXE and Android development APK builds with configured templates/toolchain, verify them outside the editor, and complete the physical-phone/native-Windows checks above. These gates are explicit because resource-pack tests and Linux screenshots are not substitutes for native exports or hardware acceptance. No additional feature milestone should start automatically.

## 31. Deliverable and reproducibility

One `PocketCrossing_M14_Update.zip`: merge over completed M13 in a backed-up candidate folder. It contains only changed/new scripts, test/capture scenes, UID files, documentation and evidence. It does **not** replace `project.godot` or `export_presets.cfg`, and contains no saves, signing keys, SDK, export binaries or `.godot` cache. Preserve your complete M13 backup for rollback.

Run focused tests with the Godot binary from the project folder:

```text
godot --headless --path . res://tests/qa_validation.tscn
godot --headless --path . --fixed-fps 60 res://tests/qa_contacts.tscn
godot --headless --path . res://tests/qa_stress.tscn
godot --headless --path . res://tests/qa_stress.tscn -- --soak-seconds=1200
godot --headless --path . res://tests/qa_perf.tscn
```

For visual captures run `tools/capture_qa.tscn` with a real rendering driver; it writes M14 screenshots and holds fireworks open for two minutes. Developer tools/tests are excluded from normal export. `qa_repro.tscn` prints targeted diagnostic booleans; the assertion-bearing suites are the pass/fail gates. Validation logs include exact commands/environment findings, per-suite results, asset/reference audits, native-export failure reasons and packed-startup results. See `M14_REQUIREMENT_COVERAGE.md` for all 65 request items.
