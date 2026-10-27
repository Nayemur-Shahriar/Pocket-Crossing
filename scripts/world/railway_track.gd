class_name RailwayTrack
extends Node2D
## Driven by RailwaySection, so warning and motion share the same pause clock.
signal collision(player: CrossingPlayer)
signal warning_started
signal state_changed(state: int)
enum State { SAFE, WARNING, PASSING }
const TRAIN := preload("res://scenes/railway/train.tscn")
var theme: LevelThemeConfig = LevelThemeConfig.new()
var config: RailwayTrackConfig
var state: State = State.SAFE
var remaining: float = 0.0
var elapsed: float = 0.0
var effect_scale: float = 1.0
var width: float = 1280.0
var train: RailwayTrain
var signal_art: RailwaySignal
var rng := RandomNumberGenerator.new()

func setup(settings: RailwayTrackConfig, seed_value: int, board_width: float) -> void:
	config = settings
	width = board_width
	rng.seed = seed_value
	train = TRAIN.instantiate() as RailwayTrain
	add_child(train)
	train.configure(config.train_length, config.direction, config.visual)
	train.hit_player.connect(func(body: CrossingPlayer) -> void: collision.emit(body))
	signal_art = RailwaySignal.new()
	signal_art.z_index = 5
	signal_art.width = width
	signal_art.direction = config.direction
	add_child(signal_art)
	remaining = config.initial_delay
	queue_redraw()

func begin_warning() -> void:
	if state != State.SAFE or remaining > 0:
		return
	state = State.WARNING
	remaining = config.warning_seconds
	elapsed = 0.0
	signal_art.update_state(state, true)
	state_changed.emit(state)
	warning_started.emit()

func tick(delta: float) -> void:
	elapsed += delta
	match state:
		State.SAFE:
			remaining = maxf(0.0, remaining - delta)
		State.WARNING:
			remaining = maxf(0.0, remaining - delta)
			if remaining <= 0.0:
				state = State.PASSING
				train.launch(width)
				state_changed.emit(state)
		State.PASSING:
			train.position.x += config.speed * effect_scale * config.direction * delta
			var cleared := train.position.x - config.train_length * 0.5 > width if config.direction > 0 else train.position.x + config.train_length * 0.5 < 0.0
			if cleared:
				train.park()
				state = State.SAFE
				remaining = rng.randf_range(config.interval_min, config.interval_max) if config.timing_variation else config.interval_min
				remaining = maxf(remaining, config.safe_delay)
				state_changed.emit(state)
	signal_art.update_state(state, state != State.SAFE and fmod(elapsed, 0.6) < 0.3)

func _draw() -> void:
	draw_rect(Rect2(0, -32, width, 64), theme.surface(theme.railway_color))
	for x in range(0, int(width), 30):
		draw_rect(Rect2(x, -23, 11, 46), Color("4c5550"))
	for y in [-16.0, 16.0]:
		draw_line(Vector2(0, y + 2), Vector2(width, y + 2), Color("263c42"), 5)
		draw_line(Vector2(0, y), Vector2(width, y), theme.rail_color, 3)
	ThemeArt.surface_details(self,0,theme,false)
