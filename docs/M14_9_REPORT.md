# Pocket Crossing M14.9 — Records, Personal Best Ghost and Gameplay Polish

## 1. Status and scope

M14.9 implementation is complete, subject to the physical Windows/Android checks below. It extends the confirmed M14.8 project. It adds no maps, characters, networking protocol, gameplay penalties, or M15 work. Automated and rendered verification used Godot 4.5.2 on Linux; it is not a claim of physical Windows or Android testing.

## 2. What already existed

M14.8 already had the four maps, five-crossing rules, Local/Friends/Challenges, mastery, coins, skins, power-ups, road/rail/water systems, camera, streaming, themes, profile saves, authoritative multiplayer results/awards, and bounded result fireworks. Initial M14.9 work also contained draft records/ghost/presentation modules and synthesized audio. These were completed and connected rather than replaced.

## 3. What was finished

Connected records to run start/results and the menus; connected ghost recording/playback to real player events; added isolated Local-only replay; completed settings persistence, ambience, pickup/splash/warning cues and bounded feedback. Fixed ghost visibility during respawn, made recording signatures safe for exported packs, and added completion cleanup and validation. Exact delivered files appear in `M14_9_FILES.json`.

## 4. Records architecture

`RunRecords` owns optional profile fields. `RecordsHUD` displays them; gameplay controllers provide run identity and final statistics. Existing scoring, rewards, damage and networking remain their original owners. Records cannot grant currency or unlock anything.

## 5. Categories and measurements

Each map has separate Local, Friends and `challenge:<challenge_id>` entries. They contain plays, completions, best completed time, highest final score, highest pickup-coin total, fewest deaths on a completed run, and Friends first/second/third-place counts. Mastery is read from the existing mastery system. Completion/mastery reward coins are excluded from the pickup-coin record. Quitting a run counts its start, but does not invent a final result. Friends podiums follow the host's ranking mode, including ranked DNF/time-up results.

## 6. Duplicate protection

Each Local/challenge attempt receives a random token. Friends uses the existing match receipt. Start and result receipts prevent repeated callbacks from adding plays, completions or podiums. The most recent 256 start/result receipts are retained to bound save growth. Existing currency-award receipt protection remains separate and unchanged.

## 7. Save migration

The existing profile schema/version and fields remain valid. Optional `records_v1`, `record_receipts` and `presentation_options` fields are added. Previous Local/Friends/challenge best times and challenge scores remain visible. Historical play counts cannot be reconstructed, so counters begin with newly recorded runs. Invalid optional statistics are ignored or repaired without discarding the account, coins, skins, selected character, mastery or previous best times.

## 8. Ghost architecture

`PersonalBestGhost` is a drawing-only Node2D, not an actor or physics body. It does not receive input, trigger collisions, collect rewards, affect the camera target, or participate in networking. It records only normal Local runs. Challenges and Friends clear and disable it. The entire sequence of five crossings, destination arrivals and respawns is recorded.

## 9. Recording format

One JSON sidecar per account/map lives beside the profile under `user://`. The filename includes an account-key hash and map ID. Its header stores format version, map ID, gameplay-layout signature, completion seconds and skin. Each event contains `[seconds, kind, from_x, from_y, to_x, to_y, direction_x, direction_y, duration]`. Kinds are spawn, hop, land, water drift, hide, destination and end. Hops use the existing smooth-step interpolation. Water riding gets occasional 4 Hz drift samples, not full-frame recording.

## 10. Personal-best replacement and validation

Only a successfully saved, faster completed normal Local best replaces a recording. Failed/slower runs preserve it. Playback requires a matching layout, matching best time, valid skin, finite ordered events and five destination events. Validation uses loaded Resource values, not editor-only source text. Missing/corrupt/stale files safely disable playback. Limits: 8,192 events, 2 MiB and one hour. Exceeding a limit stops recording without blocking gameplay or the saved best time.

## 11. Ghost settings

Main Menu → Settings → PB Ghost appears when a compatible recording exists. Its toggle controls playback; normal Local runs can still record a new best while playback is off. With an older best time but no recording, beat that best once to create a ghost. The translucent cyan character, ring and “PB” label distinguish it from the live character. It represents the old route: current traffic may differ, so it is not a safe-route guide.

## 12. Movement and landing

Existing hop timing, buffering, sprite tilt, arc, landing squash and shadow remain intact. New player signals report accepted hops and hiding to the recorder. Lightweight ground dust is added on suitable landings, excluding water and destinations. These are presentation changes, not movement changes.

## 13. Pickups and impacts

A small bounded coin ring/spark effect and distinct coin cue accompany pickups. Water deaths emit a splash and splash cue. Road/train deaths emit impact feedback; train shake is slightly stronger. Cosmetic camera offset is at most 2.5 pixels for 0.16 seconds and is reset on pause/menu. Shield handling still uses existing damage rules, so shield absorption does not add a death record. New effects are capped at 20 concurrent bursts.

## 14. Destinations and fifth crossing

Existing destination occupancy pulses, arrived-character visuals and results remain. Added short success feedback and Android haptics distinguish arrivals and the fifth crossing. Result transitions stop ambience, let short effects expire and preserve the existing result celebration. Retry/menu cleanup reuses or clears presentation nodes.

## 15. Audio and ambience

Seven original synthesized WAVs are included: coin, splash, railway warning, and four map ambiences. Village uses bird-like tones; city uses a low urban hum; river uses soft water noise; night uses insect-like tones. Ambience is assigned through `MapConfig.ambience`, loops through one reused voice at -29 dB, and uses softened loop edges. Coin/warning cues are throttled. The warning cue supplements the existing visual signals and never changes train timing.

## 16. Sound and vibration settings

Settings exposes Sound, Ambience and Vibration, plus PB Ghost when available. Sound is the master switch. Ambience can be disabled independently. Vibration uses the existing saved preference and only invokes the API on Android. Impact/arrival vibration is short; there is no duplicate legacy hit vibration in the map game. Device loudness, speaker balance and haptic strength need physical testing.

## 17. Night presentation

Night roads gain inexpensive edge reflectors; active railway lamps gain a small drawn halo. Existing vehicle/train headlights, player highlighting and theme readability remain. No dynamic lights, shadow maps, shaders or new physics are introduced.

## 18. HUD and results

Local/challenge HUD shows mode, score, pickup/reward display and active power-up text in the existing strip. Friends shows score/coins alongside compact standings; long names are abbreviated only in that narrow strip. Lobby and result names remain full. Existing competitive result columns and host-derived awards are reused unchanged. Records is a separate Main Menu screen, avoiding extra gameplay panels.

## 19. Fireworks

The existing M14.7/8 implementation is preserved: 4–6 rockets per wave, at most six active waves, bounded reusable draw buffers, one rate-limited audio voice, and cleanup on leaving results. The rendered test leaves the screen active for a real 120 seconds, measures record/node bounds and confirms cleanup. See `M14_9_VALIDATION.json` for this run's measurements.

## 20. Performance and compatibility

One ghost drawing node, one presentation drawing node and one ambience voice are added per game. No per-section weather/feedback duplication is added. Ghost events are captured at discrete actions, with sparse water drift samples. Records write on run boundaries, not per frame. Android split-touch/swipe controls, Windows keyboard actions, landscape layout, save paths and export presets are preserved. Audio sample-peak analysis includes all four cue voices, ambience and the result voice; it is a conservative no-clipping bound, not a listening test.

## 21. Automated verification

`M14_9_VALIDATION.json` contains exact results. Coverage includes records/settings migration, duplicate callbacks, failed/slower/faster ghost runs, corrupt sidecars, rename identity, shield/death effects, pause/retry cleanup, all-four-map real five-crossing ghost routes, M14.8 challenge routes, preserved regression suites, real four-process ENet matches, matching host awards/results, exported-pack record/replay loading, resource references, UI captures and the 120-second fireworks test. Some inherited tests deliberately exercise corrupted legacy saves or report old test-teardown ObjectDB warnings; these must not be confused with a clean main startup/parser check.

## 22. Exact Windows manual tests

1. Back up your M14.8 project. Close Godot, copy the update's `PocketCrossing` contents into the existing folder containing `project.godot`, and accept file replacements. Reopen and let imports finish. Use the editor's Run Project button; no function-key shortcut is required.
2. Confirm the same username, wallet, owned maps/skins, selected skin, best times and mastery. Open Records and switch all four maps and all three categories.
3. In normal Local Play finish five crossings. If an old best exists, beat it. Open Settings and confirm PB Ghost becomes available. Retry and watch its full sequence. It must not collect coins, lose lives, occupy destinations or move the camera.
4. Turn PB Ghost off, restart a run and confirm it is hidden. Turn it on and retry. A failed/slower run must not replace it. Close/reopen the game and verify settings, records and replay persist.
5. Play each map with keyboard and mouse/touch controls. Collect coins/power-ups, absorb one hit with a shield, take road/train/water deaths, backtrack, pause/resume and retry. Watch for stuck shake, duplicate particles, sounds or ambience.
6. Compare each map's ambience at a comfortable volume. Toggle Sound and Ambience independently. Check that railway warnings remain readable with sound off.
7. Finish a challenge and confirm its records change without changing normal Local PB/ghost. In Friends Play test two and four peers, both ranking modes, timeout, completion, replay, change map and leave. All devices should show the same results/awards; each device updates only its own Friends records.
8. Leave winner fireworks running for two minutes. Return to menu and replay; confirm cleanup and stable responsiveness. Resize to a small landscape window and check Records/Settings/touch-button readability.

## 23. Exact Android manual tests

Install an updated build over the existing application using the same package/signing identity; do not uninstall if preserving its save. Repeat steps 2–8 above with split touch and swipe. Specifically check vibration off/on, ghost contrast on Night Express, river-platform riding with a ghost visible, warning audibility over ambience, application background/resume, system Back, two-minute fireworks, low/mid-range device frame pacing, and long username clipping. Test LAN over the actual Wi-Fi/hotspot with both Android and Windows peers. No physical Android or Windows device testing was performed in this environment.

## 24. Limitations and next milestone

Records are local to the device; there is no cloud synchronization or historical counter reconstruction. Ghosts are cosmetic, bounded and tied to a compatible layout/best time. Render performance measurements come from Linux software rendering, not a phone GPU. Physical audio/haptics, device frame pacing and real Wi-Fi/hotspot behavior remain acceptance checks. The code is ready for those checks; after they pass, M15 can be separately scoped. M15 has not been started.

### Modified-file purposes

| File | Purpose |
|---|---|
| `scripts/actors/player.gd` | Report accepted hops and hiding; movement equations unchanged. |
| `scripts/core/audio.gd` | Load new original cues and rate-limit coin/warning playback. |
| `scripts/core/game.gd` | Use coin cue and avoid duplicate map-game haptics. |
| `scripts/core/map_game.gd` | Local/challenge record lifecycle, ghost lifecycle, presentation feedback and score HUD. |
| `scripts/core/mode_game.gd` | Records/settings actions, Friends receipts and presentation cleanup, compact HUD. |
| `scripts/data/map_config.gd` | Inspector-editable ambience stream. |
| `scripts/network/lan_race.gd` | Cosmetic pickup cue selection only; authority/scoring unchanged. |
| `scripts/presentation/theme_art.gd` | Lightweight Night road reflectors. |
| `scripts/ui/mode_hud.gd` | Records entry and settings controls. |
| `scripts/ui/mode_navigation.gd` | Back navigation from Records. |
| `scripts/world/railway_signal.gd` | Small halo around active warning lamps. |
| `resources/maps/village_crossing.tres` | Assign Village ambience only. |
| `resources/maps/city_rush.tres` | Assign City ambience only. |
| `resources/maps/river_delta.tres` | Assign River ambience only. |
| `resources/maps/night_express.tres` | Assign Night ambience only. |

New runtime modules are `scripts/records/run_records.gd`, `ghost_store.gd`, `personal_best_ghost.gd`, `scripts/presentation/run_presentation.gd`, and `scripts/ui/records_hud.gd`. New automated tests are `records_tests`, `ghost_routes`, `records_peer_tests`, and `records_visual` with their scenes. The new tools run the records peers and reproduce the original audio assets. All new WAV/import/UID/document files are explicitly enumerated in the JSON file manifest.
