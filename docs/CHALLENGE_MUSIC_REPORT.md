# Pocket Crossing — Challenge transition and music fix

Status: implementation verified in the available Godot/Linux environment. Physical Windows/Android and subjective music acceptance remain. This is a focused update on top of PocketCrossing_Polish_Update.zip, not a new milestone or release build.

## 1. Root cause

Challenge PLAY called select_challenge directly instead of the existing SceneFade wrapper. In addition, switching Challenge map tabs rebuilt the menu with _page(), which set its opacity to zero for a menu fade-in. The previous gameplay world could therefore be seen through the menu for a few frames even when no new world was being loaded. The previous transition also began fading immediately after its synchronous callback without a post-initialization settling phase.

World replacement already detaches old lanes/goals before queuing them for deletion. Challenge modifiers are applied to a deep copy before configure(). Player spawn already snaps the camera and refreshes camera-relative presentation. These working systems were retained; the actual problem was missing presentation coverage, not a need to rebuild maps or cameras.

## 2. Exact transition fix

Challenge tabs and PLAY now use the existing single CanvasLayer transition. Challenge menus are immediately opaque when rebuilt, including returning from gameplay. Map preparation occurs only after full coverage. The overlay remains fully opaque for two process frames and at least one physics update after the callback. This lets deferred deletion, player/camera setup and weather updates settle before fade-in. The current initialization is synchronous; if future world loading becomes asynchronous, this barrier must be connected to that loader's ready signal instead.

Duplicate selection actions are rejected while busy; gameplay movement input stays disabled until the fade finishes. Pause-menu retry and Challenge keyboard retry use covered changes; result Retry already uses the shared controller. Escape can cancel before replacement; once replacement starts, Escape waits for the transition to finish rather than exposing an intermediate frame. Multiplayer countdown retains its existing forced cancellation of any overlay.

## 3. Timing

Fade-out 0.20 seconds. One pre-swap covered frame, then the synchronous swap and a short frame/physics settling barrier. Fade-in 0.22 seconds. No artificial multi-second loading delay. Existing loading caption is reused. The barrier naturally takes longer on a very slow device; it is tied to frame readiness rather than a long fixed timer.

## 4. Files changed

Modified:

- `assets/audio/city_steps.wav`
- `assets/audio/morning_walk.wav`
- `assets/audio/night_rails.wav`
- `assets/audio/river_drift.wav`
- `assets/audio/village_breeze.wav`
- `resources/environments/city.tres`
- `resources/environments/railway.tres`
- `resources/environments/river.tres`
- `resources/environments/village.tres`
- `scripts/core/audio.gd`
- `scripts/core/map_game.gd`
- `scripts/core/mode_game.gd`
- `scripts/data/environment_profile.gd`
- `scripts/ui/mode_hud.gd`
- `scripts/ui/mode_navigation.gd`
- `scripts/ui/scene_fade.gd`

Created:

- `assets/audio/ARCADE_MUSIC_LICENSE.txt`
- `assets/audio/city_steps_challenge.wav`
- `assets/audio/city_steps_challenge.wav.import`
- `assets/audio/night_rails_challenge.wav`
- `assets/audio/night_rails_challenge.wav.import`
- `assets/audio/river_drift_challenge.wav`
- `assets/audio/river_drift_challenge.wav.import`
- `assets/audio/village_breeze_challenge.wav`
- `assets/audio/village_breeze_challenge.wav.import`
- `builds/.gitkeep`
- `docs/ARCADE_MUSIC_SOURCE.txt`
- `docs/CHALLENGE_MUSIC_FILES.json`
- `docs/CHALLENGE_MUSIC_REPORT.md`
- `docs/CHALLENGE_MUSIC_VALIDATION.json`
- `docs/challenge_polish/city_rush.png`
- `docs/challenge_polish/covered_01.png`
- `docs/challenge_polish/covered_02.png`
- `docs/challenge_polish/covered_03.png`
- `docs/challenge_polish/covered_04.png`
- `docs/challenge_polish/covered_05.png`
- `docs/challenge_polish/covered_06.png`
- `docs/challenge_polish/covered_07.png`
- `docs/challenge_polish/covered_08.png`
- `docs/challenge_polish/night_express.png`
- `docs/challenge_polish/river_delta.png`
- `docs/challenge_polish/village_crossing.png`
- `tests/challenge_polish_tests.gd`
- `tests/challenge_polish_tests.tscn`

Exact lists are also in CHALLENGE_MUSIC_FILES.json. No deletion or save migration is required. The source score is supplied as optional text; there are no Python files in the update.

## 5. Music changes

Replaced the four calm map WAVs with original synthesized 16-bar arcade compositions. The menu music now uses the cheerful Village arrangement. These are actual new musical assets, not just louder playback. Each has melody phrases, chord movement, rhythmic bass, light kick/snare/hat patterns and phrase fills. Four Challenge variations add quiet arpeggios and/or denser hats.

All musical material and instruments are generated specifically for this project; no commercial melody, sample or recording was used. ARCADE_MUSIC_LICENSE.txt documents use permission. ARCADE_MUSIC_SOURCE.txt preserves the composition/generation source for future edits.

## 6. Per-map musical identity

| Map | Tempo | Arrangement |
| --- | ---: | --- |
| Village Crossing | 108 BPM | Warm major-pentatonic mallets/plucks, friendly bass and light rural-style rhythm |
| City Rush | 124 BPM | Syncopated bright keyboard/pluck, bouncy bass and tighter hats |
| River Delta | 112 BPM | Flowing mallets, offbeat phrasing, light travel/percussion feel |
| Night Express | 128 BPM | Soft electronic pluck, pulsing bass and playful minor coloration |

Loops last approximately 30–35.56 seconds. Score phrases repeat with variations over 16 bars. These are lightweight stylized synthesized tracks; whether the timbre feels sufficiently fun is a listening acceptance item for you, not something automated assertions can establish.

## 7. Challenge behavior

EnvironmentProfile exposes an optional challenge_music_track in addition to music_track. Challenge runs select this denser arrangement, with normal music as fallback. Normal play restores music_track. Configuration is reusable and not coupled to map geometry. Retry keeps the same track/player and does not restart the soundtrack. Repeated map cycling keeps the cached track set bounded. One music player is retained.

## 8. Music/SFX balance and transitions

Music remains -25 dB, ducking to -34 dB for important cues. No SFX gain, routing, debounce, Master limiter or danger priority was changed. Normal and Challenge tracks have the same 0.55 full-scale source peak; their musical energy comes from tempo and arrangement.

The existing single-player fade-down/switch/fade-up now moves at 120 dB per second: approximately 0.29 seconds from -25 to -60 dB, then approximately 0.29 seconds up. There is no loud two-track overlap. Requests for the same track do not restart it. Music OFF pauses the one music player immediately, independently of Sound, and persisted settings still reload.

Signal analysis found no clipped samples. Circular synthesis tails and beat-aligned duration provide loop continuity; numerical boundary deltas are recorded in CHALLENGE_MUSIC_VALIDATION.json. Actual listening for clicks, repetition fatigue and masking remains required on speakers/headphones.

## 9. Automated validation

- 1,092 headless assertions passed, zero failed: focused Challenge coverage (321), previous polish (126), stability (208), map campaign (110), Challenge/map-depth (138), competitive rules (27), competitive flow (27), keyboard/touch gameplay controls (135).
- Clean-apply check: applied the update to a fresh previous-polish project, imported successfully, and reran the focused Challenge suite (320 passed, zero failed; frame-observation counts vary with frame scheduling). This repeat is not added to the headless total.
- Resource sweep: 336 scripts/scenes/Resources loaded, zero failures. Import/parser checks passed. Static reference scan found no missing concrete resource paths.
- Separate real-render run: 338 assertions passed, zero failed. All 24 actual start/retry replacement frames were checked after rendering; sampled screen regions remained fully covered. This repeats much of the headless suite and is reported separately, not added as unique coverage.
- Three cycles through Village → City → River → Night → Village, including tabs, PLAY, duplicate PLAY, retry and return to the Challenge menu.
- Verified correct Challenge/layout/spawn/theme, controls restored, cancellation, same-track retry, normal/Challenge music selection, loop flags, independent toggle persistence and bounded players/cache.
- 72 protected gameplay/configuration files compared byte-for-byte against the prior polish checkpoint: unchanged.

Some harnesses still emit ObjectDB/resource-in-use warnings at shutdown (including one retained resource in the rendered harness). These are documented, not described as a warning-free shutdown. No new GDScript/parser failure or failed assertion was observed. No new multi-device LAN session was run in this focused pass; competitive regression tests passed and networking files are unchanged.

## 10. Visual/manual work actually performed

Godot 4.5.2 Compatibility rendered the repeated transitions using Linux software OpenGL/Xvfb at 1280×720. Actual covered swap frames were sampled and saved; the covered frame and initialized four-map screenshots were visually inspected. See docs/challenge_polish/. No uncovered replacement was detected in that environment. This was automated real-engine rendering with image review, not physical PC play or human audio listening for several minutes.

## 11. Android testing actually performed

No physical Android test was performed. No Android or Windows release export was started.

## 12. Required physical acceptance tests

On Windows, then Android landscape:

1. Apply this update AFTER the previous polish update. Run the main project normally.
2. Enter Challenges. Select Village, play a challenge, return, select City, play, return, select River, play, return, then Night. Repeat this full cycle three times. Look for old-map, empty-world, wrong-camera or partial-theme flashes during tabs and PLAY.
3. Retry from pause and from results; on PC also press R. Change to a different challenge on the same map. Return to Main Menu and reenter Challenges. Check that each transition stays covered until the correct map is ready.
4. Rapidly double-tap PLAY and map tabs. Only one change should occur. Try movement during the transition; it must not move the player until reveal finishes. Press Escape/Android Back early in fade-out to cancel, then press it during replacement: no flash or stuck overlay should appear.
5. Play every map normally for at least three minutes and every Challenge mix for at least two loops (about 60–72 seconds). Listen for clean loop boundaries, sensible musical identity, a slightly denser Challenge groove, and no accumulated tracks after repeated switching.
6. Compare Music ON/Sound OFF; Music OFF/Sound ON; both OFF; both ON. Close/reopen the app and confirm settings persist. Music OFF must silence the soundtrack.
7. At moderate speaker/headphone volume, trigger train warning, dog bark, countdown/GO, vehicle/train/water collision, coin, destination and finish. Each important cue should stay clear over music. Report any harshness, masking or overly repetitive timbre.
8. Repeat rapid switching on a slower phone and after background/resume. Inspect touch controls and landscape safe margins. Check that a normal Friends countdown still reaches GO unobstructed.

Please report the map, challenge, device and exact action if a flash remains. Music feel and platform acceptance are pending until these checks pass; this report does not claim all final acceptance requirements were physically verified.

## 13. Performance

One music player plus the existing four SFX voices; no new persistent layers/players per map. A single lightweight transition processes only while busy. Audio uses 22.05 kHz, 16-bit mono WAVs and cached loops. The four additional Challenge arrangements add roughly 6 MB of raw PCM plus import/cache overhead; no per-frame synthesis runs in the game. No heavy shader, live preview, dynamic lighting or networking changes. Physical Android memory/FPS/thermal behavior remains to be checked.

## 14. Preserved rules

Challenge definitions/rewards, score/ranking formula, map layout and difficulty, traffic timings, dog/water/train behavior, match times, characters, unlocks, destination rules and networking architecture were not changed. The only gameplay-facing changes are temporary presentation input guarding and choosing a soundtrack after initialization. Save format is unchanged.

## 15. Update ZIP

PocketCrossing_Challenge_Music_Update.zip contains only changed/new files relative to the previous polish checkpoint. Back up your project, close Godot, and copy the contents of its PocketCrossing folder into your existing project folder containing project.godot. Replace matching files, retain all other project files, and let Godot reimport the WAVs. No APK/EXE/PCK, signing, release work or next milestone is included.
