# M14 request coverage

All statuses refer to this run. Read the full report and logs for limits; “automated” never means physical Android testing.

| Item | Status | Evidence / limitation |
| --- | --- | --- |
| 1. PRESERVE THE GAME | STATICALLY VERIFIED | All M13 Resources/assets/scenes and project/export settings byte-identical; only five production scripts changed. |
| 2. FULL PROJECT AUDIT | AUDITED + AUTOMATED | All 54 production scripts inspected; Resources/scenes loaded; asset references and lifecycle hot spots reviewed. |
| 3. GODOT OUTPUT CLEANUP | AUTOMATED | Fresh import and normal-flow logs; intentional corrupt/unwritable fixtures separated; accelerated audio shutdown warnings rechecked at normal clock. |
| 4. ALL 15 LEVELS — RESOURCE VALIDATION | AUTOMATED | campaign_tests, balance_tests, qa_validation: every level and all minimum-five-hazard requirements. |
| 5. FULL CAMPAIGN PLAYABILITY | AUTOMATED | Sequential completion/unlock/Next through all 15; 45 separately automated real-physics route completions. |
| 6. SAVE SYSTEM STRESS TEST | AUTOMATED | Phase 4 and qa_validation v2/legacy fixtures, 50 skin selections, repeated saves/reloads in soak. |
| 7. SAVE CORRUPTION / RECOVERY | FIXED + AUTOMATED | Empty primary backup recovery fixed; malformed syntax/types, missing backups, sparse progress and failed purchase tested. |
| 8. CHARACTER SYSTEM QA | AUTOMATED | All four skins, prices/purchase failures/persistence; actual texture swaps keep same body/shape. |
| 9. PLAYER MOVEMENT QA | AUTOMATED + DEVICE PENDING | Core input suite plus qa_contacts rapid 100-command buffer checks; real keyboard/touch feel still pending. |
| 10. ROAD SYSTEM QA | AUTOMATED | Every road type/direction, speed/gap checks, spawn and activation regression. |
| 11. VEHICLE COLLISION QA | AUTOMATED | qa_contacts uses actual Area2D overlap and just-outside body positions for nine types × two directions. |
| 12. RAILWAY QA | FIXED + AUTOMATED | Rail suite + streaming reentry gives full warning; pause keeps normal clock; one/two/three tracks and collision/shield. |
| 13. WATER QA | AUTOMATED + DEVICE PENDING | Water unit/integration/real routes, carrying/edges/transfer/shield; tactile phone transfers pending. |
| 14. WATER COLLISION ACCURACY | AUTOMATED + VISUAL REVIEW | M13 sizes unchanged; exact support boundary checks; rendered deck-edge review. |
| 15. CAMERA QA | AUTOMATED | Camera/clamps/backtracking/reset in long_level_tests and long-route suites. |
| 16. SECTION STREAMING QA | AUTOMATED | Retained-road/rail/water streaming, pickup/scenery/weather bounds; repeated soak relocations + genuine route backtracking. |
| 17. RETRY STRESS TEST | AUTOMATED | qa_stress ten consecutive Level 15 retries with owner/pool counts and reset assertions. |
| 18. DEATH / RESPAWN STRESS TEST | AUTOMATED | Repeated death/respawn callback bursts, plus actual road/train/water physics suites. |
| 19. SHIELD QA | AUTOMATED | Shield one-hit/grace and water rescue; existing behavior preserved. |
| 20. SLOW TRAFFIC QA | AUTOMATED | Speed ratios/restoration, duration, pause and retry/transition cleanup. |
| 21. BONUS POWER-UP QA | AUTOMATED | Double-reward scoring/coin duration, refresh and reset rules unchanged. |
| 22. COIN QA | AUTOMATED | Pickup once, immediate banking, no streaming respawn; run resets preserve existing economy. |
| 23. SCORE / BEST SCORE QA | AUTOMATED | Per-ID best, pre-save record detection, bonuses once, worse replay preservation. |
| 24. STAR QA | AUTOMATED | One/two/three-star thresholds and persistence on every campaign config. |
| 25. RESULT PANEL QA | AUTOMATED + VISUAL REVIEW | Correct successful card values, navigation, final-level no Next. |
| 26. FAILURE PANEL QA | AUTOMATED + VISUAL REVIEW | Failure no Next/stars/celebration/unlock, existing failed-run best preservation. |
| 27. CONTINUOUS HIGH-SCORE FIREWORK QA | AUTOMATED RENDERED; WINDOWS PENDING | Actual 120+ sec rendered Linux celebration, bounded nodes/bursts/audio triggers; native Windows sound/interaction pending. |
| 28. FIREWORK DUPLICATION STRESS TEST | AUTOMATED | Repeated successful record screens/exits assert one loop and immediate stop. |
| 29. THEME QA | AUTOMATED + VISUAL REVIEW | Six preset screenshots and theme regression; phone visibility still pending. |
| 30. WEATHER LIFECYCLE QA | AUTOMATED | One weather owner, pause/retry/death/next/menu/activation checks. |
| 31. BANGLADESH CONTENT QA | AUTOMATED + STATIC | Identity suite, all original Bangladesh assets preserved, five environment profiles, no decorative colliders. |
| 32. LEVEL SELECT QA | AUTOMATED + VISUAL REVIEW | 15 entries, focus-follow scroll, locks/bests/stars; six rendered sizes. |
| 33. MENU NAVIGATION QA | AUTOMATED | Repeated menu/play/pause/retry/result/next/character transitions and stale-focus protection. |
| 34. PAUSE QA | AUTOMATED | Normal movement, train warning/passing, water, effects, weather and respawn pause behavior. |
| 35. TOUCH CONTROL QA | AUTOMATED; DEVICE PENDING | Native Godot multi-touch event injection and target bounds, not physical touchscreen testing. |
| 36. SWIPE QA | AUTOMATED; DEVICE PENDING | Four swipes, threshold, release over UI, emulated mouse rejection; physical feel pending. |
| 37. WINDOWS RESOLUTION QA | LINUX RENDERED; WINDOWS PENDING | 1280x720,1366x768,1600x900,1920x1080 plus wide sizes captured and inspected; not native Windows. |
| 38. ANDROID SCREEN QA | SIMULATED; DEVICE PENDING | 1920x864/800x360 and safe-area control fixtures; actual cutouts/navigation insets pending. |
| 39. ANDROID PERFORMANCE AUDIT | LINUX PROFILE ONLY; ANDROID PENDING | Six representative level render profiles; no physical Android profiler or FPS claim. |
| 40. PERFORMANCE TARGET | PRESERVED; DEVICE PENDING | No frame target change, no unsupported device-wide promise; manual sustained frame-pacing checklist. |
| 41. OFF-SCREEN PROCESSING | STATIC + AUTOMATED | Inactive road timers/vehicles/water/rail freeze; decoration draw list bounded; fresh rail warning on reentry. |
| 42. PARTICLE OPTIMIZATION | AUTOMATED | Weather capped 240 authored maximum, screen-local pool; bounded 2-active shipping fireworks and transient effects. |
| 43. AUDIO QA | STATIC + AUTOMATED; LISTENING PENDING | Six WAVs load, below-clipping peaks, bounded voices and cue synchronization; Dummy audio cannot verify listening. |
| 44. MEMORY / LIFECYCLE AUDIT | AUDITED + AUTOMATED | Signal/deferred/Timer/Tween/await paths inventoried; no orphan increase in normal-clock lifecycle run. |
| 45. LONG SESSION TEST | AUTOMATED WALL CLOCK | 20-minute lifecycle run log; scripted navigation/reset/activation, not human continuous play. |
| 46. ANDROID APP LIFECYCLE | CALLBACK TESTED; DEVICE PENDING | Background/focus/back notifications exercised; Android OS minimize/interruption requires phone. |
| 47. DEBUG / DEVELOPMENT TOOLS | STATIC + PACKED RUNTIME | Developer scenes retained, excluded from export, no production input cheats/startup dependency. |
| 48. RELEASE STARTUP SCENE | AUTOMATED PACKED RUNTIME | Production scenes/main.tscn opens Level Select with 15 entries in both packs. |
| 49. INPUT MAP AUDIT | STATIC + AUTOMATED | All mapped movement/pause/restart/sound actions present; input settings unchanged. |
| 50. RESOURCE IMPORT AUDIT | STATIC + CLEAN IMPORT | SVG/WAV imports resolve; no unnecessary resampling or art degradation. |
| 51. FONT / TEXT QA | VISUAL REVIEW; DEVICE PENDING | Important English UI inspected at rendered resolutions; no new font dependency. Historical export description deferred. |
| 52. ERROR HANDLING | AUTOMATED | Optional theme/environment fallbacks retained; invalid core movement/numeric config now rejected with diagnostics. |
| 53. AUTOMATED REGRESSION TESTS | AUTOMATED | All existing 16 regression scenes plus targeted M14 validation/contacts/stress/render suites. |
| 54. TEST FAILURES | PRESERVED | No old regression expectations modified; new test compile issue fixed in test code before final run. |
| 55. REMOVE FALSE SUCCESS | DOCUMENTED | Every result distinguishes automated, static, screenshot review and untested native/hardware checks. |
| 56. WINDOWS MANUAL TEST MATRIX | CHECKLIST PROVIDED | Exact Windows representative levels/scenarios, exports and save steps in QA_M14.md §29. |
| 57. ANDROID MANUAL TEST MATRIX | CHECKLIST PROVIDED | Exact phone install/update/controls/levels/results/lifecycle/performance checklist in QA_M14.md §29. |
| 58. EXPORT-SAFETY AUDIT | PACKS PASS; NATIVE EXPORT BLOCKED | Both native export attempts documented: missing Windows templates and Android templates/SDK paths. Both pack/runtime audits pass. |
| 59. SECURITY / PRIVACY AUDIT | STATIC | No source credential-pattern or production absolute-private-path findings; settings preserved; not a penetration-test claim. |
| 60. PROJECT CLEANUP | CONSERVATIVE | No uncertain files deleted; final ZIP excludes cache, saves and binaries. Preview tools retained. |
| 61. OPTIMIZATION RULE | MEASURED | Only per-update redundant gap computation optimized; seven-sample benchmark and unchanged behavior regressions. |
| 62. BUG PRIORITY | DOCUMENTED | Four reproduced issues classified HIGH/HIGH/MEDIUM/MEDIUM; no broad feature work. |
| 63. RELEASE-CANDIDATE REQUIREMENTS | QUALIFICATION INCOMPLETE | No known remaining code blocker/high; native build/device acceptance gates explicitly open. |
| 64. DO NOT IMPLEMENT IN M14 | PRESERVED | No new features/content/SDKs/publishing. M15 not started. |
| 65. BACKUP / DELIVERABLE | BACKUP + UPDATE | M13 intact; separate candidate, incremental ZIP, exact file list and merge/rollback instructions. |
