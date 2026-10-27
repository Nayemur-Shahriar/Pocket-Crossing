class_name ResultCelebration
extends Node2D
## Bounded staggered waves, one audio voice. Drawing stays behind result cards.
const MAX_ACTIVE_WAVES:=1
const COLORS := [Color("ffd46e"), Color("79eed3"), Color("ff92bd"), Color("9dcfff")]
@export var settings: CelebrationConfig = preload("res://resources/presentation/celebration.tres")
var sound: AudioStream
var elapsed := 0.0
var emitted := 0 # Actual explosions, not launches.
var waves := 0
var sound_events := 0
var finished := false
var voice: AudioStreamPlayer
var bursts: Array[Dictionary] = [] # Rocket records retained through their explosion.
var next_burst := 0.08
var rng := RandomNumberGenerator.new()
var last_sound := -10.0

func _ready() -> void:
	rng.randomize() # Does not perturb gameplay RNG.
	voice = AudioStreamPlayer.new()
	voice.stream = sound
	voice.max_polyphony = 1
	voice.volume_db = -16.0 # Mix-only lift to retain fireworks over the stronger score.
	add_child(voice)

func _process(delta: float) -> void:
	if finished: return
	if not is_visible_in_tree():
		stop()
		return
	elapsed += delta
	for i in range(bursts.size()-1, -1, -1):
		var record := bursts[i]
		var age: float = elapsed - record.born
		if age >= record.travel and not record.exploded:
			record.exploded = true
			emitted += 1
			# One voice and a rate limit also prevent audio bursts after a stalled frame.
			if sound != null and SaveData.sound_enabled and elapsed-last_sound >= 0.25:
				Audio.duck_music(0.45)
				voice.play()
				last_sound = elapsed
				sound_events += 1
		if age >= record.travel + record.life: bursts.remove_at(i)
	next_burst -= delta
	if next_burst <= 0 and active_waves()<MAX_ACTIVE_WAVES: _launch_wave()
	if not SaveData.sound_enabled and voice.playing: voice.stop()
	queue_redraw()

func active_waves() -> int:
	var previous:=-1
	var count:=0
	for burst in bursts:
		if burst.wave!=previous:count+=1;previous=burst.wave
	return count
func _launch_wave() -> void:
	if active_waves()>=MAX_ACTIVE_WAVES:return
	waves += 1
	var count := rng.randi_range(clampi(settings.rockets_per_wave,4,6),clampi(settings.rockets_per_wave_max,clampi(settings.rockets_per_wave,4,6),6))
	var born:=elapsed
	var previous_explosion:=elapsed+clampf(settings.rocket_travel_time,0.8,1.6)-0.20
	var full_end:=elapsed
	for i in range(count):
		# Side corridors keep every rising rocket visible beside the opaque result card.
		var x: float = [175.0,1105.0,110.0,1170.0,230.0,1050.0][i] + rng.randf_range(-35,35)
		var target := Vector2(x,rng.randf_range(105,255) if i < 2 else rng.randf_range(25,85))
		if i>0:born+=rng.randf_range(maxf(0.18,settings.rocket_stagger-0.07),minf(0.35,settings.rocket_stagger+0.10))
		var explosion:=maxf(born+0.75,previous_explosion+rng.randf_range(0.15,0.40))
		previous_explosion=explosion
		full_end=maxf(full_end,explosion+clampf(settings.burst_lifetime,0.8,2.5))
		bursts.append({"wave":waves,"born":born,
			"travel":explosion-born,
			"life":clampf(settings.burst_lifetime,0.8,2.5),"start":Vector2(clampf(x+rng.randf_range(-95,95),30 if x<640 else 1040,240 if x<640 else 1250),760),
			"center":target,"scale":rng.randf_range(0.85,1.15),"phase":rng.randf_range(0,TAU),
			"color":COLORS[(waves+i)%COLORS.size()],"exploded":false})
		_prepare_sparks(bursts.back())
	var minimum := clampf(settings.delay_min,1.2,1.8)
	next_burst = full_end-elapsed+rng.randf_range(minimum,clampf(settings.delay_max,minimum,1.8))

func _prepare_sparks(burst: Dictionary) -> void:
	# Reused vertex buffers turn sixty small draw calls into three batched calls.
	var rays:=clampi(settings.rays,12,32)
	burst.directions=PackedVector2Array();burst.outer_directions=PackedVector2Array()
	burst.streaks=PackedVector2Array();burst.tips=PackedVector2Array();burst.outer=PackedVector2Array()
	burst.streaks.resize(rays*2);burst.tips.resize(rays*2);burst.outer.resize(rays*2)
	for ray in range(rays):
		var direction:=Vector2.from_angle(ray*TAU/rays+burst.phase)
		burst.directions.append(direction);burst.outer_directions.append(direction.rotated(0.065))

func stop() -> void:
	finished = true
	set_process(false)
	bursts.clear()
	if is_instance_valid(voice): voice.stop()
	queue_redraw()

func _exit_tree() -> void:
	stop()

func _draw() -> void:
	for burst in bursts:
		var time: float = elapsed-burst.born
		if time < 0: continue
		var color: Color = burst.color
		if time < burst.travel:
			var t: float = clampf(time/burst.travel,0,1)
			var at: Vector2 = burst.start.lerp(burst.center,1.0-pow(1.0-t,1.35))
			var direction: Vector2 = (burst.center-burst.start).normalized()
			var length := minf(clampf(settings.rocket_trail_length,30,180),at.distance_to(burst.start))
			for segment in range(8):
				var tail := at-direction*length*float(segment)/8.0
				draw_line(tail,tail-direction*length/8.0,Color(color,(1.0-float(segment)/8.0)*0.75),4.0,true)
			draw_circle(at,9,Color(color,0.12))
			draw_circle(at,3,Color("fff7d6"))
			continue
		var age: float = clampf((time-burst.travel)/burst.life,0,1)
		var radius: float = clampf(settings.explosion_radius,100,280)*burst.scale
		var travel: float = 1.0-pow(1.0-age,2.4)
		var gravity := Vector2(0,80*age*age)
		var rays: int = burst.directions.size()
		if age < 0.2:
			draw_circle(burst.center,30*(1-age/0.2),Color(1,0.97,0.8,1-age/0.2))
		for ray in range(rays):
			var direction: Vector2 = burst.directions[ray]
			var distance: float = radius*travel*(0.8+float(ray%3)*0.1)
			var at: Vector2 = burst.center+direction*distance+gravity
			burst.streaks[ray*2]=at-direction*(10+age*10);burst.streaks[ray*2+1]=at
			burst.tips[ray*2]=at-Vector2(1,0);burst.tips[ray*2+1]=at+Vector2(1,0)
			var secondary: Vector2 = burst.center+burst.outer_directions[ray]*distance*0.65+gravity*1.3
			burst.outer[ray*2]=secondary-Vector2(0.7,0);burst.outer[ray*2+1]=secondary+Vector2(0.7,0)
		color.a=(1-age)*0.95
		draw_multiline(burst.streaks,color,2.7,true)
		draw_multiline(burst.tips,Color(1,0.98,0.87,1-age),2.8*(1-age)+0.5,true)
		draw_multiline(burst.outer,Color(color,0.7*(1-age)),1.8,true)
