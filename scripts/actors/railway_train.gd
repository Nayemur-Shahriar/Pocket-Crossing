class_name RailwayTrain
extends Area2D
## One reusable original vector train per track. Damage remains in CrossingGame.
signal hit_player(player: CrossingPlayer)
var theme: LevelThemeConfig = LevelThemeConfig.new()
var visual: TrainVisualConfig
var length: float = 360.0
var direction: int = 1
var running := false
@onready var hitbox: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func configure(train_length: float, travel_direction: int, appearance: TrainVisualConfig = null) -> void:
	visual = appearance
	length = train_length
	direction = travel_direction
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length - 12.0, 36.0)
	hitbox.shape = shape
	queue_redraw()
	park()

func launch(width: float) -> void:
	position.x = -length * 0.5 - 2.0 if direction > 0 else width + length * 0.5 + 2.0
	visible = true
	running = true
	set_deferred("monitoring", true)

func park() -> void:
	running = false
	visible = false
	set_deferred("monitoring", false)

func _on_body_entered(body: Node2D) -> void:
	if running and body is CrossingPlayer:
		body.contact_cause="train"
		hit_player.emit(body)

func _draw() -> void:
	if theme.train_lights:
		ThemeArt.lights(self,direction,length,theme.light_strength)
	if visual != null and visual.is_valid():
		_draw_passenger_train()
		return
	var left := -length * 0.5
	draw_rect(Rect2(left + 3, -19, length, 44), Color(0.06, 0.12, 0.16, 0.3))
	draw_rect(Rect2(left, -22, length, 44), Color("243945"))
	draw_rect(Rect2(left + 3, -19, length - 6, 38), Color("d6ddd2"))
	draw_rect(Rect2(left + 3, 9, length - 6, 7), Color("dc7547"))
	for x in range(int(left + 12), int(length * 0.5 - 25), 36):
		draw_rect(Rect2(x, -14, 23, 16), Color("385e70"))
		draw_line(Vector2(x + 2, -12), Vector2(x + 18, -12), Color("8fb5be"), 2)
	for x in range(int(left + 70), int(length * 0.5 - 20), 90):
		draw_line(Vector2(x, -21), Vector2(x, 21), Color("243945"), 4)
	var nose := direction * (length * 0.5 - 12)
	draw_rect(Rect2(nose - 7, -17, 14, 33), Color("d69b4b"))
	draw_circle(Vector2(direction * (length * 0.5 - 4), -11), 3, Color("fff1bc"))
	draw_circle(Vector2(direction * (length * 0.5 - 4), 11), 3, Color("fff1bc"))

func _draw_passenger_train() -> void:
	# Fixed collision envelope, variable coach count. All modules face right in assets.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1))
	var engine_length := minf(92.0, length * 0.4)
	var coach_count := maxi(1, ceili((length - engine_length) / 112.0))
	var coach_length := (length - engine_length) / coach_count
	for i in range(coach_count):
		draw_texture_rect(visual.coach_texture, Rect2(-length*0.5+i*coach_length, -25, coach_length, 50), false)
	draw_texture_rect(visual.engine_texture, Rect2(length*0.5-engine_length, -25, engine_length, 50), false)
	draw_set_transform(Vector2.ZERO)
