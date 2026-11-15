extends Node
const Layout = preload("res://scripts/control_layout.gd")
var move := Vector2.ZERO
var look := Vector2.ZERO
var jump := false
var stick_id := -1
var look_id := -1
var stick_origin := Vector2.ZERO
var touch_move := Vector2.ZERO
var touches := {}
var queued := {}
var allow_restart := false
var menu_open := true
var force_touch := false
var left_down := false
var right_down := false
var mouse_fire := false
var mouse_melee := false
var active := true
var touch_visible: bool:
	get: return DisplayServer.is_touchscreen_available() or force_touch

func clear() -> void:
	stick_id = -1
	move = Vector2.ZERO
	look_id = -1
	touch_move = Vector2.ZERO
	touches.clear()
	queued.clear()
	left_down = false
	right_down = false
	mouse_fire = false
	mouse_melee = false
	look = Vector2.ZERO
	jump = false
func _input(event: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE: jump = true
			KEY_V: queued.melee = true
			KEY_F: queued.fire = true
			KEY_R: queued.reload = true
			KEY_TAB: queued.cycle = true
			KEY_Q, KEY_E: queued.weapon = true
			KEY_ENTER: queued.restart = true
			KEY_ESCAPE: queued.pause = true
			KEY_T: force_touch = not force_touch
			KEY_M: queued.mute = true
			KEY_L: queued.quality = true
			KEY_N: queued.arena = true
			KEY_H: queued.difficulty = true
			KEY_C: queued.aim = true
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_down = event.pressed
			if event.pressed: queued.fire = true
			mouse_fire = event.pressed
			if event.pressed and menu_open:
				menu_press(event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_down = event.pressed
			if event.pressed: queued.melee = true
			mouse_melee = event.pressed
	if event is InputEventMouseMotion and not menu_open:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or left_down or right_down or (OS.has_feature("web") and JavaScriptBridge.eval("!!document.pointerLockElement")):
			look += event.relative * 0.0025
	if event is InputEventScreenTouch:
		if not event.pressed:
			touches.erase(event.index)
			if event.index == stick_id:
				stick_id = -1
				touch_move = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
		elif menu_open:
			menu_press(event.position)
		else:
			var handled := false
			var buttons := Layout.buttons(size)
			for action in buttons:
				if buttons[action].has_point(event.position):
					touches[event.index] = action
					queued[action] = true
					if action == "boost": jump = true
					handled = true
					break
			if not handled:
				if event.position.x < size.x*0.35 and event.position.y > size.y*0.45 and stick_id == -1:
					stick_id = event.index
					stick_origin = event.position.clamp(Vector2(80+Layout.safe.x,80+Layout.safe.y),size-Vector2(80+Layout.safe.z,80+Layout.safe.w))
				elif look_id == -1:
					look_id = event.index
	if event is InputEventScreenDrag:
		if event.index == stick_id:
			var displacement: Vector2 = (event.position-stick_origin)/80.0
			var strength := clampf((displacement.length()-0.12)/0.88,0.0,1.0)
			touch_move = displacement.normalized()*strength
		if event.index == look_id:
			look += event.relative*0.004*720.0/size.y
		elif touches.get(event.index, "") in ["fire","boost"]:
			# Right thumb aims while holding fire; left thumb keeps moving.
			look += event.relative*0.003*720.0/size.y
func held(action: String) -> bool:
	return action in touches.values()
func sample() -> Dictionary:
	move = Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))) if active else Vector2.ZERO
	move = (move+touch_move).limit_length()
	var command := {"move":move,"look":look,"jump":jump,"boost":held("boost") or (active and Input.is_physical_key_pressed(KEY_SPACE)),"dash":held("dash") or (active and Input.is_physical_key_pressed(KEY_SHIFT)),"fire":queued.get("fire",false) or mouse_fire or left_down or held("fire") or (active and Input.is_physical_key_pressed(KEY_F)),"melee":queued.get("melee",false) or mouse_melee or right_down or held("melee") or (active and Input.is_physical_key_pressed(KEY_V))}
	for action in ["reload","cycle","weapon","restart","pause","mute","quality","suspend","arena","difficulty","aim"]:
		command[action] = queued.get(action,false)
	queued.clear()
	look = Vector2.ZERO
	jump = false
	mouse_fire = false
	mouse_melee = false
	return command
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		active = false
		clear()
		queued.suspend = true
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		active = true

func menu_press(position: Vector2) -> void:
	var buttons := Layout.menu_buttons(get_viewport().get_visible_rect().size)
	for action in buttons:
		if buttons[action].has_point(position):
			queued[action] = true
			return
	# Only the visible primary action launches; background clicks are safe.
