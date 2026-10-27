# Pocket Crossing — selected B free music REVIEW update

## Status
Playable music integration, not final musical acceptance. City uses your selected B, Super Retro Lounge. Village, River and Night are same-publisher candidates that still need your listening approval. No claims are made that a machine measured “fun”, “bounce”, musical suitability, or audible warning clarity.

## 1. Previous problems
The original upload set music playback to -25 dB on already quiet sources (prior measurements approximately -24 dBFS RMS), and ducked most cues to -34 dB for 1.2 seconds, including UI clicks. This made sustained music very quiet. The subsequent synthesized energetic direction was rejected by you as generic/serious. Gain alone cannot fix that aesthetic mismatch.

## 2–5. Replacement direction, map identity, tempo and palette
The selected direction is cheerful retro arcade. Source category/energy descriptions below come from publisher metadata, not a claim of human audition here.

| Map | Track | Direction/palette | Duration | Tempo status |
|---|---|---|---|---|
| Village | Heart-Shaped PALPATATIONS | Bright, silly chiptune; warm playful candidate, not verified rural/folk instrumentation | 22.74 s | No publisher BPM; rough onset estimate ~95/190, ambiguous |
| City | Super Retro Lounge (chosen B) | Bright energetic chiptune; retro electronic lead/bass/percussion character | 24.00 s | Rough onset estimate ~90/180, ambiguous |
| River | Sunburn BEACH HOUSE | Bright energetic jazz-tagged candidate; rhythmic adventure direction, not verified marimba palette | 21.82 s | Unverified; no defensible BPM assigned |
| Night | Workshop BREADBOARD | Bright electronic candidate; night arcade direction | 22.59 s | Rough onset estimate ~85/170, ambiguous |

These estimates are not certified perceived tempo. The requested 110–128 BPM is NOT verified, and some sources may fall outside it. Selected B is preserved at original speed/pitch instead of being forcibly accelerated. Shared composer and bright palette support cohesion, but no recurring newly composed Pocket Crossing motif has been added. Menu retains the Village slot. Short 22–24 second loops remain a repeat-fatigue risk; they do not satisfy a long multi-section arrangement requirement by themselves.

## 6. Mix
Music bus -14 dB; steady player gain 0 dB; no per-map runtime offsets. Source target -18 LUFS, measured approximately -18.17 to -17.98 LUFS. Encoded true peaks remain below -2.7 dBTP, no decoded sample clipping. Source gain is adjusted separately for each file. Electrical level is higher than the uploaded mix; normal phone/laptop audibility is still untested. Music effective integrated level is roughly -32 LUFS before ducking; that may still require adjustment after listening.

Original gameplay SFX files, voice allocation, cue gains and routing are unchanged. Only music attenuation changes: important warnings/deaths duck music by 5 dB briefly, with smooth recovery. UI clicks/hops/coins do not trigger constant pumping. SFX source gain cannot prove perceptual audibility; hazard masking must be listened to on device.

## 7. Loop and transition behavior
One persistent music AudioStreamPlayer, full-file Ogg loop, cache bounded to eight recordings. Same-track requests keep playback position. A map change fades old music down for 0.35 seconds, swaps at silence, then fades new music up for 0.35 seconds. No overlapping full-volume players. Two-millisecond end/start shaping reduces boundary discontinuities; lossy decoding leaves small measured seam deltas recorded in JSON. No long silence was inserted. Musical seam quality/pop absence still requires headphones and speaker listening.

## 8. Challenge
Four separate challenge Ogg mixes increase the existing percussive component by 40% before loudness matching. Same source length, tempo and pitch; no runtime volume boost. This is a subtle rhythmic emphasis, not a new authored arrangement, and its musical benefit remains to be auditioned.

## 9. License
All eight files: publisher CC0; see FREE_MUSIC_CREDITS.md and assets/audio/playful/CC0_SOURCE_LICENSE.txt. Free download and permitted edits; no paid service used.

## 10. Tests actually performed
See FREE_MUSIC_TEST_RESULTS.txt for exact current runtime results. Tests use a clean extraction of the user's original ZIP plus only this patch. Audio decoded and analyzed with FFmpeg; all eight outputs nonclipping. Godot headless tests exercise actual main scene map/challenge selection, source routing, near-end loop wrapping, menu transitions, one player, bounded cache, fades, settings independence, UI overlay identity/opacity during music toggle, ducking, and preference persistence in a separate process.

No several-minute human gameplay listening sessions or physical loudspeaker tests were performed. Headless transport checks are not musical acceptance.

## 11. Android / final acceptance still required
Play each map and its Challenge mode for at least several minutes at comfortable normal device volume. Judge funny/bouncy/energetic/arcade feel, opening groove, phrase fatigue and transitions. Verify each loop with headphones and phone speaker. Trigger dog/train/countdown/GO/Time Up/impact/splash/coin/success/finish/fireworks and confirm clear priority. Exercise Map A → menu → Map B → Challenge → Map C, toggles independently, app restart with music off, background/resume, and check no visual flash/audio leak. Review memory/CPU on the target phone.

If the three unapproved candidates or short repeated phrases fail, final replacements still required are village.ogg, river.ogg, night.ogg and their matching challenge files. City may also need an approved longer arrangement of B. Prefer authored 60–90 second multi-phrase loops in the requested tempo range, not copies padded by repetition. Do not label this review build final until subjective and device acceptance passes.

## 12–13. Scope and installation
This is a patch, not an APK or full project. Back up the project, then merge the ZIP's PocketCrossing folder into the existing project folder containing project.godot, replacing matching files. Godot imports the Ogg assets on opening. Works on the supplied original project and supersedes earlier music-manager/slot patches. It does not revert unrelated earlier changes already present in your working project.

Changed existing runtime files: scripts/core/audio.gd and default_bus_layout.tres. Added/updated: scripts/data/playful_music_catalog.gd, resources/audio/playful_music.tres, eight assets/audio/playful/*.ogg files and import settings, music documentation/license, isolated test scene/script. Exact list and SHA256 values in UPDATE_MANIFEST.json. No gameplay, UI, map, multiplayer, scoring/ranking scripts or important SFX assets are included. Earlier fireworks/UI edits are deliberately excluded. No further milestone started.
