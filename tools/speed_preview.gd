extends Node2D
## Uses real TrafficLane/TrafficVehicle motion to compare cruise speeds visually.
@export_range(50,350) var lane_speed: float = 150
@export_range(0.5,1.5) var lane_modifier: float = 1.0
const IDS := ["rickshaw","large_truck","medium_truck","local_bus","delivery_van","cng","pickup","microbus","small_car"]
var lanes: Array[TrafficLane] = []
var elapsed := 0.0
func _ready() -> void:
	var title := Label.new()
	title.text = "M13 / VEHICLE SPEED COMPARISON"
	title.position = Vector2(26,18)
	title.add_theme_font_size_override("font_size",25)
	add_child(title)
	var reset := Button.new()
	reset.text = "RESTART TOGETHER"
	reset.position = Vector2(950,16)
	reset.size = Vector2(300,48)
	reset.pressed.connect(restart)
	add_child(reset)
	var rules := LevelConfig.new()
	rules.starting_speed_scale = 1
	rules.final_speed_scale = 1
	for i in range(IDS.size()):
		var config := LaneConfig.new()
		config.vehicle_types = [IDS[i]]
		config.speed = lane_speed
		config.speed_modifier = lane_modifier
		config.speed_variation = 0
		var lane := TrafficLane.new()
		add_child(lane)
		lane.position.y = 104+i*61
		lane.setup(config,13,rules)
		lanes.append(lane)
		var label := Label.new()
		label.text = "%s\n%.0f px/s" % [IDS[i].replace("_"," "),lane_speed*lane_modifier*VehicleLibrary.find_visual(IDS[i]).base_speed/150]
		label.position = Vector2(20,82+i*61)
		label.add_theme_font_size_override("font_size",16)
		add_child(label)
	restart()
func restart() -> void:
	elapsed = 0
	for lane in lanes:
		for actor in lane.get_children(): actor.free()
		lane.spawn_left = 100000
		lane.spawn_vehicle(300)
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 4.7: restart()
func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("17343e"))
	for i in range(9):
		draw_rect(Rect2(220,76+i*61,1060,58),Color("43535c"))
		draw_line(Vector2(300,76+i*61),Vector2(300,134+i*61),Color("a5c7b3"),1)
