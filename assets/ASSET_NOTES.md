# Asset notes

All SVG drawings and the five WAV cues were created specifically for Pocket Crossing. They do not contain extracted art, logos, audio, or characters from another game.

| Asset | Source / intended replacement |
| --- | --- |
| `art/courier.svg` | Original yellow-cap courier; replace the Player Art texture |
| `art/car.svg` | Original top-down car; tintable body |
| `art/van.svg` | Original longer delivery van; separate collision width |
| `art/tree.svg` | Original layered canopy |
| `art/icon.svg` | Original 512 × 512 project icon |
| `audio/*.wav` | Synthesized original tones and hit noise |
| Scenery | Original Godot CanvasItem drawing in `board_art.gd` |
| Font | Godot's built-in fallback font; not a separately bundled font file |

To regenerate sounds, run `python tools/generate_audio.py`. Python is only needed for regeneration, not for playing or exporting the game.

The original project materials use the root MIT license. Godot and its bundled fallback font/components have their own notices. Review the engine's third-party notices when preparing a distributed binary: [Godot licensing guidance](https://docs.godotengine.org/en/4.5/about/complying_with_licenses.html).
