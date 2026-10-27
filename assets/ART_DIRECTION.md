# Phase 2 visual system

Original vector artwork authored for Pocket Crossing, covered by the project's
MIT license. No downloaded, traced or third-party game sprites.

Palette: slate/teal foundations, warm cream text, amber accents, muted green
planting and coral lives. Shared UI tokens: scripts/ui/visual_style.gd.
Vehicle tint colors still come from the existing LaneConfig resources.

| Replaceable asset | SVG size | Contract |
| --- | --- | --- |
| car.svg | 116 x 58 | Faces right; neutral body tint; centered origin |
| van.svg | 140 x 58 | Compact delivery truck in the existing van slot; faces right |
| courier.svg | 52 x 60 | Existing Art offset and hop animation |
| tree.svg | 100 x 100 | Decorative only, drawn at 74 x 74 |
| asphalt.svg | 64 x 64 | Seamless low-contrast road tile |
| grass.svg | 64 x 64 | Seamless subdued grass tile |
| pavement.svg | 128 x 64 | Seamless staggered paving tile |

Vehicle shadows are baked into the small sprites. Player shadow is drawn at the
ground position and becomes smaller/lighter while hopping. Collision shapes
and vehicle types are unchanged; preserve image dimensions and footprints
when swapping assets.

Edit SVGs directly or reproduce them with:
python3 tools/generate_visual_assets.py

The generator uses a fixed seed for asphalt detail. Godot rasterizes SVGs on
import; their gradients require no runtime shaders. These seven assets total
44,352 nominal pixels, about 173 KiB RGBA before mipmaps/driver overhead.

Board placement lives in scripts/world/board_art.gd. Its background drawing
is cached; it does not redraw every frame. Curb lines use draw_multiline.
Destination sparkles are six drawn dots within the existing 0.4-second pulse.
Phase 1 hop/landing, impact and 0.18-second modal transitions remain intact.
No dynamic lights, post-processing, large textures or particle emitters were added.
