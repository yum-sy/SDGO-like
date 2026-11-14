extends RefCounted
# Distinct tactical intent; actors own collision, attack timing and damage.
var role := "ASSAULT"
var state := "ADVANCE"
var time := 0.0
var dodge_left := 0.0
var evade_cooldown := 0.0
var side := 1.0
var route := PackedVector2Array()
var stuck_clock := 0.0
var last_position := Vector3.ZERO
var route_left := 0.0
func sample(actor: CharacterBody3D, player: CharacterBody3D, delta: float) -> Dictionary:
	time += delta
	dodge_left = maxf(0,dodge_left-delta)
	evade_cooldown = maxf(0,evade_cooldown-delta)
	route_left -= delta
	if actor.global_position.distance_to(last_position) < 0.02 and actor.velocity.length() > 0.5:
		stuck_clock += delta
	else: stuck_clock = 0
	last_position = actor.global_position
	if stuck_clock > 0.6:
		route_left = 0
		dodge_left = 0.25
		stuck_clock = 0
	var offset := player.global_position-actor.global_position
	offset.y = 0
	var distance := offset.length()
	var toward := offset.normalized()
	var tangent := Vector3(-toward.z,0,toward.x)*side
	var desired := player.global_position
	var speed := 3.4
	var fire := false
	if role == "ASSAULT":
		state = "RUSH" if distance > 2.4 else "STRIKE"
		speed = 4.4
		fire = distance < 3.0
		desired = player.global_position-toward*1.9
	elif role == "FLANKER":
		state = "FLANK"
		desired = player.global_position-toward*9+tangent*6
		fire = distance < 24
	else:
		state = "AIM"
		desired = actor.global_position # Elevated fire support holds its perch.
		fire = distance < 40
		if distance < 6:
			state = "RETREAT"
			desired = actor.global_position-toward*5
	var move := (desired-actor.global_position)
	move.y = 0
	if move.length() < 0.7: move = Vector3.ZERO
	else: move = move.normalized()
	if role != "SUPPORT" and is_instance_valid(actor.get_parent()) and actor.get_parent().get("arena") != null:
		if route_left <= 0:
			route = actor.get_parent().arena.path(actor.global_position,desired)
			route_left = 0.45+actor.target_number*0.05
		while not route.is_empty() and Vector2(actor.position.x,actor.position.z).distance_to(route[0]) < 0.8: route.remove_at(0)
		if not route.is_empty():
			move = Vector3(route[0].x-actor.position.x,0,route[0].y-actor.position.z).normalized()
	if dodge_left > 0 and role != "SUPPORT":
		state = "EVADE"
		move = tangent
		speed = 7
	# Separation avoids three actors collapsing into one silhouette.
	for sibling in actor.get_parent().get_children():
		if sibling == actor or not sibling is CharacterBody3D or not sibling.has_method("aim_point"): continue
		var separation: Vector3 = actor.global_position-sibling.global_position
		separation.y = 0
		if separation.length() > 0.01 and separation.length() < 1.8:
			move += separation.normalized()*0.5
	return {"move":move.limit_length(),"speed":speed,"fire":fire,"target":player.aim_point(),"evading":dodge_left>0}
func evade() -> void:
	if evade_cooldown == 0:
		dodge_left = 0.4
		evade_cooldown = 1.8
		side = -side
