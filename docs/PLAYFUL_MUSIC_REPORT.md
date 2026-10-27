# Pocket Crossing — playful soundtrack replacement preparation

**Status: final soundtrack NOT completed. Eight final music files are still required.**
This report supersedes the previous music report for this pass. No newly generated score is being represented as accepted or final. The available tools do not include a connected music-production service; the optional integration was declined. The useful authorized fallback is implemented and tested.

## 1. Previous soundtrack problem

The previous pass strengthened bass/percussion and raised levels while retaining the same fundamental synthesized palette, short phrase structure and largely repeated drum framework. This addressed loudness more than musical personality. The user rejected the generic/serious result. Technical playback and gain checks do not establish fun, bounce or catchiness.

## 2–5. Replacement direction, map styles, tempos and palette

The new production brief is comic, bouncy, cheerful instrumental arcade music with a related rhythmic hook across all maps. Light punchy drums/claps, short bouncing bass, plucked/pizzicato/mallet notes and call-and-response phrasing form the common family. Sparse whistle or brass-like accents are optional; warning-like sounds must be avoided.

| Map | Proposed BPM (not a delivered asset measurement) | Proposed musical character |
| --- | ---: | --- |
| Village Crossing | 114 | Warm rural bounce, hand percussion, comic plucks and occasional flute reply |
| City Rush | 124 | Busy funny arcade groove, quirky synth, rubbery bass, light punchy drums and claps |
| River Delta | 118 | Active boat-jumping adventure, marimba/xylophone, interlocking woody percussion and plucks |
| Night Express | 122 | Bright night arcade pulse, bouncy electronic bass and playful short-note lead |

32-bar arrangements should establish personality immediately and vary across main groove, variation, alternate phrase and return. Full composition/delivery instructions are in `assets/audio/playful/ASSET_REQUIREMENTS.md`.

## 6. Music volume and mixing

Dedicated Music bus set to **-14 dB provisionally**, 2 dB above the prior update. At steady state the player's gain is 0 dB. This is NOT a final listening-calibrated volume because the replacement files do not yet exist. Source delivery target is approximately -18 LUFS integrated, maximum -1 dBTP, followed by actual game/device balancing.

The previous music-only 5 dB critical-cue ducking and attack/recovery behavior are retained. No SFX files, voice allocation, cue gains, trigger logic or fireworks files are changed in this pass. No normal/challenge gain offset is applied. The Music bus cannot make missing assets audible, and louder sources alone cannot establish the requested musical quality.

## 7. Playback, loops and transitions

New typed Resource catalog provides eight slots. Existing map requests resolve through their legacy names to the replacement slots without editing maps or gameplay callers. Startup uses Village. Empty normal slots return silence; the rejected tracks are not automatically reused. The manager prints the pending slot names to the developer console, without adding any UI.

One persistent music AudioStreamPlayer remains. Re-requesting the same resolved track does not restart it. Changes use 0.35 seconds out and 0.35 seconds in, swapping at silence, with no simultaneous full-volume tracks. Starting from an empty slot fades in directly. A missing destination slot fades the outgoing music out and stops it.

WAV and Ogg Vorbis imports are supported and duplicated for runtime loop settings. WAV loops the complete sample length; Ogg loops from offset zero. Loop flags do not certify the musical seam; each supplied final recording still needs audition. Music OFF pauses; ON resumes/fades in. Missing-slot handling does not rewrite the saved preference. SOUND remains independent.

## 8. Challenge behavior

Each map has a separate challenge slot at the same proposed BPM and loudness, intended for extra hand percussion, syncopation or a light rhythmic counterline. Until that slot is filled, its assigned normal track may play without a restart. This interim fallback is documented and does NOT meet the final challenge-excitement requirement. If both are empty, music stays silent.

## 9. Asset/source/license status

All eight final filenames and individual statuses are listed in ASSET_REQUIREMENTS.md. Every one is **missing, with source and license pending**. No new audio asset or third-party licensing claim is included. Legacy files remain untouched on disk, with their existing project-supplied provenance, but are not selected for runtime music by this catalog. Do not accept a supplied file until its origin and distribution permission are documented.

## 10. Tests actually performed

Godot 4.5.2, headless Linux:

- Editor/import completed with no script parse errors.
- Focused runtime suite: **150 passed, 0 failed**, using silent in-memory WAV fixtures and a temporary silent Ogg fixture, not proposed soundtrack assets.
- Exercised all four actual map selections repeatedly and all four actual challenge selections; checked mapping, missing slots, normal-track challenge fallback, same-track continuity, player count, cache bound, fades, gain, null-track stop, warning duck/recovery and independent settings.
- Checked that toggling MUSIC retains the same UI overlay instance and opacity. This is an object-state check, not rendered-device visual certification.
- Confirmed actual Ogg playback wraps past its end without stopping the player.
- Separate fresh-process settings test: **2 passed, 0 failed**; Music OFF and Sound ON persisted.
- Archive-based byte checks confirm that this pass changes no UI, gameplay, map, multiplayer, scoring/ranking, SFX WAVs, SFX cue gains or SFX trigger implementation. See PLAYFUL_MUSIC_SCOPE_CHECKS.json.

The main fixture suite emitted an ObjectDB shutdown warning and one resource-in-use exit diagnostic; the restart test completed without those diagnostics. Assertions passed; that shutdown diagnostic is disclosed, not claimed fixed.

The earlier pass's 898 assertions are not counted for this new catalog. No final-track listening, perceived-volume measurement, musical-quality acceptance, or several-minute map playtest has been performed. There are no final tracks to audition yet.

## 11. Physical Android/laptop acceptance still required

After all files are supplied and assigned:

1. Play each map and its Challenge version for at least three minutes at a normal comfortable phone/laptop volume, then repeat on another session. Reject any track that fails fun, bounce, energy or arcade character.
2. Check the first few seconds for immediate rhythm/personality; confirm 32-bar variation is catchy without becoming irritating over repeats.
3. Listen across several complete loops for silence, clicks, abrupt harmony/tail cuts or unwanted restarts.
4. Trigger dog alert/bark, train warning, countdown, GO, impacts, water splash, Time Up and important UI feedback. Every important cue must stay clear. Lower/reshape music as needed rather than changing the protected SFX.
5. Repeat map → menu → another map → challenge → another map. Check smooth fades and absence of layered duplicate music; check playback while popups appear.
6. Toggle MUSIC/SOUND independently, during play and pause; restart the app and confirm preferences. Inspect the rendered screen for glitches.
7. Confirm Android playback performance, memory and mono-speaker balance with the final encoded assets.

## 12–13. Files and update ZIP

Modified in this pass only:

- `scripts/core/audio.gd`
- `default_bus_layout.tres`

New:

- `scripts/data/playful_music_catalog.gd` (and Godot UID metadata)
- `resources/audio/playful_music.tres`
- `assets/audio/playful/ASSET_REQUIREMENTS.md`
- `tests/playful_music_slots_tests.gd` / `.tscn` (and any UID metadata)
- `docs/PLAYFUL_MUSIC_REPORT.md`
- `docs/PLAYFUL_MUSIC_SCOPE_CHECKS.json`
- `docs/PLAYFUL_MUSIC_TEST_LOGS.txt`
- `docs/PLAYFUL_MUSIC_FILES.json`

The ZIP is an architecture/asset-preparation update, not a finished replacement soundtrack. Applying it makes unfilled music slots silent. It works with the uploaded PocketCrossing(3) project or the previous music update; no previous audio asset update is required. The ZIP does not include or alter previous fireworks/UI changes. No next milestone has been started.
