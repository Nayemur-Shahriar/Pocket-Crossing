class_name CelebrationConfig
extends Resource
## Presentation only. One wave; at most six rocket records.
@export_range(4, 6) var rockets_per_wave: int = 4
@export_range(4, 6) var rockets_per_wave_max: int = 6
@export_range(0.5, 2.5) var rocket_travel_time: float = 1.05
@export_range(0.18, 0.35) var rocket_stagger: float = 0.25
@export_range(30.0, 180.0) var rocket_trail_length: float = 100.0
@export_range(100.0, 280.0) var explosion_radius: float = 205.0
@export_range(0.8, 2.5) var burst_lifetime: float = 1.15
@export_range(12, 32) var rays: int = 20
## Breathing gap after the last spark of the full wave.
@export_range(1.2, 1.8) var delay_min: float = 1.2
@export_range(1.2, 1.8) var delay_max: float = 1.8
