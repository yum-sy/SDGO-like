extends CharacterBody3D
signal hit
const State = preload("res://scripts/unit_state.gd")
var state := State.new()
var booster: float:
	get: return state.booster
	set(value): state.booster = value
var hp: int:
	get: return state.hp
var focus_yaw := NAN
var last_hit_from := Vector3.ZERO
var attack_slow := 1.0
var yaw := 0.0
var pitch := -0.22
var visual: Node3D
var impulse := Vector3.ZERO
var dash_left := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector3.ZERO
var dash_was_held := false
var animation_time := 0.0
var rig: Node3D
var grounded := false

func aim_point() -> Vector3:
	return global_position + Vector3.UP * 1.1
func damage_from(amount: int, source: Vector3) -> void:
	if hp > 0 and state.invulnerable <= 0: last_hit_from = source
	damage(amount)
func damage(amount: int) -> void:
	if state.damage(amount):
		hit.emit()
		if is_instance_valid(rig):
			rig.hit()
			if hp <= 0: rig.die()
func simulate(command: Dictionary, delta: float) -> void:
	state.tick(delta)
	if hp <= 0:
		return
	if command.look.length() > 0: focus_yaw = NAN
	if not is_nan(focus_yaw):
		var turn := angle_difference(yaw,focus_yaw)
		yaw += clampf(turn,-3.0*delta,3.0*delta)
		if absf(angle_difference(yaw,focus_yaw)) < 0.01: focus_yaw = NAN
	yaw -= command.look.x
	pitch = clampf(pitch - command.look.y, -0.9, 0.45)
	var direction := Basis(Vector3.UP, yaw) * Vector3(command.move.x, 0, command.move.y)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	dash_left = maxf(0,dash_left-delta)
	if command.dash and not dash_was_held and dash_cooldown == 0 and booster >= 22:
		dash_direction = direction if direction.length() > 0.1 else -Basis(Vector3.UP,yaw).z
		dash_left = 0.18
		dash_cooldown = 0.55
		booster -= 22
		if is_on_floor(): preload("res://scripts/ground_fx.gd").spawn(get_parent(),global_position)
	dash_was_held = command.dash
	if booster < 1:
		state.boost_locked = true
	if booster > 25:
		state.boost_locked = false
	var boosting: bool = command.boost and not is_on_floor() and not state.boost_locked and booster > 0
	var speed := (12.0 if boosting else 7.0)*attack_slow
	velocity.x = move_toward(velocity.x, direction.x * speed, 50 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 50 * delta)
	if is_on_floor() and command.jump:
		velocity.y = 9
	elif boosting:
		velocity.y = move_toward(velocity.y, 3.5, 25 * delta)
	else:
		velocity.y -= 24 * delta
	if dash_left > 0:
		velocity.x = dash_direction.x * 24
		velocity.z = dash_direction.z * 24
	velocity += impulse
	impulse = Vector3.ZERO
	booster = clampf(booster + (-36.0 if boosting else 20.0) * delta, 0, 100)
	var was_grounded := grounded
	var falling_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not was_grounded and falling_speed < -4 and is_instance_valid(rig):
		rig.land()
		preload("res://scripts/ground_fx.gd").spawn(get_parent(),global_position)
	grounded = is_on_floor()
	if direction.length() > 0.1 and (not is_instance_valid(rig) or (rig.aim_left <= 0.1 and rig.swing_left == 0) or dash_left > 0):
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), 1-exp(-16*delta))
	animation_time += delta * Vector2(velocity.x,velocity.z).length()*1.5
	if is_instance_valid(rig):
		rig.boost_active = boosting or dash_left > 0
		rig.animate(velocity,grounded,animation_time,delta)
	if position.y < -12:
		position = Vector3(0,2,5)
		velocity = Vector3.ZERO
		damage(20)
