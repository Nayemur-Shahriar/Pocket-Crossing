# Split mobile controls update

## Apply to your working project (recommended)

1. Close Godot and keep a backup of your working PocketCrossing folder.
2. Extract PocketCrossing_MobileControls_Update.zip.
3. Copy its scripts, tests, tools and docs folders into your existing project
   folder (the folder containing project.godot). Allow the listed files to be replaced.
4. Reopen your existing project in Godot 4.5.2, wait for script import, and press F5.
5. Export a new debug APK using your existing working Android preset.

The update ZIP deliberately contains no project.godot, export_presets.cfg,
keystores, or editor settings. Your device setup and Android texture-import
setting are preserved. The complete project ZIP is also updated, but is based
on the original source archive rather than your locally configured export settings.

## How to play

- Left thumb: UP above DOWN at the lower-left corner.
- Right thumb: LEFT and RIGHT side by side at the lower-right corner.
- A quick tap requests one hop.
- Intentional holding retains the original repeat behavior: a 0.22-second
  initial delay, then one command every 0.16 seconds. Player movement still
  uses the existing single-step function and buffer.
- With two buttons held, the most recently pressed direction wins. Releasing
  that thumb restores the other hold after the repeat delay, without adding
  an immediate extra hop. Releasing the older thumb leaves the newer hold active.
- Releasing outside a button or receiving a canceled touch clears its ownership.
- Pausing, respawning, changing mode, and restarting clear held input.
- Swipe anywhere on the board/start strip for one hop in the dominant direction.
  Movements shorter than 24 logical pixels are ignored. A long swipe still
  produces only one command. A touch beginning on a button never becomes a swipe.
- WASD, arrow keys, pause, restart, sound, physical mouse buttons/drag and
  Android Back keep their existing functions.

## Layout

A full-rect Control contains a bottom-left VBoxContainer and bottom-right
HBoxContainer. The vertical targets are 112 x 76 logical pixels, and the
horizontal targets are 112 x 84, with a 4-pixel invisible hit margin around
their existing-style button faces. Direction labels remain 34 pixels.
The controls use 24-pixel side margins and a 16-pixel bottom margin.

The original 1280 x 720 aspect-preserving canvas and landscape setting are
retained. On wider screens the existing letterboxing remains; anchors refer
to the game canvas. Android's reported safe rectangle is converted to logical
viewport coordinates, so cutouts and navigation insets move controls inward.
Physical button size depends on the device; thumb reach still needs phone testing.

## Files changed

Runtime:
- scripts/ui/game_hud.gd: split anchored containers, hit targets, safe-area
  positioning, held-button selection, and footer text placement.
- scripts/ui/touch_direction_button.gd (new): independent native touch IDs,
  mouse support, pressed visuals, cancellation and release-anywhere handling.
- scripts/input/input_router.gd: board-only swipe starts, control-mode API,
  gesture-reset signal, and optional non-immediate hold restoration.
- scripts/core/game.gd: two input/UI signal connections only.

Validation/support:
- tests/run_tests.gd: relocated button checks, native touch/multitouch,
  all swipe directions, thresholds, mode switching, keyboard mappings and
  simulated safe-area tests. Synthetic touches now explicitly use logical
  viewport coordinates. Initial traffic sampling waits for physics startup.
- tools/capture_mobile.gd and tools/capture_mobile.tscn (new): rendered layout checks.
- docs/MOBILE_CONTROLS.md (new), docs/MOBILE_TEST_RESULTS.txt (new),
  docs/VALIDATION.md (updated), plus four new mobile screenshots.
- Generated .uid sidecars accompany new GDScript files.

No player, vehicle, collision, scoring, lives, timer, destination or level
implementation changed. Input still follows HUD -> InputRouter.direction_requested
-> CrossingGame._on_direction -> existing player.request_step.

## Future Settings integration

Both input styles remain available by default. A future Settings screen can call:

    controls.set_control_mode(InputRouter.ControlMode.SPLIT_BUTTONS)
    controls.set_control_mode(InputRouter.ControlMode.SWIPE)
    controls.set_control_mode(InputRouter.ControlMode.BOTH)

The mode change resets gestures and shows/hides the split controls. Keyboard
input remains available in every mode. A Settings screen and saved preference
are intentionally outside this update.

## Phone acceptance checks

- Tap each arrow: confirm exactly one hop in the corresponding direction.
- Hold then release each arrow, including dragging off it before lifting.
- Hold two directions and release each thumb in either order.
- Swipe up/down/left/right; check tiny movements do nothing and long swipes
  never produce repeated hops.
- Start a touch on a button and drag into the road: it must not become a swipe.
- Pause/resume, switch apps, and take a hit while touching a control: no stuck input.
- Check thumb reach, bottom navigation space, camera cutouts and text visibility.
- Complete a level, restart, and confirm PC WASD/arrow controls still feel normal.

This update is source code, not a prebuilt APK. Synthetic and rendered checks
do not replace testing the updated APK on your physical Android phone.
