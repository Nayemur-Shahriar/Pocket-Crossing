# Pocket Crossing — focused refinement after M14.9

## 1. Overall status

All 14 requested changes are implemented and passed the automated/rendered checks described below. Physical Windows and Android acceptance, including listening on actual speakers/headphones, remains for you. No M15 work, new maps, scoring formula, ranking redesign or networking redesign was added.

The working M14.9 checkpoint was inspected first. Existing systems were extended: the same four maps, five-crossing objective, section compiler, Road/Railway/Water gameplay, camera, controls, accounts, progression and authoritative LAN race remain.

## 2. Files created (75)

Paths are relative to your existing project. `.uid` and `.import` files are Godot metadata. The screenshot files document visual checks, and are excluded from game exports by the existing preset.

```text
assets/art/courier_elder_man.svg
assets/art/courier_elder_man.svg.import
assets/art/courier_elder_woman.svg
assets/art/courier_elder_woman.svg.import
assets/audio/REFINEMENT_AUDIO_LICENSE.txt
assets/audio/dog_bark.wav
assets/audio/dog_bark.wav.import
assets/audio/dog_catch.wav
assets/audio/dog_catch.wav.import
assets/audio/impact_bus.wav
assets/audio/impact_bus.wav.import
assets/audio/impact_car.wav
assets/audio/impact_car.wav.import
assets/audio/impact_cng.wav
assets/audio/impact_cng.wav.import
assets/audio/impact_rickshaw.wav
assets/audio/impact_rickshaw.wav.import
assets/audio/impact_train.wav
assets/audio/impact_train.wav.import
assets/audio/impact_truck.wav
assets/audio/impact_truck.wav.import
assets/audio/impact_van.wav
assets/audio/impact_van.wav.import
assets/audio/morning_walk.wav
assets/audio/morning_walk.wav.import
assets/audio/water_entry.wav
assets/audio/water_entry.wav.import
docs/REFINEMENT_FILES.json
docs/REFINEMENT_REPORT.md
docs/REFINEMENT_VALIDATION.json
docs/refinement_screenshots/character_selection_bottom.png
docs/refinement_screenshots/character_selection_bottom.png.import
docs/refinement_screenshots/character_selection_top.png
docs/refinement_screenshots/character_selection_top.png.import
docs/refinement_screenshots/characters_phone.png
docs/refinement_screenshots/characters_phone.png.import
docs/refinement_screenshots/dog_running.png
docs/refinement_screenshots/dog_running.png.import
docs/refinement_screenshots/dog_warning.png
docs/refinement_screenshots/dog_warning.png.import
docs/refinement_screenshots/home.png
docs/refinement_screenshots/home.png.import
docs/refinement_screenshots/maps.png
docs/refinement_screenshots/maps.png.import
docs/refinement_screenshots/night_character.png
docs/refinement_screenshots/night_character.png.import
docs/refinement_screenshots/settings.png
docs/refinement_screenshots/settings.png.import
docs/refinement_screenshots/settings_phone.png
docs/refinement_screenshots/settings_phone.png.import
docs/refinement_screenshots/six_characters.png
docs/refinement_screenshots/six_characters.png.import
scripts/data/dog_config.gd
scripts/data/dog_config.gd.uid
scripts/presentation/dog_view.gd
scripts/presentation/dog_view.gd.uid
scripts/presentation/hazard_audio.gd
scripts/presentation/hazard_audio.gd.uid
scripts/world/dog_encounter.gd
scripts/world/dog_encounter.gd.uid
tests/refinement_parse.gd
tests/refinement_parse.gd.uid
tests/refinement_parse.tscn
tests/refinement_peer_tests.gd
tests/refinement_peer_tests.gd.uid
tests/refinement_peer_tests.tscn
tests/refinement_tests.gd
tests/refinement_tests.gd.uid
tests/refinement_tests.tscn
tests/refinement_visual.gd
tests/refinement_visual.gd.uid
tests/refinement_visual.tscn
tools/generate_character_art.py
tools/generate_refinement_audio.py
tools/run_refinement_peers.py
```

## 3. Files modified (42)

```text
README.md
assets/art/courier.svg
assets/art/courier_coral.svg
assets/art/courier_mint.svg
assets/art/courier_violet.svg
resources/maps/city_rush.tres
resources/maps/night_express.tres
resources/maps/river_delta.tres
resources/maps/village_crossing.tres
resources/presentation/celebration.tres
scripts/actors/player.gd
scripts/actors/railway_train.gd
scripts/actors/vehicle.gd
scripts/core/audio.gd
scripts/core/game.gd
scripts/core/map_depth_progress.gd
scripts/core/map_game.gd
scripts/core/mode_game.gd
scripts/data/celebration_config.gd
scripts/data/character_catalog.gd
scripts/data/map_config.gd
scripts/data/mastery_goal.gd
scripts/network/lan_config.gd
scripts/network/lan_race.gd
scripts/network/lan_replica.gd
scripts/network/lan_session.gd
scripts/presentation/run_presentation.gd
scripts/records/ghost_store.gd
scripts/records/personal_best_ghost.gd
scripts/ui/map_depth_hud.gd
scripts/ui/map_hud.gd
scripts/ui/mode_hud.gd
scripts/ui/mode_navigation.gd
scripts/ui/records_hud.gd
scripts/ui/result_celebration.gd
tests/competitive_tests.gd
tests/ghost_routes.gd
tests/map_depth_tests.gd
tests/map_depth_visual.gd
tests/records_peer_tests.gd
tests/records_tests.gd
tests/records_visual.gd
```

The four retired scripts listed below contain only an inert base declaration/comment. This allows a simple copy-over ZIP to overwrite their old implementation without requiring manual deletion. Full lists are also in `REFINEMENT_FILES.json`.

## 4. PB Ghost removal

Removed the runtime node, recordings, playback, hop-recording signals, toggle, settings text and calls from Local/Friends flows. `personal_best_ghost.gd` and `ghost_store.gd` are inert compatibility files. Existing ghost sidecars and optional old profile fields are ignored; nothing reads or rewrites them. Best Time and useful internal run statistics remain.

## 5. Records removal

Removed the home button, screen, map/category actions and Back navigation route. `records_hud.gd` is inert. `RunRecords` remains an internal statistics/settings helper because results, Best Time and save compatibility still use its data. There is no replacement Records screen.

## 6. Mastery removal

Removed goals from the four map Resources, map-card indicators/buttons, details panel, awarding logic and result messages. `mastery_goal.gd` is inert. Existing mastery fields, including malformed obsolete values, no longer invalidate an otherwise valid account. Challenges keep their independent completion, best-time, score and normal completion-reward path. Map Play/Unlock buttons expand into the released space.

## 7. Firework configuration

| Parameter | Final behavior |
|---|---|
| Rockets per wave | Random 4–6 |
| Launch stagger | 0.18–0.35 seconds, varied per rocket |
| Explosion stagger | 0.15–0.40 seconds, independently varied |
| Full-wave gap | 1.2–1.8 seconds after the final burst expires |
| Concurrent records | At most six, one wave |
| Spark lifetime | 1.15 seconds |
| Rays | 20 per burst, reused drawing buffers |
| Audio | One player, maximum one launch of the sound per 0.25 seconds |

Launch/target positions, height, travel time, radius and color vary. No accumulating timers or emitters. `resources/presentation/celebration.tres` remains editable. The actual rendered 120-second run produced 27 waves and stayed at six or fewer records and one audio child. Cleanup passed.

## 8. Music system

`Audio` now owns one persistent music player alongside its existing four SFX voices. `morning_walk.wav` is an original, synthesized 32-second celesta/pad composition with a periodic loop; no commercial song or third-party samples were used. The generator and ownership note are included.

Music fades in, stays below SFX at −23 dB, and ducks to −33 dB for important cues. Menus and small panels do not recreate or restart the player. Turning Music off fades and pauses it; turning it back on resumes. Music can continue during a pause/menu.

SETTINGS has separate MUSIC and SOUND buttons. Music is stored in the existing profile's optional presentation settings. Sound retains its existing saved setting. MUSIC OFF/SOUND ON and MUSIC ON/SOUND OFF were both tested, including reload. Ambience remains controlled by Sound and its existing Ambience option. Music does not depend on Sound.

## 9. Characters and fairness

| Save ID | Character | Visual treatment | Unlock |
|---|---|---|---|
| pip | Pip — young boy | Smaller stature, amber striped top, short hair | Existing free character |
| mint | Mika — young girl | Smaller stature, mint top, tied hair | Existing free character |
| coral | Rio — adult man | Taller proportions, coral shirt, dark skin/hair | Existing 20 coins |
| violet | Nova — adult woman | Taller proportions, longer hair, violet clothing | Existing 40 coins |
| elder_man | Arun — older man | Gray hair, glasses, teal cardigan/vest | 30 coins |
| elder_woman | Leela — older woman | Gray hair/bun, glasses, rose cardigan | 30 coins |

All are original lightweight SVG art. The original four IDs retain existing ownership and selection. The existing scrollable Character Selection handles all six. Selection persists and is used for Local and Friends identity.

The player scene and standardized 26×28 collision rectangle are unchanged. Character selection changes only the texture: same grid, hop duration/distance, speed, lives, collision rules, power-ups, scoring and respawn. There are no age/gender bonuses or pay-to-win abilities.

## 10. Dog mechanic

`DogConfig` is an optional MapConfig Resource; `DogEncounter` holds the small authority state; `DogView` draws one local dog/warning. No pathfinding, extra physics bodies or spawned timer nodes are needed.

Village Crossing enables it in `safe_2` and `safe_4`, the two intermediate dry safe sections. Start, Destination, Road, Railway and Water never qualify. City, River and Night currently have no dog configuration.

Default sequence: 3.0 seconds meaningfully stationary → visible “DOG NEARBY · MOVE” and one bark → 1.0-second warning → dog enters from outside the left/right edge at 300 px/s. It is never spawned on the character. A swept horizontal contact check handles low frame rates. Moving more than eight pixels or beginning a valid hop cancels the threat, including during its run; blocked button presses do not count as movement. There is a five-second catch cooldown and a fresh stationary grace after reset/protection. Normal traversal does not repeatedly trigger it.

A catch calls the same guarded collision path as traffic. Shield/invulnerability still work. One accepted contact takes one life and starts the existing respawn. Pause freezes the Local encounter; Retry/menu/end clear it. Friends Play retains its existing non-pausing race menu behavior.

To tune: open `resources/maps/village_crossing.tres` in Inspector, expand **Dog**, and edit section IDs, Stationary Seconds, Warning Seconds, Run Speed or Cooldown Seconds. Other maps can opt in by assigning a DogConfig; the runtime does not hard-code a map ID.

## 11. Friends dog feedback

Each racer has an independent host-side encounter. Only the recipient's dog state is included in their existing owner snapshot. Each device has one DogView; remote dogs are not rendered. The host accepts life loss and sends a reliable, sequence-deduplicated owner feedback message. The ordinary shared feed receives “NAME was caught by a dog” (with OUT when applicable), using its existing bounded queue, three-second display and fade.

The four-process test verified a remote client's warning/chase/catch, exactly one life deduction, exactly one dog feed message on all four peers, and no heavy remote collision audio. It also checked water feedback and unchanged score/ranking results. All peers must install this update; the existing content-version handshake prevents mixed old/new builds.

## 12. Vehicle impact audio

All cues are separate original synthesized waveforms, not one clip at different volumes. No injury screams.

| Vehicle IDs | Cue asset | Character |
|---|---|---|
| rickshaw | impact_rickshaw.wav | Light mechanical ring/rattle |
| cng | impact_cng.wav | Small resonant body impact |
| car, small_car | impact_car.wav | Medium automotive thump |
| pickup, delivery_van, microbus | impact_van.wav | Stronger medium body impact |
| bus, local_bus | impact_bus.wav | Heavy body resonance |
| truck, medium_truck, large_truck | impact_truck.wav | Low heavy impact |
| train | impact_train.wav | Stronger metallic rail impact |

## 13. Water death audio

`water_entry.wav` combines a short entry transient, splash and brief bubbling/water movement. It plays at the accepted water-hazard event with the existing splash visual and respawn. It no longer also plays the generic vehicle hit cue. Protected water rescues retain their existing behavior. The water sequence is environmental and non-graphic.

## 14. Central hazard routing

`HazardAudio` is the one cause-to-cue table. Vehicle and train contacts identify their actual source, captured before deferred dispatch so a second overlapping contact cannot overwrite the first sound's cause. Local feedback is called only after `CollisionRules` accepts life loss. LAN feedback is host-owned, targeted and deduplicated by match/sequence. The former per-frame death audio inference was removed. Dog catch uses `dog_catch.wav`, separate from the warning bark.

Tests verify every category, shield protection, overlapping/deferred contacts, duplicate contacts, one death/one SFX, and one respawn. Scoring/ranking logic was not replaced.

## 15. Saves and compatibility

No destructive migration or save reset. Username/device identity, coins, map unlocks, selected/owned characters, Best Time, existing stats, Friends settings and audio settings remain. New character IDs and the Music preference are additive. Ghost and Mastery fields are ignored. No weather/theme or new gameplay data is written into progression per frame.

The existing save writers, account implementation, input router, player scene and LAN score/ranking formula are byte-for-byte unchanged. Existing map section/lane/platform/track subresources are unchanged; only obsolete goals were removed and Village received its optional dog rule.

## 16. Automated results

**5,527 explicitly counted checks: 5,527 passed, 0 failed** in the final successful runs. Repeated clean-copy checks are not counted twice. Three legacy suites report successful exit rather than assertion counts.

| Group | Passed | Failed |
|---|---:|---:|
| 25 preserved regression suites (reported assertions) | 4,354 | 0 |
| Focused refinement | 120 | 0 |
| Internal statistics | 41 | 0 |
| Map depth / independent Challenges | 138 | 0 |
| Fireworks/ranking + competitive flow | 54 | 0 |
| Real map routes without Ghost | 16 | 0 |
| Challenge routes | 68 | 0 |
| LAN stabilization + extra | 52 | 0 |
| Four maps, four ENet peers | 344 | 0 |
| Timed competitive/records, four peers | 268 | 0 |
| Dog/water ownership, four peers | 59 | 0 |
| Audio uniqueness/peaks/loop-seam checks | 13 | 0 |

Additional gates: **322 scripts/scenes/Resources loaded**, **783 concrete references checked with none missing**, clean baseline + update import/startup/resource/focused checks passed, exported PCK smoke passed, and the real two-minute rendered fireworks test passed. No GDScript/parser errors in final checks. The PCK check exercises exported data; it is not a Windows EXE or Android APK device test.

The new tests initially exposed Resource assignment order and audio test teardown issues; both were fixed. Some older accelerated tests still emit Godot ObjectDB shutdown warnings, and negative-path tests deliberately exercise invalid saves/configurations. They report no failed assertions. The final normal startup, clean-copy focused run, exported pack and owner-feedback tests show no resource-in-use errors.

Machine-readable results: `REFINEMENT_VALIDATION.json`. To rerun focused checks, run `tests/refinement_tests.tscn`, `tests/competitive_tests.tscn`, and `tests/refinement_parse.tscn`. For real processes, use `tools/run_refinement_peers.py GODOT_EXECUTABLE` and the existing LAN runners.

## 17. Windows/manual tests actually performed

No physical Windows testing was possible here. Linux Godot 4.5.2 was run headlessly and with the Compatibility renderer under Xvfb. Rendered screenshots were inspected for home, maps, settings, Character Selection (top/bottom), six-character art, Village dog warning/run, and Night visibility, at 1280×720 and 640×360. The dog warning stays within the safe lane rather than covering neighboring traffic.

Perform these Windows checks:

1. Run your existing main project. Check that Ghost, Records and Mastery are absent, while Local, Friends, Challenges, Settings and Characters work; use keyboard focus and Back/Escape.
2. Open Local → Characters. Scroll to Arun/Leela; unlock/select several characters. Restart the app and confirm selection, wallet, owned maps and Best Time remain.
3. In Settings, test both Music/Sound combinations, then both off/on. Switch menus and Retry: music should continue smoothly. Restart to confirm preferences.
4. Play each of the four maps with the existing keyboard controls. Complete five distinct destinations; check coins, timer, lives, score, shield, Retry and results.
5. In a Village intermediate safe lane, stay still for three seconds. Confirm bark plus visual warning for one second before entry. Move on warning: no catch. Repeat without moving: one life loss. Repeat with shield and test pause/resume during warning.
6. Listen to rickshaw, CNG, small car, van/pickup, bus, truck and train impacts. They should differ and remain comfortable below maximum system volume. Fall into River: only splash/water audio, synchronized with the splash.
7. Achieve a new Local Best Time or host a winning Friends result. Watch fireworks for two minutes: 4–6 staggered rockets, pauses after full waves, no progressive slowdown. Alternatively run `tests/competitive_visual.tscn` with the editor's **Run Current Scene** control; it keeps the fixture open for two minutes.
8. Confirm train warnings, bark, countdown/GO cues and finish feedback are readable/audible over music. Verify water platforms remain playable and the character visible at Night.

## 18. Multiplayer tests actually performed

Four separate Godot processes used real loopback ENet connections. Tests covered host/join, maps/readiness, countdown, predicted movement, only-own-actor rendering, shared hazards, feed, deterministic results, score/time modes, a real 60-second expiry, replay and account/stat isolation. Four-map results and timed competitive results matched across all peers. Separate stabilization tests covered input/session cleanup.

The dedicated dog test placed one remote participant on a configured safe lane and let the host run the complete grace/warning/entry/catch sequence. Only that participant saw the warning/run and heard bark/catch/water. All four received one dog message. Duplicate damage/feedback was rejected.

For real LAN acceptance, connect two to four updated devices on the same Wi-Fi/hotspot. Let one guest camp in Village while everyone else stays at Start: other phones must show only the message, not the chase or heavy sound. Then test simultaneous traffic/water deaths for audio spam, all maps, Time and Score modes, client input smoothness, host disconnect, client Leave and replay.

## 19. Android tests actually performed

No physical Android device or APK installation was tested. Phone-sized rendered UI checks and the preserved touch/swipe regression tests passed. Those do not substitute for device GPU, speakers, Wi-Fi or operating-system behavior.

## 20. Exact physical Android checklist

1. Install your updated export on every participating phone. Open in landscape; check safe margins, readable menus, Back and Exit confirmation.
2. Open Characters. Scroll with a finger through all six; distinguish young/adult/older and male/female art. Ensure a drag does not accidentally buy/select. Select Arun or Leela, restart and confirm persistence.
3. MUSIC OFF + SOUND ON: hops, bark, collisions and train warnings work without music. SOUND OFF + MUSIC ON: only music remains. Test both off, then restart for saved settings.
4. Switch menus, Retry and return from gameplay repeatedly. Music must not layer or restart each time; no stuck dog or overlay remains.
5. Play Road, Railway and Water with split-touch controls and swipe. Check five destinations, coins, power-ups, life loss and respawn. Confirm no movement advantage for a different character.
6. On Village's intermediate safe lane, stand still: three-second grace, one-second readable warning and audible bark, then entry. Move after the bark to escape. Walk normally through the lane to ensure no repeated unfair triggers. Repeat with shield, Retry and pause during warning.
7. Check the dog on both screen sides and while scrolling. Watch for touch delay or frame spikes.
8. Listen through phone speakers and headphones to every impact category and water entry. No harsh peaks, generic vehicle sound on water, duplicate death sound or warning masked by music.
9. Leave winning fireworks open for two minutes. Observe FPS/heat before and afterward, staggered waves and breathing gaps. No growing slowdown or sound spam.
10. Test Night readability and existing Rain/Snow/Fog performance. Confirm platforms and train signals remain visible; the new art must remain readable.
11. On two to four updated phones, host/join through Wi-Fi and hotspot. Let one guest be caught by a dog: that guest alone sees/hears its encounter; everyone gets one temporary name/cause message.
12. Trigger several participants' traffic/water deaths around the same time. Each phone should hear its own full impact, not everyone's. Check smooth guest movement, countdown, Time/Score results, replay, host disconnect and client Leave.
13. Use Android Back from settings, character selection, Local pause/results and Friends lobby/race. Cancel and confirm where offered. Background/resume the app and check controls/audio for stuck state.
14. Restart the app and confirm username, coins, maps, characters, Best Time, score data and both audio settings survived.

Report device model, Android version, observed FPS and any audio/visibility issue if something differs.

## 21. Performance findings

The 120-second rendered result test processed 5,678 frames: median 20.37 ms and p95 25.0 ms on software OpenGL (Mesa llvmpipe). It kept one audio child and at most six effect records, with no node growth and successful cleanup. These numbers are not a phone FPS promise.

The dog is one drawing node per device and small authority state per racer; no AI navigation, timers or extra collision nodes. Six character textures replace the same player art. Music adds one reusable voice, and all hazard SFX reuse the existing four voices. No per-frame save writes were added. Normal graphics and weather systems remain unchanged.

## 22. Known limitations

Physical Windows/Android, Wi-Fi/hotspot conditions and subjective sound quality need the manual checks above. Sounds are original synthesized casual-game effects, not field recordings. Human art is stylized 2D, not photorealistic. The dog currently exists only in Village intermediate safe sections; other maps deliberately remain opted out. Existing historical milestone documentation may describe removed features; this report and the updated README describe the current build.

## 23. Local stability

Local regressions passed across all four maps and the retained earlier systems. Five-crossing completion, Best Time, independent Challenges, coins, skins, shield, Road/Railway/Water, pause/retry and saves were exercised. Existing map gameplay Resources and standardized player scene were preserved.

## 24. Friends stability

Real four-peer results and the added dog/water ownership checks passed. Existing authority, prediction, score/rank rules and own-character-only design remain. Only owner dog metadata and reliable owner hazard feedback were added to the current session; there is no new multiplayer architecture.

## 25. Update ZIP

Use only **PocketCrossing_Refinement_Update.zip** for your existing stable M14.9 project. Close Godot, extract it, copy the contents of its `PocketCrossing` folder over your existing project folder, replace matching files, then open your existing `project.godot` and let imports finish. No manual deletion, save reset or second ZIP is needed. The update was applied to a clean copy of the saved baseline and passed import, startup, all resource loads and the focused suite. No M15 work starts automatically.
