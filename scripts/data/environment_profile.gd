class_name EnvironmentProfile
extends Resource
## Independent of time/weather and layout. No collisions or spawning rules.
@export var profile_id: String = "green"
@export var display_name: String = "Green"
@export_enum("Path", "Paving", "Bank", "Gravel") var rest_style: String = "Path"
@export var ground_tint := Color("a5b58c")
@export var safe_color := Color("c7c9a0")
@export var edge_color := Color("aa9a70")
## Optional facade above every valid finish pad; purely decorative, never collision.
@export var destination_art: Texture2D
@export var sign_caption: String = "CROSSING"
@export var props: Array[Texture2D] = []
@export var vegetation: Array[Texture2D] = []
@export_range(0.0,1.0) var prop_density: float = 0.4
@export_range(0.0,1.0) var vegetation_density: float = 0.5
@export var guard_rails := false
@export_group("Optional ambience — original/licensed audio only")
@export var music_track: AudioStream
## Optional denser arrangement at the same gain. Normal track is the fallback.
@export var challenge_music_track: AudioStream
@export var ambience: AudioStream
@export_range(-40.0,-6.0) var ambience_volume_db: float = -26.0

func is_valid() -> bool:
	if profile_id.is_empty() or rest_style not in ["Path","Paving","Bank","Gravel"]:
		return false
	if not is_finite(prop_density) or not is_finite(vegetation_density) or prop_density < 0 or prop_density > 1 or vegetation_density < 0 or vegetation_density > 1:
		return false
	for color: Color in [ground_tint,safe_color,edge_color]:
		for value: float in [color.r,color.g,color.b,color.a]:
			if not is_finite(value) or value < 0 or value > 1: return false
	for texture in props + vegetation:
		if texture == null: return false
	return is_finite(ambience_volume_db) and ambience_volume_db >= -40 and ambience_volume_db <= -6
