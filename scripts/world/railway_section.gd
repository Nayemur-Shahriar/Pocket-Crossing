class_name RailwaySection
extends Node2D
## Independent track clocks with a shared guaranteed quiet window between batches.
signal collision(player: CrossingPlayer)
var tracks: Array[RailwayTrack] = []
var quiet_left: float = 0.0
var quiet_seconds: float = 2.0
var was_busy := false

func setup(section: LevelSectionConfig, first_row: int, level: LevelConfig, seed_value: int) -> void:
	# At least a full section traversal plus reaction time at this level's hop speed.
	quiet_seconds = maxf(2.0, (section.railway_tracks.size() + 1) * level.hop_seconds + 1.0)
	for i in range(section.railway_tracks.size()):
		var track := RailwayTrack.new()
		track.position.y = level.cell_position(Vector2i(0, first_row + i)).y
		add_child(track)
		track.setup(section.railway_tracks[i], seed_value + i * 7919, 1280.0)
		track.collision.connect(func(body: CrossingPlayer) -> void: collision.emit(body))
		tracks.append(track)
	quiet_left = quiet_seconds

func _physics_process(delta: float) -> void:
	var busy := false
	for track in tracks:
		track.tick(delta)
		busy = busy or track.state != RailwayTrack.State.SAFE
	if busy:
		was_busy = true
		return
	if was_busy:
		quiet_left = quiet_seconds
		was_busy = false
		return
	quiet_left = maxf(0.0, quiet_left - delta)
	if quiet_left > 0.0:
		return
	# All due tracks get a full warning. No new batch joins one already passing.
	# Expired independent timers wait here instead of creating an endless blockade.
	for track in tracks:
		if track.remaining <= 0.0:
			track.begin_warning()
			was_busy = true

func set_speed_scale(value: float) -> void:
	for track in tracks:
		track.effect_scale = clampf(value, 0.1, 1.0)

func prepare_reactivation() -> void:
	# A player returning from another screen did not see the frozen warning.
	# Reuse the train and restart only busy tracks; safe independent clocks survive.
	for track in tracks:
		if track.state != RailwayTrack.State.SAFE:
			track.train.park()
			track.state = RailwayTrack.State.SAFE
			track.remaining = 0.0
			track.begin_warning()
			was_busy = true
