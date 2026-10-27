# Pocket Crossing — final polish pass

## 1. Overall status

Presentation implementation is ready for device acceptance, not unconditional release sign-off. This update is based on the PocketCrossing.zip you uploaded on 17 October 2026. Inspection found the stable gameplay/networking implementation, but none of the interrupted polish files (SceneFade, new branding, new previews or polish tests). Those absent presentation changes were applied to your uploaded version. Existing gameplay was preserved. No release exports were performed.

## 2. Files created

- `assets/branding/LICENSE.txt`
- `assets/branding/adaptive_background.png`
- `assets/branding/adaptive_background.png.import`
- `assets/branding/adaptive_foreground.png`
- `assets/branding/adaptive_foreground.png.import`
- `assets/branding/icon_1024.png`
- `assets/branding/icon_1024.png.import`
- `assets/branding/icon_128.png`
- `assets/branding/icon_128.png.import`
- `assets/branding/icon_16.png`
- `assets/branding/icon_16.png.import`
- `assets/branding/icon_192.png`
- `assets/branding/icon_192.png.import`
- `assets/branding/icon_256.png`
- `assets/branding/icon_256.png.import`
- `assets/branding/icon_32.png`
- `assets/branding/icon_32.png.import`
- `assets/branding/icon_48.png`
- `assets/branding/icon_48.png.import`
- `assets/branding/icon_512.png`
- `assets/branding/icon_512.png.import`
- `assets/branding/icon_64.png`
- `assets/branding/icon_64.png.import`
- `assets/branding/pocket_crossing.ico`
- `assets/branding/splash.png`
- `assets/branding/splash.png.import`
- `default_bus_layout.tres`
- `docs/POLISH_FILES.json`
- `docs/POLISH_REPORT.md`
- `docs/POLISH_VALIDATION.json`
- `docs/polish_screenshots/1280x720_characters.png`
- `docs/polish_screenshots/1280x720_characters.png.import`
- `docs/polish_screenshots/1280x720_complete.png`
- `docs/polish_screenshots/1280x720_complete.png.import`
- `docs/polish_screenshots/1280x720_exit.png`
- `docs/polish_screenshots/1280x720_exit.png.import`
- `docs/polish_screenshots/1280x720_failure.png`
- `docs/polish_screenshots/1280x720_failure.png.import`
- `docs/polish_screenshots/1280x720_friends.png`
- `docs/polish_screenshots/1280x720_friends.png.import`
- `docs/polish_screenshots/1280x720_gameplay.png`
- `docs/polish_screenshots/1280x720_gameplay.png.import`
- `docs/polish_screenshots/1280x720_home.png`
- `docs/polish_screenshots/1280x720_home.png.import`
- `docs/polish_screenshots/1280x720_join.png`
- `docs/polish_screenshots/1280x720_join.png.import`
- `docs/polish_screenshots/1280x720_lobby.png`
- `docs/polish_screenshots/1280x720_lobby.png.import`
- `docs/polish_screenshots/1280x720_manual.png`
- `docs/polish_screenshots/1280x720_manual.png.import`
- `docs/polish_screenshots/1280x720_maps.png`
- `docs/polish_screenshots/1280x720_maps.png.import`
- `docs/polish_screenshots/1280x720_pause.png`
- `docs/polish_screenshots/1280x720_pause.png.import`
- `docs/polish_screenshots/1280x720_results.png`
- `docs/polish_screenshots/1280x720_results.png.import`
- `docs/polish_screenshots/1280x720_safe_area.png`
- `docs/polish_screenshots/1280x720_safe_area.png.import`
- `docs/polish_screenshots/1280x720_settings.png`
- `docs/polish_screenshots/1280x720_settings.png.import`
- `docs/polish_screenshots/1920x1080_home.png`
- `docs/polish_screenshots/1920x1080_home.png.import`
- `docs/polish_screenshots/1920x1080_maps.png`
- `docs/polish_screenshots/1920x1080_maps.png.import`
- `docs/polish_screenshots/1920x1080_results.png`
- `docs/polish_screenshots/1920x1080_results.png.import`
- `docs/polish_screenshots/1920x1080_settings.png`
- `docs/polish_screenshots/1920x1080_settings.png.import`
- `docs/polish_screenshots/2340x1080_home.png`
- `docs/polish_screenshots/2340x1080_home.png.import`
- `docs/polish_screenshots/2340x1080_maps.png`
- `docs/polish_screenshots/2340x1080_maps.png.import`
- `docs/polish_screenshots/2340x1080_results.png`
- `docs/polish_screenshots/2340x1080_results.png.import`
- `docs/polish_screenshots/2340x1080_settings.png`
- `docs/polish_screenshots/2340x1080_settings.png.import`
- `docs/polish_screenshots/640x360_home.png`
- `docs/polish_screenshots/640x360_home.png.import`
- `docs/polish_screenshots/640x360_maps.png`
- `docs/polish_screenshots/640x360_maps.png.import`
- `docs/polish_screenshots/640x360_results.png`
- `docs/polish_screenshots/640x360_results.png.import`
- `docs/polish_screenshots/640x360_settings.png`
- `docs/polish_screenshots/640x360_settings.png.import`
- `docs/polish_screenshots/960x540_home.png`
- `docs/polish_screenshots/960x540_home.png.import`
- `docs/polish_screenshots/960x540_maps.png`
- `docs/polish_screenshots/960x540_maps.png.import`
- `docs/polish_screenshots/960x540_results.png`
- `docs/polish_screenshots/960x540_results.png.import`
- `docs/polish_screenshots/960x540_settings.png`
- `docs/polish_screenshots/960x540_settings.png.import`
- `docs/polish_screenshots/transition.png`
- `docs/polish_screenshots/transition.png.import`
- `scripts/ui/scene_fade.gd`
- `scripts/ui/scene_fade.gd.uid`
- `tests/polish_tests.gd`
- `tests/polish_tests.gd.uid`
- `tests/polish_tests.tscn`
- `tests/polish_visual.gd`
- `tests/polish_visual.gd.uid`
- `tests/polish_visual.tscn`

## 3. Files modified

- `assets/maps/city_rush.svg`
- `assets/maps/night_express.svg`
- `assets/maps/river_delta.svg`
- `assets/maps/village_crossing.svg`
- `export_presets.cfg`
- `project.godot`
- `scripts/core/audio.gd`
- `scripts/core/mode_game.gd`
- `scripts/ui/competitive_results.gd`
- `scripts/ui/game_hud.gd`
- `scripts/ui/map_hud.gd`
- `scripts/ui/mode_hud.gd`
- `scripts/ui/mode_navigation.gd`
- `scripts/ui/result_celebration.gd`
- `scripts/ui/visual_style.gd`

The full exact file list is also in POLISH_FILES.json. No files need deletion. Import sidecars and UID files are Godot metadata. The update contains no Python scripts.

## 4. UI spacing changes

Shared standard buttons use 72 logical pixels in height, 14 horizontal and 8 vertical padding, and radius 12. Main-menu buttons have consistent spacing. Existing compact HUD/lobby selectors retain their deliberately smaller dimensions; character rows retain 92-pixel artwork height. Character Back is enlarged to 72 pixels. Existing mouse behavior is preserved, keyboard focus is enabled on menu buttons, touch-control faces remain non-focusable, disabled text has consistent contrast, and focus outlines are visible.

## 5. Typography and alignment

Standard buttons use 20-pixel text; compact HUD buttons use 16. Labels are vertically centered and constrained to their allocated width, using ellipsis for unexpectedly long content. Map headers no longer run into top-right navigation. Footer status width no longer overlaps crossing progress. Friends results always show RANK | PLAYER | TIME | SCORE, including Score mode; the ranking calculation itself is unchanged. Four long-name result rows were rendered and inspected. Text entry retains its existing 26-pixel font.

## 6. Map preview improvements

All four are lightweight original 512×512 SVG illustrations, replacing 240×240 previews:

- Village Crossing: warm houses, green trees, country road, small green traffic and fence.
- City Rush: varied building heights, window grid, streetlights, traffic and pavement.
- River Delta: distinct blue-green water, boats, ripples, dock and green banks.
- Night Express: moon/stars, train, track sleepers, railway signals, headlights and highway.

Map Select preserves aspect ratio. Locked previews are dimmed mildly but recognizable. Existing lobby art uses the same resources. No live scene renders are created for cards and no map layout changed.

## 7. Loading and transitions

SceneFade is one lazily created CanvasLayer per HUD. It fades out in 0.20 seconds, renders an opaque LOADING… frame, calls the pending map action once, then fades in over 0.22 seconds. Duplicate requests are ignored while busy. Cancellation clears the pending callback and hides the overlay. Local Play and result Retry use this controller. Normal menu pages use the existing 0.18-second fade-in. Escape cancels a pending local fade. Multiplayer preparation is unchanged; start_race_ui cancels any local fade before countdown, so it cannot cover GO or delay authoritative start. The controller stops processing while idle. Synchronous map loading can still hold a frame on slow hardware; it is not a threaded loader.

## 8. Music levels

Music target: -25 dB; temporary duck target: -34 dB. Existing music fade/switch and map-specific tracks remain. Only one music player is retained and four SFX voices are reused. Music and Sound remain independent persisted settings. Sound level tuning has objective gain checks, but phone/headphone listening acceptance is still required.

## 9. SFX levels

| Category | Gain |
| --- | ---: |
| Train warning, dog bark, Time Up | -11 dB |
| GO | -12 dB |
| Countdown, dog catch, water entry | -13 dB |
| Vehicle/train impacts, destination, finish and other cues | -14 dB |
| Coin | -16 dB |
| UI and fireworks | -22 dB |
| Hop | -26 dB |

Countdown and GO reuse original existing sound files. Remote-player damage routing is unchanged. Existing warning debouncing, music ducking and four-voice limit remain. A lightweight Master limiter uses -1 dB ceiling and -2 dB threshold. Largest measured post-gain hazard/UI sample peak is approximately 0.179 full scale. This and the limiter provide headroom; it is not a substitute for listening to simultaneous effects on target devices. Ambience is unchanged.

## 10. Icon assets

Original crossing-character icon with road stripes and teal/gold palette. PNG sizes: 1024, 512, 256, 192, 128, 64, 48, 32, 16. The 1024 PNG is the high-resolution source. Windows ICO includes 16/32/48/64/128/256 sizes. Android adaptive foreground/background are 432×432, with the main mark centered safely. Project and existing export preset paths are assigned. Android themed monochrome icon is not added. Actual launcher masking and Windows executable icon need validation during the separate export phase.

## 11. Splash

A 1280×720 landscape Pocket Crossing splash uses the same icon and typography. Project boot splash is assigned with filtering and matching background. It displays during normal startup, with no artificial delay. Aspect-preserving project stretching is configured. Very fast startup may show it only briefly.

## 12. Android UI findings

The HUD/menu root now fits proportionally inside the OS-reported safe rectangle; split controls remain inside that root. Synthetic notch/gesture insets passed checks. The 640×360 and wide landscape rendered layouts remain readable. The world can remain visible around an inset menu; critical menu content stays inside the safe area. No physical Android was used, so cutout APIs, thumb comfort, keyboard overlay, audio and sustained FPS need device checks.

## 13. Windows UI findings

Rendered 1280×720, 1920×1080 and 960×540 layouts are centered and readable. Wide 2340×1080 uses the preserved 16:9 content region rather than stretching the artwork. Screenshots capture the viewport, not necessarily OS window borders or letterboxing. Mouse/keyboard mapping and Escape logic remain. These renders used Linux software OpenGL; Windows DPI/fullscreen behavior remains a manual acceptance item.

## 14. Automated/static results

Final results: **1704 assertions passed, 0 failed**. Resource sweep: **334 loaded, 0 failed**. Static scan: 808 concrete resource references, no missing paths. Parser/import completed successfully. The update ZIP was also applied to a fresh copy of your upload; clean import and all 126 focused checks passed again (repeat checks are not double-counted in the 1,704 total).

Covered controls, progression/save recovery, sections, railway, water, long levels, themes, campaign, 12 complete map routes (four maps × three seeds), LAN navigation/stabilization, ranking/flow, contacts, the focused stability suite and 126 new polish checks. Separate network runs cover a three-player stability scenario and four-player competitive rounds with real countdown/time expiry and replay.

The initial map-route wall-clock timeout was resolved by using the test's deterministic fixed-FPS run. The first stability launch mistakenly supplied four peers to its three-peer scenario; its unused fourth peer timed out. The corrected final three-peer run passed. These setup failures are not counted as passes. Some harnesses report ObjectDB/resource-in-use warnings at process shutdown, including one resource in the competitive host run; these remain noted rather than being described as a perfectly clean shutdown.

## 15. Visual/manual checks actually performed

Automated real-engine captures were visually inspected: main menu, settings, map cards including locked states, characters, Friends/Join/manual IP, lobby, pause, exit confirmation, gameplay HUD, failure, completion/fireworks, four-player results and synthetic safe margins. Also inspected the 192px icon, splash, 640px map cards and wide results. Five viewport sizes were rendered. This was image-based visual review, not manual play on physical devices. Screenshots are in docs/polish_screenshots.

## 16. Physical Android tests performed

None. No connected physical phone was available.

## 17. Exact manual acceptance checklist

Windows:

1. Back up your current project, apply this update, open project.godot in Godot 4.5.2 and let import finish. Run the main scene with the Play Project button.
2. At 1280×720, then 1920×1080, inspect Main Menu, Local Play, four map cards, Character Select, Settings and Friends. Check labels, gaps, disabled state and hover/focus. Resize to an intermediate size. Check fullscreen if you normally use it.
3. Navigate with mouse, Tab/Shift+Tab/arrows and Enter. Press Escape on every menu and cancel an exit confirmation. Scroll characters to the last row and return.
4. Rapidly double-click PLAY: one map must load, with a short fade and no stuck overlay. Retry from failure and completion. Press Escape during fade and confirm navigation stays usable.
5. Play each map: five destinations, road/train/water collision, platform riding, dog warning/escape, coins, lives, timer and score. Pause/resume, retry, and return to Map Select.
6. Test Music ON/Sound OFF, Music OFF/Sound ON, both ON and both OFF. Restart the game and confirm settings persist. Listen to music, train/dog warnings, collision, water splash, coin, countdown, GO, Time Up and fireworks. Warnings should be prominent without painful volume or distortion.
7. On 2–4 actual devices on one Wi-Fi/hotspot, host/join, choose a map and rules, wait for all Ready, start, and verify the full five-second countdown and visible GO. Compare traffic and player motion. Finish at different times, test Time Up, check both ranking modes and fixed result columns, replay, change map, and test host/client leave.

Android:

1. Use your normal development build procedure (this ZIP is source, not an APK). Check launcher icon and startup splash when you next make a development export.
2. In landscape, inspect every screen above with gesture navigation/cutout enabled. Nothing important should hide behind notches or rounded edges. Test long username entry and keyboard dismissal.
3. Test split controls with both thumbs, swipe movement, pause and system Back. Confirm no accidental adjacent menu taps and no keyboard-focus highlight interfering with touch controls.
4. Inspect all four previews while locked/unlocked, scroll and select characters, and verify the 5/5 objective and HUD.
5. Repeat rapid PLAY, Retry, pause, death, completion and return-to-menu transitions; no black overlay or duplicate music should remain.
6. With phone speaker and headphones at moderate volume, repeat all audio combinations from Windows step 6. Check several nearby hazards without clipping.
7. Play Rain/Night/river/train maps for at least 10 minutes. Check heat, frame pacing, thumb comfort, dog alert visibility, fireworks and results.
8. Repeat the Friends scenario using Windows + Android and Android + Android if available. Test hotspot host and ordinary Wi-Fi. This is the remaining real-network acceptance check.

## 18. Performance findings

No dynamic lights, blur, reflections or expensive fullscreen shaders were introduced. Four 512px preview textures are roughly 4 MiB uncompressed RGBA before mipmaps/engine overhead, loaded as static assets. One three-node fade controller processes only during transitions. Music/SFX node counts remain bounded and limiter is one Master effect. Loopback stability telemetry is available, but software/headless frame timings do not predict Android FPS. No controlled before/after GPU benchmark or physical thermal test was performed; no universal performance claim is made.

## 19. Known limitations

Physical Windows/Android/audio acceptance remains. Synchronous map loading can still stutter on slow hardware. Some test shutdown warnings remain as described above. Splash timing is engine-driven; no forced dwell. Launcher/adaptive/ICO export appearance awaits separate export validation. Existing gameplay and historical issues outside this presentation scope were not redesigned. Legacy test files for removed features are retained as supplied; no PB Ghost/Records/Mastery navigation was restored.

## 20. Local Play regression

Automated controls, save/progression, sections, road/rail/water, themes and four-map routes passed. Existing map configurations and gameplay scripts remain intact. Local result/UI renders passed visual review. Physical play acceptance remains.

## 21. Friends Play regression

Three-peer stability and four-peer competitive final runs passed. Ranking/scoring, networking architecture, traffic/hazard synchronization code and match rules were not modified. Only countdown sound presentation and HUD rendering changed. Physical Wi-Fi/hotspot QA remains; loopback does not establish real-network smoothness.

## 22. Next phase readiness

Ready for user acceptance testing. Once the physical checklist passes, the project can move to the NEXT SEPARATE release/export phase. This pass does not claim final release readiness, perform signing/store submission, or start that phase automatically.

## 23. Update ZIP

PocketCrossing_Polish_Update.zip is a changed-files update for exactly your uploaded stable project. Copy the contents of its PocketCrossing folder into the existing folder that contains project.godot, replacing matching files. Do not create a nested PocketCrossing/PocketCrossing project. Keep existing assets/resources/scripts not included here. No player saves are included or changed by applying the ZIP. No APK/EXE/PCK release build or Python utilities are included. README_UPDATE.txt contains installation and quick-check steps.
