# M10 — Theme and Weather

## Installation and quick preview

This is an incremental update for the completed M9 project, not a standalone project. Back up your project, close Godot, extract the ZIP into the folder containing `project.godot`, and merge/replace matching files. Reopen Godot and let it import. No files need deleting. No save migration is required.

Open `tools/theme_preview.tscn` and click **Run Current Scene** in the editor toolbar (F6 is optional). The footer dropdown switches Day, Evening, Night, Rain, Snow and Fog on the same running 24-row layout. It contains Road, Safe, Railway, Water and Destination. Switching appearance does not restart gameplay. The root's **Preview Theme** property sets the initial theme. This preview uses `user://section_preview_profile.cfg`, not the normal campaign profile. Run Project still opens the original five-level campaign.

## Work found and work finished

On resuming, the M10 Resource extension, six presets, presentation components, gameplay integration, preview, automated tests and rendered captures were already implemented. These were preserved. Remaining work was final validation, rerunning an incomplete long-level regression log, import/package checks, documentation and delivery. No M11 work was started.

## Architecture

`LevelConfig.presentation` references the existing, extended `LevelThemeConfig` Resource. Layout sections and all gameplay parameters remain separate. Legacy fields and defaults remain compatible. A null Resource or a loaded Resource with invalid values resolves to default Day. A deleted `.tres` referenced by a level can still prevent Godot loading that level; repair broken file references in the editor.

`RoadLevel` owns one `WorldPresentation`. It applies the Resource to classic board art, long-level terrain, road vehicles, railway tracks/train, water lanes, destinations and player presentation. The owner contains one `WeatherEffects` and one `AtmosphereHaze`; streamed sections never create their own weather. Applying a theme updates these existing nodes.

`ThemeArt` shares inexpensive wet-road/snow-edge details and vehicle/train light drawing. Lights use drawn shapes, not dynamic lights or shadow maps. Selected characters use the same optional contrast aid. Theme configuration never changes collision, traffic timings, platform speed, damage, scoring, RNG, camera bounds or saves.

## Included presets

| Resource | Visible treatment |
| --- | --- |
| `resources/themes/day.tres` | Existing bright baseline, natural terrain, clear visibility |
| `resources/themes/evening.tres` | Warm terrain, sunset palette, contrasting water, mild lights |
| `resources/themes/night.tres` | Dark cool terrain, brighter markings, headlights, visible goals/player |
| `resources/themes/rain.tres` | Cool wet roads with streaks, distinct blue water, falling rain |
| `resources/themes/snow.tres` | Cool bright terrain, snowy edges, falling snow, open blue water |
| `resources/themes/fog.tres` | Muted environment and gentle distant haze; hazards remain clear |

Day's existing Resource is unchanged; five new preset Resources reuse the same configuration class. These are environment palettes plus surface treatment and effects, not just colored full-screen rectangles.

## Exact Inspector steps: assign a theme

1. Stop the running game.
2. In FileSystem, select a Level Resource, for example `resources/examples/long_crossing_demo.tres`.
3. In Inspector expand **Section architecture**.
4. Drag `resources/themes/night.tres` into **Presentation**.
5. Save and run the level. For this example, open `tools/long_level_preview.tscn` and use Run Current Scene.
6. Assign `rain.tres`, `snow.tres` or another preset in the same field to reuse the identical layout.

The legacy **Theme** field identifies an older environment category; it is NOT the M10 preset selector. **Time Of Day** inside a theme is descriptive metadata; selecting Night there alone does not set an entire night palette. Assign the full Night Resource.

The dedicated `theme_preview.tscn` deliberately overrides the example's Presentation with its own **Preview Theme** and live dropdown. Use that workflow to compare presets; use `long_level_preview.tscn` to test the Level Resource's saved assignment.

## Exact Inspector steps: tune weather

1. Select a preset in FileSystem. To avoid altering every level that shares it, duplicate the Resource file first and rename it (for example `my_rain.tres`).
2. Open its **Weather — visual only** group.
3. For rain, set **Weather = Rain**, **Weather Intensity** between 0 and 1, and **Particle Amount** between 0 and 240. Snow uses the same fields with **Weather = Snow**.
4. Active particle count is rounded `Particle Amount × Weather Intensity`. Rain defaults to 200 × 0.70 = 140; Snow to 160 × 0.65 = 104.
5. For fog, set **Weather = Fog** and tune **Fog Strength** between 0 and 0.30. Fog Strength directly controls haze; Weather Intensity scales precipitation, not fog. Haze can also accompany other weather types.
6. In **Environment**, tune **Ambient Brightness** (0.55–1.20), surface colors, **Wetness** or **Snow Coverage**. In **Readability and lights**, tune headlights and player highlight. Water colors/ripple animation are separate.
7. Save, assign your Resource to the level's Presentation, and rerun. The preview root's Preview Theme can also reference your custom Resource. Its dropdown switches back to the six bundled presets.

`Clear` means no precipitation. Editor ranges bound intensity, not the quality of arbitrary custom palettes: verify your colors remain readable on a phone.

## Weather, camera and lifecycle

Rain/snow use a fixed-size packed position pool over the visible logical playfield, following the M9 camera. Cost does not grow with level length. Particles wrap locally as the camera moves, so there is no empty newly revealed strip. Redraw is capped at 30 Hz. No materials or Resources are created every frame.

Haze uses 16 inexpensive bands, strongest toward the distant top. It is behind moving hazards/platforms; rain/snow are below player and railway signals. This deliberately favors reaction-time readability over realistic occlusion.

Pause freezes weather through the existing world process state. Retry reuses the single presentation owner and resets its pools. Death/respawn retains the assigned theme. Next Level replaces the theme. Level Select hides presentation. No theme information is written to progression saves.

## Automated validation

Godot 4.5.2 on Linux; headless checks and software-rendered captures. Test logs are in `docs/validation_m10/`.

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Core test_runner | 135 | 0 |
| Phase 3 | 103 | 0 |
| Phase 4 | 62 | 0 |
| M6 sections | 68 | 0 |
| Railway | 88 | 0 |
| Water | 73 | 0 |
| Water routes | 3 | 0 |
| Long levels | 142 | 0 |
| Long routes | 2 | 0 |
| Themes | 109 | 0 |
| Theme routes | 6 | 0 |
| **Total** | **791** | **0** |

The Phase 4 suite intentionally loads corrupt save fixtures and emits expected parse diagnostics; those recovery assertions pass. Final editor import completed without parser/script errors. All 220 literal resource references resolved. A Windows Desktop resource-pack export completed successfully (not an executable build). Theme tests cover all presets, invalid/null fallback, application to long/legacy levels, newly spawned actors, unchanged gameplay state/RNG, pause/resume, retry, death, Next Level, menu cleanup, one presentation owner and normal-profile isolation. Six real-physics route runs use normal hop requests and finish the long layout with three lives under each theme.

31 real Godot rendered captures were produced: six presets at four positions, three additional viewport sizes, and four classic-board comparisons. Road/rail/water comparisons and representative destination/classic frames were visually inspected. The six presets are visibly different, with readable hazards and goals. Captures live in `docs/screenshots/m10_*.png`. Staged screenshots are separate from the real-physics route tests.

No physical Windows or Android device test was performed here. Resource-pack validation is not an APK/EXE build or a device performance measurement.

To rerun locally, use `godot --headless --path <project-folder> res://tests/theme_tests.tscn` and the corresponding `theme_route_tests.tscn`. Existing regression scenes remain in `tests/`.

## Exact Windows manual tests

1. Apply the update to a backed-up M9 project. Import in Godot 4.5.2; confirm no script/parser errors.
2. Run Project: confirm normal Level Select and Levels 1–5; verify previous coins, stars, high scores, unlocks and selected character.
3. Run Current Scene on `tools/theme_preview.tscn`. Confirm direct gameplay and the six-option footer selector.
4. Day: play Road, Railway and Water; confirm familiar movement, collisions, warnings and platform riding.
5. Evening: compare terrain/water warmth with Day; inspect player and vehicle visibility.
6. Night: inspect each character, road markings, headlights, railway warning/passing states, water platforms and destination. Test at a lower monitor brightness too.
7. Rain: move through the whole long level and backtrack several sections. Check continuous rain, distinct wet road/water and no duplicated effects.
8. Snow: repeat the long route/backtracking. Check recognizable tracks/roads and visible moving platforms.
9. Fog: wait beside roads and railways, then plan water jumps. Confirm approaching hazards and warnings remain readable.
10. During Rain and Snow, pause for several seconds then resume. Retry repeatedly; confirm a single particle layer and correct reset.
11. Die on road, railway and water; check normal life loss/respawn and theme continuity. Test shield behavior and other power-ups.
12. Complete the route; check results, score/stars, Retry and Return to Level Select. Confirm no weather remains over menus.
13. In a temporary project copy, assign Rain to campaign Level 1 and Night to Level 2 via Presentation. Complete Level 1 and use Next Level: verify Night replaces Rain. Restore original assignments afterward.
14. Test keyboard movement and window resizing. Return to Run Project and confirm preview play did not change normal progress.

## Exact Android manual tests

1. Use a temporary project copy to create a debug preview build: set main scene to `tools/theme_preview.tscn`, remove `tools/*` from Android export exclusions, and use a distinct package ID such as `org.pocketcrossing.m10preview`. Keep production export settings unchanged. Export using your installed Android SDK/templates.
2. On a physical landscape phone, test all six presets through the footer selector. Confirm the selector and HUD fit without covering movement areas.
3. Test split-touch controls on both sides and swipe movement, including jumping onto moving platforms and backtracking.
4. Travel start-to-destination under Rain and Snow. Watch frame pacing, battery/heat and camera continuity; lower Particle Amount if your target phone needs it.
5. Test Night/Fog at ordinary phone brightness and under bright room lighting. Verify player, trains, warnings and platform edges remain readable.
6. Pause/resume precipitation, background/restore the app, retry repeatedly and die on each hazard type. Check no duplicate effects or stuck input.
7. Complete a level and return to menu. Confirm no weather covers menus. Test Next Level with different assigned themes in the temporary copy as described for Windows.
8. Test a normal campaign debug build and existing save persistence across app restart. Confirm all five routes, characters, coins, ratings and unlocks remain intact.

## Preserved and limitations

Campaign level Resources, save logic/schema, project/export settings, keyboard/touch/swipe input, power-ups, M9 camera/activation and water support were not replaced. No progression migration or final-level redesign occurred.

This milestone adds visual weather only: no slippery snow, rain penalties, lightning damage, procedural weather, animated day/night cycles or dynamic theme transitions. Weather is camera-local stylization, not a world weather simulation. Theme changes from Inspector require rerunning/reloading; only the preview dropdown provides live switching. Physical Android performance/visibility and Windows deployment still need the manual checks above.

See `M10_FILES.txt` for the exact created/modified file list relative to completed M9.
