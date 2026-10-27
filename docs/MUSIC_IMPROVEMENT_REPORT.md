# Pocket Crossing — focused music improvement pass

Status: implementation and automated checks passed; LISTENING ACCEPTANCE PENDING.
This is a reviewable update, not a claim that all final acceptance requirements are met.
No physical Android, laptop-speaker listening, or several-minute-per-map playtest was performed.

## Root cause

The uploaded scores measured approximately -23.6 to -25 dBFS RMS, then received -25 dB of player attenuation: about -49 dBFS in normal play. Almost every cue except hops/coins, including UI clicks, triggered -34 dB playback for 1.2 seconds. Frequent cues therefore kept the music very quiet. No dedicated Music bus existed. The music already had original map/challenge arrangements, but the bass was short and subdued, with soft accompaniment. Night ran at 128 BPM, above the requested range.

## Scores and energy

Rearranged the project's existing original synthesized scores; no external recording, song, sample pack, or commercial melody was added. These remain lightweight synthesized instruments, not recorded acoustic performances. Their subjective quality must be judged by listening; if this timbre still does not suit the game, these should not be accepted as the final soundtrack. There are no missing runtime music files.

| Map | Track | Tempo | Revised character |
| --- | --- | ---: | --- |
| Village Crossing | village_breeze.wav | 108 BPM | Warm pentatonic melody, added offbeat plucked accompaniment, stronger bass and light drums |
| City Rush | city_steps.wav | 124 BPM | Syncopated keyboard/pluck, stronger bouncy bass, tight eighth-note hats and drum pulse |
| River Delta | river_drift.wav | 112 BPM | Flowing mallets, added offbeat high mallet responses, active bass/percussion |
| Night Express | night_rails.wav | 120 BPM | Electronic pluck and minor-colored night pulse, reduced from 128 BPM |
| Menu/startup | morning_walk.wav | 108 BPM | Same revised Village score |

All tracks have 16 bars, about 31–36 seconds. Challenge files use the `_challenge.wav` suffix, the same map tempo, an added syncopated kick, existing extra arpeggios, and denser hats where applicable. Challenge energy comes from arrangement, not an extra volume boost. The bus and measured RMS are identical between normal/challenge versions.

## Levels and mixing

Music bus: **-16 dB**, routed to Master. Player: 0 dB at steady state, used only for fades and ducking. All sources matched to approximately **-21 dBFS RMS**, without clipping; typical effective music RMS is approximately -37 dBFS, roughly 12–13 dB more audible electrically than the uploaded normal mix. This is an objective level change, not a measured speaker-loudness result. No per-map runtime volume offsets.

Critical cues duck music by **5 dB**, with roughly 50 ms attack and 400 ms recovery. Hold periods vary from 0.3 to 0.85 seconds. Train/dog alerts, countdown, GO, time-up, impacts, water entry, arrival/completion are included. Ordinary UI clicks, hops, and coins do not trigger ducking. Repeated hazards extend the hold instead of restarting competing tweens.

All SFX WAV bytes and core cue playback gains are unchanged. Fireworks alone receive a permitted mixing-only lift from -22 to -16 dB on their existing player and request the same 5 dB music duck for 0.45 seconds. No fireworks visual/timing/gameplay logic changed. Existing Master limiter retained. Spectral masking and warning intelligibility remain speaker-listening acceptance items.

## Loops, transitions, lifecycle

A single persistent Audio autoload owns one music AudioStreamPlayer, plus the original four SFX voices. Switching uses 0.35-second linear-amplitude fade-out, one swap at silence, and 0.35-second fade-in: about 0.7 seconds total, with no deliberate silent hold or overlapping music players. Rapid requests settle on the latest requested resource. Requesting the same track does not restart it; panel refreshes do not create players.

Score tails wrap around the bar grid. A 2 ms endpoint correction makes the first/last PCM sample equal without changing loop duration or adding a silent gap. Music imports now explicitly use forward loops and uncompressed 16-bit PCM, avoiding lossy boundary changes. Cached looping streams are bounded to the nine score resources in normal use. PCM uses more memory than the previous compressed import, roughly 13 MB of mono source audio across all nine files; peak Android memory still needs device measurement.

Music OFF pauses immediately; ON resumes the same stream position with a fade. Changing maps while muted loads the latest track silently. SOUND remains independent. Existing profile save logic and settings UI text-only refresh are untouched; no screen rebuilding was introduced.

## Actual validation

Godot 4.5.2 headless Linux:

- Fresh editor/import: completed without parse/import errors.
- Existing challenge/transition regression suite: **292 passed, 0 failed**.
- New focused audio suite: **604 passed, 0 failed**; 96 normal/challenge swaps, bus gain, fade endpoints, same-track playback continuity, PCM loop configuration, bounded cache, single player, duck attack/recovery, muted map changes, independent music/SFX toggles.
- Separate process restart test: **2 passed, 0 failed**; Music OFF and SFX ON persisted.
- WAV analysis: all nine source files at approximately -21 dBFS RMS, no clipping, equal endpoints. Exact values in MUSIC_PASS_ANALYSIS.json and MUSIC_PASS_ASSET_CHECKS.json.
- Byte comparisons: **271 protected code/scene/resource files unchanged**, including maps, gameplay, ranking, networking, settings, project configuration. All SFX recordings unchanged.

The tests use headless playback and accelerated/manual delta checks; these are NOT listening tests, a rendered visual-glitch certification, or several-minute gameplay sessions. Godot emitted ObjectDB shutdown warnings; the existing suite reported one resource in use at exit and the focused suite ten. Assertions passed, but these exit diagnostics are disclosed and are not claimed resolved. The initial regression launch occurred before imports finished, failed to load resources, and was discarded; the successful suite was rerun after completed imports.

## Device acceptance still required

On Android and a normal laptop speaker at a normal comfortable device volume:

1. Play each of the four maps for at least 3 minutes, then its Challenge version for at least 3 minutes. Listen through several loop boundaries. Confirm the intended map feel, comfortable rhythm, and whether the melodies are enjoyable on repetition.
2. Trigger dog bark/DOG ALERT, train warnings, countdown/GO, Time Up, every impact type, river splash, coins, destination/finish, and fireworks. Every warning must remain identifiable over music. Check frequent train warnings for distracting ducking.
3. Repeat Village → menu → City → Challenge → River → Night at least five times. Confirm fades, no long gap, no restarted music on routine panels, and no layered duplicate soundtrack.
4. Toggle MUSIC and SOUND independently, including while paused and during map changes. Restart the app with Music OFF, then ON. Confirm persistence, no audible leak and no visual flash.
5. Check performance/memory after visiting all normal/challenge tracks. Confirm no device-specific stalls from PCM imports.

Do not approve final soundtrack acceptance until these listening checks pass. If the synthesized instrument quality still feels weak, a professionally produced original/licensed replacement set is the remaining creative requirement, rather than another volume increase.

## Files

Modified: default_bus_layout.tres; scripts/core/audio.gd; scripts/ui/result_celebration.gd; nine music WAVs (four normal, four challenge, morning_walk); their nine .wav.import files; assets/audio/ARCADE_MUSIC_LICENSE.txt; docs/ARCADE_MUSIC_SOURCE.txt.

Created: tools/generate_music_pass.py; tests/music_pass_tests.gd and .tscn; docs/MUSIC_PASS_ANALYSIS.json; docs/MUSIC_PASS_ASSET_CHECKS.json; docs/MUSIC_IMPROVEMENT_REPORT.md; docs/MUSIC_PASS_FILES.json; docs/music_pass_test_logs.txt.

The exact changed/new path list and SHA-256 hashes are in MUSIC_PASS_FILES.json. No gameplay, scoring, ranking, network, map, or save-system behavior was edited. No next milestone was started.
