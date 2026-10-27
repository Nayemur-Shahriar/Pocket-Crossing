# Pocket Crossing — focused post-M14 update

## 1. Status and scope

All five requested improvements are implemented and validated. M15 has **not** started. This is a source update for the uploaded **pc M14.zip**, not a replacement project or a new milestone.

The work resumed from the inspected M14 copy. No completed M1–M14 system was rebuilt. On the final continuation, production files, assets, resources, tests and tools were byte-compared with the clean-imported, clean-tested copy: **no differences**. Only reporting and packaging remained.

### What existed before this pass

- A repeating lightweight ResultCelebration with small instant bursts, one audio voice and working high-score/cleanup guards. It had no rising rockets.
- Working WaterLane pools and WaterSupport riding/death integration. WaterSupport incorrectly killed supported riders when their **player center** left the grid-center range.
- A 15-card ScrollContainer menu showing difficulty, score, timer, target and completion metadata. No explicit card-safe touch/mouse drag ownership.
- Original M12 CNG/rickshaw textures and rectangular collision envelopes. The old broad visual generator was outside the shipped project; the shipped `generate_visual_assets.py` generates earlier artwork and was left alone.
- One shared finish-gate texture. Current campaign levels used one center goal; the underlying legacy completion callback still required **all** configured goals.
- Existing M9 camera/activation, railway, water, weather, rewards, skins and saves; all were reused.

Your uploaded archive's project/export settings and local edits to the legacy Level 5 resource, water example and water preview were retained. The 15 active campaign Resources are a separate folder from those legacy levels.

## 2. Installation

1. Close Godot and make a backup of your current M14 project folder.
2. Extract `PocketCrossing_PostM14_Update.zip`.
3. Open its **PocketCrossing** folder. Copy its contents into the existing folder containing your `project.godot`. Choose **Replace files** when asked.
4. Do not create a nested `PocketCrossing/PocketCrossing` project. This is an incremental update and cannot run by itself.
5. Reopen your existing project in Godot 4.5.2 and let the new SVGs/scripts import.
6. Use **Run Project** for the normal campaign. Your existing save remains in place.

No project settings, export settings, normal profile, APK or EXE are included in the update. Nothing needs deleting. Native builds must be exported again from your updated project.

## 3. Fireworks

`ResultCelebration` remains one Node2D with one AudioStreamPlayer. It creates one wave at a time, normally **three rockets**. Launches start at logical Y=760, below the 720-high canvas. Side corridors keep all three rising rockets visible beside the opaque results card. Different launch positions, angles, heights, local-RNG color/size variation and 0.18-second staggering distinguish the paths.

Default flight is approximately 1.15 seconds. Segmented fading trails, a bright rocket tip and small glow lead to explosions with a 205-pixel base radius, 24 primary rays, secondary sparks, a center flash, expansion, gravity and fade over 1.6 seconds. Size variation is 0.85–1.15. The next wave waits until the previous wave finishes, then waits another 0.65–1.15 seconds. At most three records exist with the supplied preset; Inspector tuning is capped at four.

The original project pop sound plays **at explosion**, never launch. One audio voice and a 0.12-second minimum separation limit overlaps and prevent catch-up spam after a stalled frame. Mute still works. Local visual RNG never changes traffic patterns.

The existing previous-best comparison is preserved. Failure, equal score and worse completion do not celebrate. Replay, Next Level, Level Select, hiding/removing the panel, restarting and scene-tree removal stop drawing/audio and clear records. Effects draw behind the opaque panel, so text and buttons remain readable.

### Inspector tuning

1. In FileSystem open `resources/presentation/celebration.tres`.
2. Tune **Rockets Per Wave**, **Rocket Travel Time**, **Rocket Stagger**, **Rocket Trail Length**, **Explosion Radius**, **Burst Lifetime**, **Rays**, **Delay Min** and **Delay Max**.
3. Burst Lifetime is the explosion lifetime. Delay Min/Max are the quiet delay **after** a wave disappears.
4. Save the Resource. Use `tools/capture_post_m14.tscn` → **Run Current Scene** for an automated visual showcase and roughly two-minute soak. It uses `user://post_m14_render.cfg`, then exits.

The showcase deliberately creates a high-score test fixture through the real result path. For an ordinary playable preview use `tools/campaign_preview.tscn` instead.

## 4. Water-edge fix

Previously, `inside_bank()` compared the player's X against grid centers 96..1184. Those are hop centers, not the edges of the visible water. A supported rider could therefore die while most of a boat was still visible.

The authoritative support half-width remains `platform.length / 2 - 18`. `supports_x()` and the new overlap test share that value. The boundary is **WaterLane's logical world width**, currently 0..1280. It does not come from desktop window dimensions. M9 scrolls only vertically and fixes horizontal framing, so this is consistent with the rendered water and camera.

- Right exit: die when `boat_x - support_half_width > lane.width`.
- Left exit: die when `boat_x + support_half_width < 0`.
- Equality and any remaining support overlap are still safe.
- Player center, boat center and decorative sprite nose do not decide the exit.

A boat carrying a supported player is pinned against pool recycling. Platforms move at physics priority -20; WaterSupport resolves at -10. Even a large timestep past the old recycle threshold cannot teleport a carrying boat first. Full exit emits the existing water hazard once, clears the pin/support, and uses normal life-loss/shield/respawn logic. The pool can reclaim it afterward. Jumping clears old support, and landing acquires the next valid deck. There is no duplicated death system.

The final focused tests cover both directions, lengths 128/176/224, speeds 60/120, partial overlap, last meaningful support pixel, large-timestep full exits, one death only, pause, Retry, near-edge platform-to-platform and platform-to-land hops, and retained pools after backtracking. Existing water routes and shield tests also pass.

## 5. Level Select

Each large, 86-pixel-high card now shows number, existing short name, stars and PLAY/LOCKED/COMPLETED state. BEST, target/reward, time limit and difficulty have been removed from each card. Results still display best score. Names and stable IDs are unchanged.

`LevelListScroll` extends the existing ScrollContainer. It owns press/drag/release before Button GUI dispatch. A vertical movement of 16 logical pixels becomes a scroll gesture, and its release can never activate a card. A short stationary tap selects the original card only if the release is still over it and it is enabled. Finger-generated mouse events are suppressed inside the list to avoid duplicate Android selections.

Mouse drag, native wheel, native scrollbar and keyboard/controller Button focus remain available. The scrollbar is optional navigation, not required. Scrolling stops on release; no custom inertia was added. Focus loss cancels the gesture. The gameplay input router is unchanged and disabled in the menu; gameplay swipes still move the player afterward.

## 6. CNG and cycle rickshaw

Two original 116×58 SVGs were revised. No outside game assets or brand logos were used.

- **Rickshaw:** distinct paired rear wheels and exposed front bicycle wheel, bicycle frame, rider/handlebars/pedals, open passenger seat, rounded teal canopy with warm decorative bands, colored passenger body and clear travel direction.
- **CNG:** compact taper toward one front wheel, green passenger shell, cream roof, dark passenger openings and warm bench, sloped windscreen, front lamp, rear lamps and mirrors. It no longer reads as the same rectangular body as a car.

Both use a simple, mirrored eight-point **convex collision outline** that narrows toward the front. The optional `VehicleVisualConfig.collision_outline` is empty for other vehicles, which retain rectangles. The existing 92×38 bounding envelope, 144 spacing envelope, visual dimensions and M13 speeds are unchanged: rickshaw 85, CNG 150 nominal pixels/second. No road spawn/gap values changed. This removes empty front-corner collision area without adding multiple physics bodies.

`tools/generate_post_m14_art.py` is the reproducible source for these two SVGs and six new finish facades. It does not rewrite other artwork. Actual physics contacts for every vehicle and both directions passed. The route predictor now uses the conservative Resource envelope instead of assuming every collision shape is a rectangle.

## 7. Destination styles and choices

`EnvironmentProfile.destination_art` is an optional Texture2D. EnvironmentLayer draws it above each existing DestinationZone, using the current theme tint. A missing art assignment keeps the old gate fallback. Ground pads remain bright and consistent across themes. Facades have a shared check-mark crest and no colliders. Nearby decorative props are kept clear of facade space.

| Levels | Environment | Finish facade |
| --- | --- | --- |
| 1 Easy Road | Green | Park entrance |
| 2 City Run, 3 Sunset Rush, 4 Night Ride, 8 Rain Run | City | Plaza/terminal |
| 5 Train Time, 10 Snow Way | Village | Courtyard entrance |
| 6 Double Track, 11 Fog Track | Railway | Station canopy |
| 7 River Hop, 9 River Rush, 12 Wild River | River | Ghat/landing |
| 13 Midnight Run, 14 Danger Zone | Highway | Roadside rest stop |
| 15 Final Crossing | Crossroads | Plaza/terminal |

All 15 current campaign levels now have **three choices at zero-based columns [4, 8, 12]**, world X positions **352, 608, 864**. Their goal-row Y still comes from the section compiler. The middle path remains available. Every goal column passes existing configuration/reachability validation.

**Any one valid goal completes the run.** The existing PLAYING guard, claim-once state and terminal-state guard protect score, timer/life bonus, target reward, stars, coins, unlocks and result panels from duplicate callbacks. The HUD now shows 0/1 then 1/1 reached. The rule also applies to legacy multi-goal test/example levels; the earlier requirement to visit every bay was intentionally replaced. All 45 campaign goal alternatives were entered using real player hop callbacks in focused integration tests. Those tests relocate the player to the final approach; separate 45 full route runs use ordinary input and real physics.

### Inspector: change destination appearance

1. Open `resources/campaign/level_XX.tres`.
2. Expand **Environment**.
3. In **Destination Art**, drag one of the six SVGs from `assets/environment/destinations/`.
4. Environment profiles are shared. To change only one level, first choose **Make Unique** on its Environment resource, or save a duplicated Environment Resource and assign it to that level.
5. Save. The layout, weather, physics and save ID do not change.

### Inspector: change finish choices

1. Open the campaign Level Resource.
2. Expand **Sections** and its last **DESTINATION_SECTION**.
3. Edit **Destination Columns** (zero-based integers). The supplied choices are 4, 8 and 12.
4. Keep columns in bounds and approach cells reachable. Do not edit the compiled runtime copy. Reaching any listed choice is sufficient.

M9 retains the existing destination nodes across activation. Backtracking does not create extra nodes, and death/Retry resets their claimed state. Short and long destination deaths, respawns and alternate entries pass focused tests.

## 8. Preserved systems and migration

All 15 names, IDs, section ordering, hazard counts, vehicle speed categories, road gaps/timing, railway warnings/timing, water sizes/timing, scoring constants, timer budgets, star thresholds and coin/power-up placement remain unchanged. The only changes inside the 15 campaign Resource files are the approved goal-column lists. Each still has at least five hazard lanes.

Camera, section activation, InputRouter, SaveData, project settings and export presets are byte-identical to your uploaded baseline. Themes/weather, character selection/unlocks, normal save format, progression IDs, shield, pause, retry and next-level navigation remain compatible. There is **no save migration or wipe**. No new campaign levels were added.

## 9. Automated validation

Godot 4.5.2 Linux, Compatibility renderer. Existing tests used isolated data directories; new focused tests use their own profile. Native hardware testing is separate.

| Existing scene | Passed assertions | Failed |
| --- | ---: | ---: |
| test_runner | 135 | 0 |
| phase3_tests | 103 | 0 |
| phase4_tests | 62 | 0 |
| section_tests | 68 | 0 |
| railway_tests | 88 | 0 |
| water_tests | 73 | 0 |
| water_route_tests | 3 | 0 |
| long_level_tests | 142 | 0 |
| long_route_tests | 2 | 0 |
| theme_tests | 109 | 0 |
| theme_route_tests | 6 | 0 |
| campaign_route_tests | 75 | 0 |
| campaign_tests | 372 | 0 |
| identity_tests | 989 | 0 |
| balance_tests | 516 | 0 |
| balance_water_routes | 5 | 0 |
| qa_validation | 353 | 0 |
| qa_contacts | 90 | 0 |
| qa_stress | 539 | 0 |
| qa_repro | Successful diagnostic/benchmark | 0 |
| qa_perf | Successful diagnostic/benchmark | 0 |

The 21 existing test scenes completed successfully: **3,730 assertions passed, 0 failed**, plus the reproduction diagnostic and performance benchmark. The reproduction diagnostic reports five `true` outcomes. The benchmark is informational, not counted as correctness assertions.

- New `post_m14_tests.tscn`: **448 passed, 0 failed**.
- Existing rendered QA, updated for the approved firework behavior: **69 passed, 0 failed**.
- Combined counted assertions: **4,247 passed / 4,247 total / 0 failed**. Repeated runs are not added to this total.
- Clean project import: no GDScript/parser errors. New focused tests repeated on that clean copy: 448/448, not double-counted.
- Static reference audit: **595 references resolved, 0 missing**.
- Windows and Android `.pck` exports succeeded and both launched the 15-level normal menu; developer scenes were excluded. This is not a native EXE/APK execution claim.
- Full real-physics campaign traversal: 15 levels × 3 seeds = 45 successful routes; at least one power-free and three-star route per level. Five existing water forward/backtrack/recross routes passed.
- Actual vehicle contact suite: 90 assertions, including all vehicle types, both directions, no duplicate death and skin/input checks.

Existing assertions were changed only where the requested contract changed: ANY goal instead of all bays, three rockets instead of two instant bursts, rate-limited audio instead of a sound for every simultaneous pop, full support exit instead of player-center exit, and convex outlines instead of assuming rectangles. The M14 memory/node comparison now samples the same retained level so differing traffic pools cannot create a false leak report.

Detailed logs are in `docs/validation_post_m14/`. Deliberate invalid/corrupt-save tests may print expected validation errors. Final logs contain no unhandled SCRIPT ERROR or parser errors.

## 10. Visual and performance verification actually performed

Rendered Linux screenshots were inspected for the simplified menu, both vehicle directions at gameplay scale, the six destination facades (including night), partial boat exits, three visible rocket trails, large explosions and unobstructed result buttons. The final rocket positions were refined so the center panel does not hide a rising rocket. See `docs/screenshots/post_m14_*.png`.

The original rendered QA also exercised six landscape sizes, all six themes, gameplay/pause/results and long-level section activation. The long-level render measured bounded active sections rather than allocating weather per section.

A rendered 120.137-second audiovisual firework run recorded 5,889 frames, at most **3** active records and a constant **159 nodes**. Samples at 30/60/90/120 seconds showed bounded memory; the test's 1 MiB growth guard passed. It produced 90 explosions and 85 rate-limited sound triggers. A separate visual soak also stayed at 3 effects and a constant 138 nodes. These are Linux software-renderer measurements, **not Android FPS predictions**. The final side-corridor placement received another rendered visual check and the same bounded lifecycle tests.

Efficiency remains lightweight: one celebration controller/voice, no particle or timer nodes, at most four Inspector-configured rockets, short fixed spark loops, no per-frame texture generation, shared SVG textures, one convex collider per revised vehicle, no added destination nodes, and direct ScrollContainer offset updates. Small dictionaries are allocated once per firework wave; drawing uses math on those bounded records.

## 11. Native Windows tests actually performed

**None.** This environment is Linux. No native Windows EXE was run. The rendered desktop checks and Windows export-pack startup above were performed, but do not establish Windows hardware qualification.

## 12. Physical Android tests actually performed

**None.** No physical phone or Android emulator was available. Android export-pack and synthetic touch-event checks passed. No new native APK was built or claimed tested.

## 13. Exact Windows manual checklist

Use your normal project after applying the update. For unlocked testing without touching the normal profile, open `tools/campaign_preview.tscn`, choose the root node's **Starting Level**, and use **Run Current Scene** from Godot's run menu. F6 is only a shortcut; you do not need that key. This preview uses `user://campaign_preview_profile.cfg`.

1. **Menu:** Run Project. Check the 15 short names/stars/locks. Drag upward starting directly on a card. It must scroll without launching. Drag back, release, then tap/click a card. Check wheel, scrollbar and keyboard focus/Enter too. A locked card must not open.
2. **Input:** After opening a level, test arrows/WASD, split controls and gameplay swipe. Return to menu and drag again; the player must not move behind it.
3. **Fireworks:** Complete a level with a genuine new best (a fresh preview profile can help). Watch three rockets rise with trails and staggered large explosions. Leave it for two minutes. Toggle sound. Test Play Again, Next Level and Level Select on separate completions. Each must stop the effect immediately. Equal/worse completion and failure must have no fireworks.
4. **Water:** Preview Level 7 or 9. Ride a right-moving boat and then a left-moving boat to the edge without jumping. Survive while any highlighted rideable deck remains within the world; full exit must remove exactly one life and respawn normally. A decorative hull tip can still be visible after its rideable deck clears. Repeat with smaller/larger boats in later river levels, and pause just before exit.
5. **Water escape:** Near each edge, jump onto a valid neighboring platform and then land. Retry while riding. Backtrack to earlier water. Check there is no stale support, teleporting carrying boat or double death.
6. **Vehicles:** In Levels 2/5, inspect CNG and cycle rickshaw going both ways. Confirm recognizable silhouettes at normal scale. With Godot Debug → Visible Collision Shapes, check the tapered collider and normal collision/life loss.
7. **Destinations:** Play Levels 1, 5 and 7 for park, courtyard and ghat; inspect 6 for station and 13 for night rest stop. All three finish pads must remain obvious. Finish Level 1 through the left pad, replay and finish through the right pad. Each alone completes the run exactly once.
8. **Long route:** Preview Level 15. Backtrack before the finish, pause, die near the end, retry and complete. Check camera bounds, three goal nodes, one result panel and saved best/stars/coins after restart.

## 14. Physical Android checklist

Export/install an updated development APK using your existing working export setup. In landscape:

- Finger-drag anywhere over cards and gaps, including starting on a card; no accidental launch. Tap afterward, test locked cards and scroll to Level 15 and back. Reopen gameplay and test split controls plus swipes.
- Earn a new high score; confirm three rising rockets, large bursts and readable buttons. Leave it for two minutes, watching frame pacing and temperature. Verify sound off and all result exits.
- Ride platforms to both edges, including small and large boats. No death on player-center exit; one normal death after the entire support interval clears. Pause/resume near an edge, jump away, retry, and backtrack.
- Check CNG/rickshaw recognizability on the phone at actual scale, both directions. Check collisions and shield.
- Compare park, village, station, river and night destination variants. Complete the same level via two different finish pads on separate runs. Confirm saved stars, scores, coins, selected character and level unlocks after closing/reopening.
- Repeat Rain/Snow/Night/Fog long routes for phone-specific visibility and performance. These systems were preserved, but physical-device qualification is still required.

## 15. Limitations and M15 readiness

No known blocker/high-severity code defect was found by this pass's checks. The source is suitable to continue toward M15 **after you review these changes and perform native device qualification**. M15 has not begun.

Remaining limitations: finite existing campaign, fixed logical 1280 horizontal world, no menu inertia, stylized placeholder art, device-dependent performance, and native EXE/APK execution still unverified here. Existing saved best scores are deliberately not reset. Any-goal completion is an intentional behavior change for legacy multi-bay examples as well as the current campaign.

## 16. File inventory

`POST_M14_FILES.txt` lists **every created and modified file** in the update, relative to your uploaded M14 archive, including tests, reproducible art sources, screenshots, logs, `.uid` and `.import` metadata. No files are deleted.

Production changes are confined to celebration/configuration, water support/pooling, menu gesture handling/captions, two vehicle visuals/colliders, destination art selection and ANY-goal completion. Campaign resources only change the three goal columns; Environment Resources only add their facade texture reference. The complete manifest is authoritative.
