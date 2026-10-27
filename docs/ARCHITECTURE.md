# M9 world extension

See LONG_LEVELS_M9.md for the current runtime contract, bounds, tests and authoring example.
The compiler still owns deterministic section rows. `LevelCamera` derives vertical bounds
from Start/Destination and applies a smoothed dead zone. `SectionActivation` keeps existing
hazard/pickup nodes and suspends distant simulation. `LongLevelTerrain` draws only nearby
rows, using existing textures. `RoadLevel` wires these components to the original systems.

Physics order is camera (-40), activation (-30), water (-20), support (-10), player (0).
Player spawn notifications immediately reset the camera/window. Collision feedback converts
world position into HUD coordinates; CanvasLayer controls do not follow the camera.
Road/rail effect scale is propagated only when its value changes. Original Level IDs and saves
are unchanged, and the five campaign Resources are byte-identical to the uploaded project.

# M8 Water extension

Read WATER_M8.md for current water configuration and behavior. Water sections now instantiate
WaterLane pools plus one WaterSupport adapter in RoadLevel. Optional player callbacks validate
landing before scoring/buffered input and preserve fractional X while hopping onto water.
Platform physics precedes support motion and then the player's existing hop. Water hazards
reuse CrossingGame's collision/lives/shield handler; protected falls return to spawn.
Road/rail slowdown does not affect water. Water is supported; M9 removes the former seven-row runtime gate.

The following sections describe the retained M6/M7 and progression foundations.

# Section architecture extension

Read RAILWAY_M7.md for railway authoring and SECTION_ARCHITECTURE.md for the M6 foundation. The Phase 4
systems below remain in use; there is no second player/world/progression system.

LevelConfig.sections (ordered LevelSectionConfig resources) is optional. When
empty, the existing flat config is used unchanged. When populated, section-local
lane and obstacle data is compiled into a transient runtime config by
SectionLayoutCompiler. CompiledLevelLayout retains section spans, safe rows,
source resources, validation errors and runtime feature requirements.
RoadLevel uses this runtime config to build its existing TrafficLane and
DestinationZone components. SaveData still keys progress by the same level_id.

LevelThemeConfig remains separate presentation data. RoadLevel reads compiled
railway descriptors to build RailwaySection -> RailwayTrack -> RailwayTrain /
RailwaySignal components. The existing collision signal leads to CrossingGame's
single shield/lives handler. RailwaySection guarantees a shared safe window,
while each track owns its configuration and warning clock. One train is reused
per track. All simulation inherits world pause; Slow Traffic scales train motion.
WaterLaneConfig now drives the M8 runtime. M9 supplies camera follow and activation.

# Architecture — Phase 4

One game controller and one world scene serve all five existing level resources.
No per-level gameplay scripts are duplicated. The original routes retain their fixed framing;
section routes may now scroll and include M7 rail/M8 water. Weather remains out of scope.

## Responsibilities and interfaces

| Component | Responsibility |
| --- | --- |
| CrossingGame | Authoritative run state, lives, score, timer, result and UI orchestration |
| LevelCatalog / LevelConfig | Campaign order, stable level IDs and editable route/reward rules |
| InputRouter / TouchDirectionButton | Existing WASD/arrows, split buttons and one-hop swipes |
| CrossingPlayer | Existing ground collision, animated grid hops and optional cosmetic texture/shield ring |
| RoadLevel | Shared world factory; legacy/section config, hazards, goals, safe reward sites, camera and activation |
| RewardField | Bounded pickup instances keyed by opaque IDs, with caller-supplied world positions |
| RewardPickup | Lightweight icon and bounded pickup burst; no save or movement logic |
| PowerUpConfig / PowerUpController | Resource-defined effect parameters; active timers, shield charge, multipliers |
| TrafficLane | Existing spacing/ramp/pattern rules plus a shared temporary speed factor |
| SaveData | Typed profile migration, wallet, cosmetics, stars, completion and scores |
| CharacterCatalog | Stable cosmetic IDs, prices and original texture references |
| GameHUD | Display wallet, effects, ratings and character selection; emit user intents |

## Layout-independent progression

SaveData uses arbitrary stable level IDs as dictionary keys, not array slots or
hard-coded names. Unknown level IDs survive loading. Campaign order is consulted
only to decide whether the preceding route is completed. Keep released IDs stable.
Star calculation uses only completion, remaining time and lives; it does not inspect
roads, tracks or coordinates. The LevelConfig exposes editable thresholds.

RewardField.setup(sites, coin_count, power_ups) accepts a list of dictionaries:
`{"key": <unique stable-within-run value>, "position": Vector2(...)}`.
It knows nothing about lane counts, screen bounds or the five current routes.
RewardField.take(key) removes the collectible before returning it, so repeated
callbacks cannot duplicate it. CrossingGame handles the bank/effect transaction.

The existing RoadLevel.reward_sites() adapter supplies valid cells on safe rows,
excludes spawn/obstacles/destinations, and respects the current board HUD. Only this
adapter knows the current screen geometry. The existing completed-hop callback
provides the cell key. A future world can supply its own safe positions and pickup
keys/events without changing wallet, character ownership, stars or save schema.
This is an integration boundary, not an implementation of a future world.

## Effects

PowerUpController owns no nodes or layout. CrossingGame advances it only during
PLAYING/RESPAWNING, so pause/focus loss freezes durations. Each effect has a bounded
resource duration; a repeated type refreshes instead of stacking. All effects end
on retry, return to selection or terminal result. Shield consumes one charge and
grants short hit grace. Slow traffic sets one lane-wide factor for existing and
new vehicles; conservative original spawn spacing remains. Reward multipliers
apply to forward/destination points and collected coins, not completion bonuses.

## Persistence

The existing `user://profile.cfg` gains version 2 fields. Old high scores, completion,
sound and vibration remain. Coins/stars/cosmetics are typed and bounded on load.
Save writes `.tmp`, keeps the previous parseable profile in `.bak`, then renames the
temporary file over the main profile. Missing/truncated main files fall back to
`.bak`, then defaults. Invalid individual values receive safe defaults/clamps.
A backup may predate the latest successful action. Purchase failure rolls back
wallet/ownership/selection in memory and reports a failure in the character UI.

## Rendering and platform scope

The 1280x720 landscape canvas, aspect-preserving scale, Compatibility renderer,
existing input actions, player/vehicle shapes, art and audio remain. New skins are
small original SVG recolors. Pickups are drawn primitives (at most 12 coins and
three power-ups), with brief five-dot/ring bursts and no shaders or extra physics.
Menus use scrolling containers. PC and Android export presets are not modified.
See PHASE4.md for actual validation and remaining device checks.
