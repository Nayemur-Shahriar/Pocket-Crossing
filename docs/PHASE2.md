# Phase 2 — Visual upgrade

## Install into the working Phase 1 project

Close Godot and back up your project. Extract PocketCrossing_Phase2_Update.zip
into the project root containing project.godot; merge folders and replace
matching files. Reopen Godot 4.5.2, wait for the SVG/script imports, then run F5.
Export a new APK using your existing working Android preset.

This patch expects Phase 1. It contains no project.godot, export_presets.cfg,
keystores or editor settings. Your local Android setup is preserved.
The full project ZIP is also updated, but applying the patch is the best way
to retain your local export configuration.

## Completed visual work

- Original car, delivery truck, courier and tree SVGs with consistent shading.
- Window reflections, trim, lights and baked vehicle shadows within unchanged dimensions.
- Small tiled asphalt, staggered pavement and grass surfaces.
- Cleaner lane markings, segmented curbs and raised median stepping stones.
- Refined destination panels, highlight edges, checkmarks and six brief success sparkles.
- Player ground shadow that responds to the existing hop height.
- Shared visual palette, separate score/time/lives cards and heart-shaped life display.
- Raised buttons with borders, shadows and pressed/hover feedback.
- Existing Phase 1 hop, landing, collision effect and smooth modal transitions retained.
- Existing split controls, swipe controls, safe areas and landscape scaling retained.

No gameplay, traffic, input, scoring, timing, lives or progression changes.
The existing van vehicle is presented as a compact delivery truck; no new
vehicle system or collision shape was introduced. Phase 3 has not started.

## Changed files

Art: assets/art/car.svg, van.svg, courier.svg, tree.svg;
new asphalt.svg, pavement.svg and grass.svg.
Scripts: scripts/world/board_art.gd, scripts/world/destination.gd,
scripts/actors/player.gd (shadow drawing only), scripts/ui/game_hud.gd
(cosmetic styling), new scripts/ui/visual_style.gd and UID.
Support: tools/generate_visual_assets.py, tools/capture_mobile.gd,
assets/ART_DIRECTION.md, Phase 2 documentation/test logs, VALIDATION.md
and refreshed screenshots.

Asset dimensions, tint rules, palette location and replacement guidance:
assets/ART_DIRECTION.md.

## Verification

- Godot 4.5.2 Standard/GDScript, Linux: 135 checks passed, 0 failed.
- Clean resource import: no missing resources or script errors.
- Actual rendered gameplay, hop, impact, menu, pause and terminal screens.
- Layout checks at 1280x720, 1920x864, 960x720 and 800x360.
- Windows-preset PCK export and standalone Linux headless pack launch.
  This validates packaged resources; it is not a native Windows EXE test.

The restored Phase 2 work was reverified after its temporary working directory
was lost during the interruption. The visual design matches the previously
completed implementation.

## Performance scope

Software OpenGL counters in PHASE2_RENDER_RESULTS.txt show 187–190 draw calls
for the sampled gameplay frames and approximately 6.3–15.9 MiB reported texture
memory, including renderer/framebuffer allocations. These are not Android FPS
measurements. Small imported assets, cached scenery, no expensive shaders and
bounded effects keep this pass lightweight.

The updated APK still needs physical-device testing. No native APK or EXE is
included; use your established local export workflow.

## Test manually on Android

1. Check player/vehicle outlines, road contrast and numbered destinations.
2. Check score, timer, hearts and button labels on your actual small screen.
3. Tap/hold/release both split-control groups and swipe all four directions.
4. Check cutouts/navigation margins and the phone's landscape aspect ratio.
5. Take a hit, respawn, claim destinations and complete/replay the level.
6. Pause/resume and switch apps while touching controls.
7. Play several full rounds; look for stutter, heat and battery drain.
8. Confirm the new sprites still feel consistent with collision boundaries.

On Windows, check WASD/arrow controls and button hover/pressed appearance.
