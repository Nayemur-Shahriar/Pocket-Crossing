class_name CollisionRules
extends RefCounted
enum Hit { IGNORED, SHIELDED, LIFE_LOST }
static func hit(actor: CrossingPlayer, powers: PowerUpController) -> Hit:
	if not actor.visible or actor.invulnerable_left>0:return Hit.IGNORED
	if powers.consume_shield():
		actor.invulnerable_left=maxf(actor.invulnerable_left,1.2)
		return Hit.SHIELDED
	return Hit.LIFE_LOST
