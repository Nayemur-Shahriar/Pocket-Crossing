class_name DogEncounter
extends RefCounted
## Authority-only deterministic state, one per racer. No nodes/pathfinding/timers.
var phase:="idle"
var stationary:=0.0
var warning_left:=0.0
var cooldown:=0.0
var origin:=Vector2.INF
var at:=Vector2.ZERO
var direction:=1
var warning_id:=0
var width:=1280.0
func reset() -> void:
	phase="idle";stationary=0;warning_left=0;cooldown=0;origin=Vector2.INF
func tick(delta: float, actor: CrossingPlayer, section: Dictionary, settings: DogConfig, active: bool) -> String:
	if settings==null or not active or not actor.visible:
		reset();return ""
	cooldown=maxf(0,cooldown-delta)
	var eligible:=settings.allows(section) and actor.invulnerable_left<=0
	# A committed pass survives movement/camera/section eligibility changes.
	# Only the pre-attack grace/warning is cancelled by a valid escape.
	if phase=="running":
		var before:=at.x
		at.x+=direction*clampf(settings.run_speed,180,420)*delta
		if actor.invulnerable_left<=0 and absf(actor.position.y-at.y)<24 and actor.position.x>=minf(before,at.x)-30 and actor.position.x<=maxf(before,at.x)+30:
			phase="idle";stationary=0;cooldown=maxf(3,settings.cooldown_seconds);origin=actor.position
			return "hit"
		if at.x < -80 or at.x > width+80:
			phase="idle";stationary=0;cooldown=settings.cooldown_seconds;origin=actor.position
		return ""
	if not eligible or actor.moving or origin==Vector2.INF or actor.position.distance_to(origin)>16:
		phase="idle";stationary=0;warning_left=0;origin=actor.position
		return ""
	if cooldown>0:return ""
	if phase=="idle":
		stationary+=delta
		if stationary>=maxf(2.5,settings.stationary_seconds):
			phase="warning";warning_left=maxf(0.7,settings.warning_seconds);warning_id+=1
			direction=1 if actor.position.x<width*0.5 else -1
			at=Vector2(-48 if direction>0 else width+48,actor.position.y)
			return "warning"
	elif phase=="warning":
		warning_left-=delta
		if warning_left<=0:phase="running"

	return ""
func snapshot() -> Dictionary:return {"phase":phase,"at":at,"direction":direction,"warning_id":warning_id,"origin":origin,"warning_left":warning_left}
