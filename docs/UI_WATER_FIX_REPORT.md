# Pocket Crossing — UI flash and water sound fix

Status: code fixed and automated/Linux-rendered verification passed. Final physical Windows and Android acceptance is still pending. No release/export work or new milestone was started.

Based on the latest PocketCrossing_Challenge_Music_Work project (the previously delivered Challenge/music update). The interrupted run's changes were recovered; this is the same focused bug-fix pass.

## 1. Root cause of the global UI flash

MapHUD._page removed the old panel and created the new panel with alpha 0. GameHUD._process then faded it up over 0.18 seconds. This exposed the world/HUD behind every newly constructed page. The prior Challenge fix only made that one page opaque. Settings toggles called settings_screen again, unnecessarily rebuilding the entire Settings panel and repeating the flash.

A before/after reproduction in the interrupted run measured: page alpha 0 → 1; music toggle replaced panel true → false. Scene reloading, UI theme loading and save-file reload were not the cause.

## 2. Exact UI/navigation fix

Shared page creation is immediately opaque. The shared HUD no longer animates panel alpha every frame. Same-scene panel changes are synchronous, with no await or deferred gap between removing the old panel and constructing the new one. Music, Sound, Ambience and Vibration update their existing button labels in place, retaining the current panel, input field, typed name and caret.

Sound changes from the keyboard/HUD also refresh Settings if it is open. Buttons from an already replaced ModeHUD panel cannot dispatch a stale navigation action. Existing transition-busy protection continues to reject duplicate gameplay loads. No global time-based button delay was added.

## 3. Unnecessary reloads

No actual scene reload was present or needed. Removed whole-Settings-panel reconstruction for four simple toggles. Challenge map tabs now switch panels directly without a full-screen loading fade. Renaming an account can still reconstruct Settings to display its saved/error notice, but the replacement is opaque.

## 4. Transition controller

Reused SceneFade unchanged: layer 40, 0.20-second fade-out, fully opaque swap, process/physics settling, 0.22-second fade-in. Local keyboard restart and result-primary restart now use this existing covered path, as the UI retry buttons already do. Challenge PLAY still uses it. No additional overlay, arbitrary long wait, scene controller or networking synchronization was added. Existing Friends lobby/loading/countdown ownership remains unchanged.

## 5. Files modified for UI

- scripts/ui/map_hud.gd — opaque shared map/menu pages.
- scripts/ui/game_hud.gd — remove panel fade-through; generic screen starts opaque.
- scripts/ui/mode_hud.gd — existing Settings button references and in-place labels; stale-panel action guard.
- scripts/core/mode_game.gd — in-place settings updates, direct Challenge tabs, covered local restart paths, keyboard sound refresh.

## 6. Root cause of missing water SFX

The existing centralized water death handler correctly requested water_entry. Audio's four round-robin voices could overwrite that voice with another cue, even before the mixer consumed the first samples. Four subsequent hop calls reproduced the lost splash stream. Thus a splash event could be counted while its sound was immediately interrupted. The player node did not own the sound, and respawn was not freeing it.

scripts/core/audio.gd now reserves the fourth EXISTING voice for water_entry. Other effects use the other three voices, preferring idle voices. The protected voice permits up to four overlapping tails and does not reassign its identical stream on every play. No extra AudioStreamPlayers were added. cue_played is emitted after the playback request. The original 1.15-second water-impact WAV and its volume are unchanged.

## 7. Water death paths identified

All existing local paths converge through WaterSupport.hazard → RoadLevel.water_hazard → CrossingGame._on_water_hazard:

- Empty-water landing/direct fall.
- Missing a small, medium or large deck.
- Hop between decks into a gap.
- Standing player loses support / deck moves away.
- Invalid or cleared support is rechecked by check_landing.
- Carried platform no longer overlaps the logical left boundary.
- Carried platform no longer overlaps the logical right boundary.
- Reactivation uses the same support check; no separate audio-only branch exists.

Host-authoritative Friends water damage goes through LanRace._water_hit/damage and the existing reliable owner hurt event. Remote feed messages do not request a heavy splash. No hazard, support, carrying, boundary, life-loss, respawn or network rule was changed.

## 8. Centralized flow

Preserved existing flow instead of duplicating it: accepted WATER damage → one life decrement and death record/visual → HazardAudio.play("water") → Audio.play_cue("water_entry") → normal respawn or game over. Invulnerability and shields retain their existing rescue behavior without a death splash. State/visibility guards reject repeated damage. Friends feedback uses its existing match epoch and death sequence deduplication.

## 9. Surviving respawn/cleanup

Audio is an autoload, outside the player/world subtree. The protected voice remains alive through player reset, menu navigation and game-node removal. Other cues cannot steal it. SOUND OFF deliberately stops effect voices; MUSIC OFF affects only the music player. Playback remains bounded and does not delay respawn.

## 10. Water stress test

384 accepted sound-on deaths = 384 splash events = 384 single life-loss events. Every case also checked WATER cause, splash visual, duplicate hazard rejection and normal respawn. These are deterministic tests using controlled positions/deck-size fixtures, not 384 manual crossings.

| Configuration | Deaths |
|---|---:|
| River Delta normal | 96 |
| River Delta Fast River | 96 |
| River Delta One Life | 96 |
| River Delta Double Coins | 96 |

All current maps and their allowed Challenge configurations were loaded/scanned. These four configurations contain water; all four lanes of each were exercised. Eight cases × three repeats × four lanes = 96 per configuration. Test fixtures set a high life count so even One Life can exercise all branches without repeatedly rebuilding the world; production life limits are untouched.

Four additional muted deaths produced zero splash requests. The mixer capture isolated the protected splash voice after competing cues: 7,680 sample frames, peak approximately 0.345, nonzero output. This proves mixed audio delivery, not subjective speaker/listening acceptance. Separate playback checks covered respawn, menu cleanup and game-node removal.

## 11. Settings and navigation regression

Twenty cycles of Local/Back, Friends/Back, Settings/Back, Challenge tabs/Back, Characters/Back, hosting/lobby/leave, local result/Map Select and Friends result/lobby passed. Each Settings cycle toggles Music, Sound, Ambience and Vibration three times. Button/panel/input identity and typed name/caret survive; Music/Sound values persist on save/reload. All tests use isolated user-data folders/profiles.

Rendered Linux Compatibility tests checked 1,920 menu frames (three post-draw frames per panel check) for exposed game background at menu margins, alongside immediate opacity assertions. Representative screenshots were inspected. This targets the reproduced transparency defect; it is not a guarantee against every hardware-specific graphical artifact.

## 12. Automated totals and changed test files

Fresh final headless suite: 5,663 assertions passed, 0 failed. Resource loader: 338 scripts/scenes/resources loaded, 0 failed. Four-process multiplayer: 59 assertions passed, 0 failed. Combined functional assertions: 5,722 passed, 0 failed. Render repetitions are reported separately, not added to this total.

| Suite | Passed | Failed |
|---|---:|---:|
| UI/water focused | 4,408 | 0 |
| Water gameplay | 73 | 0 |
| Refinement | 120 | 0 |
| Challenge/music transitions | 291 | 0 |
| Polish | 126 | 0 |
| Stability | 208 | 0 |
| Map campaign | 110 | 0 |
| Map depth | 138 | 0 |
| Competitive rules | 27 | 0 |
| Competitive flow | 27 | 0 |
| Core gameplay | 135 | 0 |

Rendered focused suite: 6,328 passed / 0 failed, including 1,920 frame checks. Rendered Challenge suite: 314 passed / 0 failed, including all 24 covered start/retry swaps. Settling-frame assertion counts can vary slightly with scheduling.

Tests created: tests/ui_water_tests.gd and tests/ui_water_tests.tscn.
Tests modified: tests/competitive_flow_tests.gd counts actual cue events instead of assuming a four-slot round-robin cursor; tests/refinement_tests.gd updates four stale assertions. Those assertions also failed on the untouched baseline: the old test assumed a fixed 32-second music loop and no dogs outside Village, both superseded by prior completed updates. No music or dog behavior was changed in this pass.

Clean-install check: the update was applied to a fresh extraction of the stable baseline, imported successfully, and the focused suite passed again (4,408 / 0). This repeat is not added to the totals. ZIP integrity passed; no Python files are present.

No GDScript/parser or missing-resource failures. Some pre-existing regression harnesses still report ObjectDB/resource-in-use warnings on immediate shutdown. Linux software rendering reports unsupported V-sync switching. These are disclosed rather than described as warning-free.

## 13. Windows tests actually performed

No physical Windows run in this environment. Automated runtime/render tests used Godot 4.5.2 Linux, Compatibility renderer, Mesa llvmpipe/Xvfb, with dummy audio plus isolated mixer capture. Keyboard restart routes were inspected and exercised by the existing transition tests. Physical Windows acceptance remains pending.

## 14. Multiplayer tests actually performed

Four simultaneous Godot processes, one host and three clients, connected over loopback. Host passed 17 assertions; each client passed 14. Verified authoritative life loss, duplicate-damage/hurt-event rejection, owner-only water and dog feedback, remote feed behavior, selected skin, own-character rendering, results ordering and score formula. This is real local networking, not a physical Wi-Fi/hotspot or mixed Windows/Android test.

## 15. Android tests actually performed

No physical Android run or Android export was performed. No Android-specific input, landscape settings, safe-area or networking code was modified. Existing automated UI/input regression checks passed; this does not replace device validation.

## 16. Exact device acceptance checklist

On Windows first, then on Android in landscape:

1. Repeat each route 20 times: Main Menu → Local Play → Back; Friends Play → Back; Settings → Back; Map Select → Back; Characters → Back; Challenges → each map tab → Back. Watch for an exposed world, disappearing menu, wrong page, black/white frame or flickering overlay.
2. In Settings, type an unsaved name. Toggle Music ON/OFF/ON and Sound ON/OFF/ON at least 20 times each. The name, caret and panel should stay put. Verify the labels and audio match; restart the app to confirm saved options.
3. Start normal and Challenge maps, Retry with button and keyboard R on PC, and return from results to Map Select. Double-click/tap PLAY and Retry: only one run should start. Use Escape/Android Back before and during a transition; no partial world should be exposed.
4. With Music OFF and Sound ON, make at least 20 water deaths in River Delta: direct fall, misses beside small/medium/large boats, hop into a gap, lose support, and ride off both left and right edges. Each accepted death must give one large splash, one life loss, one visual splash and one respawn. Retry as needed after game over.
5. Repeat representative deaths in Fast River, One Life and Double Coins. Keep shields/invulnerability out of death-count tests; separately check protected falls rescue correctly without a death sound/life loss.
6. With Music ON and Sound OFF, repeat a few falls: silent effects, normal music and normal life/respawn. Restore Sound ON and repeat. During audible falls, listen for the splash's turbulence tail to finish even when hopping immediately after respawn.
7. On two devices on the same Wi-Fi/hotspot, host/join, enter/leave lobby, play, reach results and return to lobby. The falling local player should hear one full splash; the other device should only show the usual remote notice. Repeat with phone as host and then PC as host.
8. On Android use both split-touch and swipe, system Back, rapid taps, and app pause/resume. Check touch targets, landscape safe areas and speaker/headphone audibility. Confirm no new stutter during menus or repeated falls.

Final acceptance requires your physical Windows/Android results, especially visible one-frame artifacts and audible splash quality.

## 17. Performance

Still four reusable SFX players and one music player. Three general voices plus one protected water voice; water overlap capped at four tails. No per-frame settings writes, extra scene copies, shaders, weather changes or long delays. Shared panel-alpha polling was removed. No device FPS/battery claim is made without hardware measurement.

## 18. Scope preserved

All world/actor/data/network scripts, map and challenge resources, save/progression code, damage/scoring logic, water WAV and music assets are byte-identical to the baseline. Rules for Local, Friends, ranking, rewards, map difficulty, dog behavior, water edges and controls were not changed. The only five production scripts changed are the UI/audio files listed above. No save migration, new feature, APK, EXE or release export.

## 19. Update ZIP and installation

PocketCrossing_UI_Water_Fix_Update.zip contains changed/new files only. Apply AFTER the previous Challenge/Music update. Close Godot, back up the project, copy the CONTENTS of this ZIP's PocketCrossing folder into your existing project folder containing project.godot, and replace matching files. Do not create a nested PocketCrossing/PocketCrossing folder. Reopen Godot and let imports finish, then run the main project.

No Python files are included in the update. The exact changed/new file list is in UI_WATER_FIX_FILES.json. The new test scene is developer tooling and does not replace the game main scene. Test tooling should be run on a copy/isolated user-data environment as it creates QA profiles and test results.
