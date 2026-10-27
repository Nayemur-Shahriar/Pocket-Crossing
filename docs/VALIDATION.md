# Phase 2 verification — 2026-09-24

135 regression checks passed, 0 failures, using Godot 4.5.2 Standard/GDScript.
Fresh resource import and standalone exported PCK launch completed without
script/resource errors. Four landscape size checks passed. Actual rendered
screens were reviewed. The software driver reports unsupported V-Sync only.

See PHASE2.md, PHASE2_TEST_RESULTS.txt and PHASE2_RENDER_RESULTS.txt.
Native Windows/Android builds and physical Android performance are not
verified by these Linux tests and must be checked on the target devices.

Previous reports below are retained as history.

---

# Phase 1 verification — 2026-09-23

**135 checks passed, 0 failures** using Godot 4.5.2 Standard/GDScript.
The final run has no script or physics errors. See PHASE1.md and
PHASE1_TEST_RESULTS.txt for scope, tuning and device acceptance checks.
Rendered gameplay, hop, impact and modal screens were inspected.
Physical testing of the updated Android/Windows builds is still required.

Previous validation reports follow for history.

---

# Mobile controls verification — 2026-09-23

The focused controls update passes **80 integration checks, 0 failures** in
Godot 4.5.2 Standard/GDScript on Linux. No script or physics errors occurred
in the final test run. See MOBILE_TEST_RESULTS.txt and MOBILE_CONTROLS.md.
Tests cover native synthetic touch events, all button/swipe directions,
two-thumb releases, canceled touches, pause reset, thresholds, mode switching,
all WASD/arrow mappings, simulated safe-area insets and the original gameplay
regression checks.

Rendered layout bounds passed at 1280x720, 1920x864, 960x720 and 800x360
window sizes using Compatibility / Mesa llvmpipe. The game canvas preserves
16:9, so captured viewport PNGs exclude the letterbox bars. The 1280x720 and
smallest renders were visually reviewed. The render log contains only the
software driver's unsupported V-Sync warning, not a game error.

The user reported that the baseline game works on Windows and Android.
The updated APK still requires physical device testing; it has not been
exported or installed on a phone in this environment.

The following report records the original baseline validation. Its screenshots
and 44-test count predate the split-controls update.

---

# Validation report

Validated on **2026-09-20**, using **Godot 4.5.2.stable.official.6ce3de25a**, Standard/GDScript, in a Linux execution environment.

## Completed checks

| Check | Result |
| --- | --- |
| Fresh project import without an existing `.godot` cache | Passed; assets imported and scripts registered without errors |
| Main scene headless launch | Passed |
| Gameplay integration suite | **44 passed, 0 failed**, no script or physics errors in the final run |
| Actual Area2D collisions, including a fatal collision | Passed |
| Windows-preset resource-pack export | Passed |
| Standalone launch from the exported `.pck` | Passed; scene and dynamically loaded audio resolve correctly |
| Main menu, gameplay, pause, game-over, and level-complete rendering | Rendered and visually reviewed at 1280 × 720 |
| Screenshot rendering backend | Compatibility / Mesa llvmpipe software OpenGL |

The assertion output is included in `TEST_RESULTS.txt`.

## What the automated suite covers

Initial menu; fresh score/lives/time; four alternating traffic lanes; movement in both directions; pause and resume; keyboard movement; board limits; scoring without row farming; top-edge destination restrictions; actual vehicle collisions; damage debouncing; respawn pause/resume; spawn protection; all-lives-lost and timeout endings; one-hop swipe interpretation; swipe release over UI; on-screen button taps, holds, and releases; all four destinations and duplicate-claim rejection; completion bonuses; best-score persistence; frozen end-state clock; complete replay reset; focus-loss pausing; and Android Back notification handling.

Traffic is deliberately disabled in selected movement/destination tests to isolate those rules. Separate tests exercise real vehicle movement and physics collisions. Synthetic input events test the input logic and UI button route; they do not replace testing a physical phone.

## Screenshots

The files in `screenshots/` are captured from the actual Godot renderer. The capture helper stages the two terminal screens with consistent example state to inspect layout. The integration suite separately reaches those outcomes through the game rules.

```sh
godot --path . tools/capture_preview.tscn
```

Screenshot capture needs a display; it cannot run with `--headless`. The helper temporarily uses a separate preview profile and restores your normal preferences.

## Not yet validated

- Windows `.exe` export or execution on physical Windows hardware.
- Android `.apk` / `.aab` export, signing, installation, or physical touch/haptics.
- Hardware frame rate, GPU compatibility, audio-device output, screen cutouts, and device-specific safe-area layout.
- Godot versions other than 4.5.2.

The source and both platform presets are provided. Native platform binaries are not included. Follow `EXPORTING.md` to build and perform the device acceptance checks.
