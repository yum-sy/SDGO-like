extends RefCounted
# AI produces a movement/fire intent; actor owns physics and damage.
var time := 0.0
var dodge_left := 0.0
var evade_cooldown := 0.0
var side := 1.0
func sample(actor: CharacterBody3D, player: CharacterBody3D, delta: float) -> Dictionary:
	time += delta
	dodge_left = maxf(0,dodge_left-delta)
	evade_cooldown = maxf(0,evade_cooldown-delta)
	var offset := player.global_position-actor.global_position
	offset.y = 0
	var distance := offset.length()
	var toward := offset.normalized()
	var tangent := Vector3(-toward.z,0,toward.x) * side
	var move := toward if distance > 12 else (-toward if distance < 5 else tangent*0.65)
	if dodge_left > 0:
		move = tangent
	return {"move":move,"speed":7.0 if dodge_left > 0 else 3.2,"fire":distance < 28,"target":player.aim_point(),"evading":dodge_left>0}
func evade() -> void:
	if evade_cooldown == 0:
		dodge_left = 0.4
		evade_cooldown = 1.8
		side = -side
