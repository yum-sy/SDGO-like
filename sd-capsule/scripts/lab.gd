extends Node3D
const Bolt = preload("res://scripts/enemy_bolt.gd")
const PilotInput = preload("res://scripts/pilot_input.gd")
const UnitMotor = preload("res://scripts/unit_motor.gd")
const Arena = preload("res://scripts/arena_layout.gd")
const Rules = preload("res://scripts/sortie_rules.gd")
var rules := Rules.new()
var coaching := preload("res://scripts/showcase_flow.gd").new()
var showcase_time := 0.0
var menu_camera := false
var overlay_open := false
var best_score := 0
var arena := Arena.new()
var combat: Node3D
var pilot: Node
var unit: CharacterBody3D
var camera: Camera3D
var pivot: Node3D
var arm: SpringArm3D
var hud: Control
var sounds: Node
var mode := "ready"
var low_quality := DisplayServer.is_touchscreen_available()
var lifecycle_epoch := 0
var last_web_mode := ""
var best_time := 0.0
var saved_result := false
var fps_samples: Array[float] = []
var sample_clock := 0.0
var average_fps := 0.0
var safe_clock := 1.0
var camera_clock := 0.0
var key_light: DirectionalLight3D

func box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	if size.y < 0.2: mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	return mesh
func block(size: Vector3, at: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = at
	box(body,size,Vector3.ZERO,color)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
func crate(at: Vector3, index: int = 0) -> void:
	var body := preload("res://scripts/destructible_cover.gd").new()
	body.cover_index = index
	add_child(body)
	body.position = at
	body.broken.connect(func(cover_id):
		arena.remove_cover(cover_id)
		rules.cover_breaks += 1
		combat.announce("COVER DESTROYED / ROUTE OPEN")
		combat.sound("destroy"))
func _ready() -> void:
	arena.index = Arena.selected
	rules.arena_id = arena.index
	rules.level = Rules.selected
	arena.build_navigation()
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		best_time = config.get_value("record",rules.record_key()+"_time",0.0)
		best_score = config.get_value("record",rules.record_key()+"_score",0)
		low_quality = config.get_value("settings","low_quality",low_quality)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("233d63") if arena.index == 0 else Color("172a46")
	sky_material.sky_horizon_color = Color("c6a58e") if arena.index == 0 else Color("759aa7")
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.ground_bottom_color = Color("263849")
	var sky := Sky.new()
	sky.sky_material = sky_material
	settings.sky = sky
	settings.background_color = Color("526d80")
	settings.fog_enabled = true
	settings.fog_light_color = Color("a99a8b") if arena.index == 0 else Color("647f8c")
	settings.fog_sky_affect = 0.18
	settings.fog_density = 0.003
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b4d1ed")
	settings.ambient_light_energy = 0.62
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-25,0)
	light.light_energy = 1.0
	light.light_color = Color("ffe1bc") if arena.index == 0 else Color("c4e9ff")
	light.shadow_enabled = true
	light.shadow_opacity = 0.72
	key_light = light
	add_child(light)
	block(Vector3(60,1,60),Vector3(0,-0.5,0),Color("304458"))
	for i in range(-6,7):
		box(self,Vector3(0.08,0.015,60),Vector3(i*5,0.01,0),Color("3a5061"))
		box(self,Vector3(60,0.015,0.08),Vector3(0,0.01,i*5),Color("3a5061"))
	for side in [-1,1]:
		block(Vector3(1,5,60),Vector3(side*30,2.5,0),Color("26394b"))
		block(Vector3(60,5,1),Vector3(0,2.5,side*30),Color("26394b"))
	for i in range(arena.crates().size()): crate(arena.crates()[i],i)
	for structure in arena.structures():
		block(structure.size,structure.at,Color("394e61"))
		box(self,Vector3(structure.size.x,0.04,structure.size.z),structure.at+Vector3.UP*(structure.size.y/2+0.03),Color("55798b"))
		# Edge lights make the boost-accessible raised firing deck readable.
		box(self,Vector3(structure.size.x,0.12,0.1),structure.at+Vector3(0,structure.size.y/2,structure.size.z/2),Color("69ced5"))
	for side in [-1,1]:
		for z in range(-25,30,10):
			box(self,Vector3(0.08,0.18,3),Vector3(side*29.45,0.4,z),Color("5ca6b1"))
	var dressing := preload("res://scripts/battlefield_dressing.gd").new()
	add_child(dressing)
	dressing.build(self,arena.index)
	combat = preload("res://scripts/combat.gd").new()
	add_child(combat)
	for i in range(3):
		var target := preload("res://scripts/zaku_target.gd").new()
		target.target_number = i+1
		target.role = ["ASSAULT","FLANKER","SUPPORT"][i]
		target.veteran = rules.level == 1
		if target.veteran:
			target.max_hp = 240
			target.hp = 240
		add_child(target)
		target.position = arena.spawns()[i]
		target.home = target.position
		combat.targets.append(target)
		target.destroyed.connect(combat.on_destroyed)
	unit = UnitMotor.new()
	add_child(unit)
	unit.position = Vector3(0,0.1,5)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 2.1
	collider.shape = capsule
	collider.position.y = 1.05
	unit.add_child(collider)
	unit.visual = Node3D.new()
	unit.add_child(unit.visual)
	var model := preload("res://assets/prepared/rx78.scn").instantiate()
	model.set_script(preload("res://scripts/mecha_rig.gd"))
	model.rotation.y = PI
	unit.visual.add_child(model)
	unit.rig = model
	unit.hit.connect(func(): combat.hurt_left = 0.3; combat.camera_trauma = 0.4; combat.sound("hit"); combat.cancel_melee())
	pilot = PilotInput.new()
	add_child(pilot)
	pivot = Node3D.new()
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 6.5
	arm.position.x = 0.65
	arm.margin = 0.25
	arm.add_excluded_object(unit.get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 65
	camera.current = true
	arm.add_child(camera)
	combat.player = unit
	combat.camera = camera
	sounds = preload("res://scripts/sounds.gd").new()
	add_child(sounds)
	sounds.muted = config.get_value("settings","muted",false)
	combat.sounds = sounds
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Control.new()
	hud.set_script(preload("res://scripts/game_hud.gd"))
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.game = self
	layer.add_child(hud)
	apply_quality()
	update_camera()
func update_camera(delta: float = 1.0) -> void:
	if menu_camera:
		camera.top_level = false
		camera.transform = Transform3D.IDENTITY
		camera.h_offset = 0
		camera.v_offset = 0
		camera.fov = 65
		menu_camera = false
	camera_clock += delta
	var desired := unit.position+Vector3(0,1.6,0)
	pivot.position = pivot.position.lerp(desired,1-exp(-22*delta))
	pivot.rotation = Vector3(unit.pitch,unit.yaw,0)
	var trauma: float = combat.camera_trauma
	camera.h_offset = sin(camera_clock*83)*trauma*0.06
	camera.v_offset = cos(camera_clock*71)*trauma*0.04
	camera.fov = lerpf(camera.fov,72.0 if unit.dash_left > 0 else 65.0,1-exp(-10*delta))
	update_player_visibility()
func update_player_visibility() -> void:
	# Preserve wall collision; only hide the visual when the spring arm is compressed.
	var distance := camera.global_position.distance_to(unit.aim_point())
	if distance < 1.5: unit.visual.visible = false
	elif distance > 1.9: unit.visual.visible = true
func apply_quality() -> void:
	Engine.max_fps = 60
	if is_instance_valid(key_light): key_light.shadow_enabled = not low_quality
	get_viewport().scaling_3d_scale = 0.8 if low_quality else 1.0
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if low_quality else Viewport.MSAA_2X
	get_viewport().mesh_lod_threshold = 3.0 if low_quality else 1.5
func save_settings() -> void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("record",rules.record_key()+"_time",best_time)
	config.set_value("record",rules.record_key()+"_score",best_score)
	config.set_value("settings","low_quality",low_quality)
	config.set_value("settings","muted",sounds.muted)
	config.save("user://settings.cfg")
	if OS.has_feature("web"):
		JavaScriptBridge.force_fs_sync()
func _process(delta: float) -> void:
	if OS.has_feature("web") and mode != last_web_mode:
		last_web_mode = mode
		JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('capsule-mode',{detail:'"+mode+"'}))")
	if mode == "ready" and is_physics_processing() and is_instance_valid(camera):
		showcase_time += delta
		menu_camera = true
		camera.top_level = true
		var orbit := 0.4+sin(showcase_time*0.18)*0.12
		camera.global_position = unit.global_position+Vector3(4.8*sin(orbit),2.6,-4.8*cos(orbit))
		camera.look_at(unit.global_position+Vector3.UP*1.12,Vector3.UP)
		camera.h_offset = -1.3
		camera.v_offset = 0
		camera.fov = 48
		unit.visual.visible = true
	if OS.has_feature("web"):
		overlay_open = bool(JavaScriptBridge.eval("!!window.capsuleOverlayOpen"))
		var epoch := int(JavaScriptBridge.eval("window.capsuleLifecycleEpoch || 0"))
		if epoch != lifecycle_epoch:
			lifecycle_epoch = epoch
			pilot.clear()
			if mode == "playing": mode = "paused"
	if overlay_open and mode == "playing":
		mode = "paused"
		pilot.clear()
	safe_clock += delta
	if OS.has_feature("web") and safe_clock > 1:
		safe_clock = 0
		var insets = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify(window.capsuleSafeInsets || [0,0,0,0])")))
		var css_width: float = float(JavaScriptBridge.eval("innerWidth"))
		if insets is Array and insets.size() == 4 and css_width > 0:
			var ratio := get_viewport().get_visible_rect().size.x/css_width
			preload("res://scripts/control_layout.gd").safe = Vector4(insets[0],insets[1],insets[2],insets[3])*ratio
	sample_clock += delta
	if sample_clock > 0.5:
		sample_clock = 0
		fps_samples.append(float(Engine.get_frames_per_second()))
		if fps_samples.size() > 60: fps_samples.pop_front()
		average_fps = 0
		for fps in fps_samples: average_fps += fps
		average_fps /= fps_samples.size()
func _physics_process(delta: float) -> void:
	var command: Dictionary = pilot.sample()
	if overlay_open:
		pilot.clear()
		return
	if command.get("difficulty",false) and mode in ["ready","result"]:
		Rules.selected = 1-rules.level
		get_tree().reload_current_scene()
		return
	if command.get("arena",false) and mode in ["ready","result"]:
		Arena.selected = (arena.index+1)%Arena.NAMES.size()
		get_tree().reload_current_scene()
		return
	if command.mute:
		sounds.muted = not sounds.muted
		save_settings()
	if command.quality:
		low_quality = not low_quality
		apply_quality()
		save_settings()
	if command.suspend and mode == "playing":
		mode = "paused"
	if command.pause and mode in ["playing","paused"]:
		mode = "paused" if mode == "playing" else "playing"
		pilot.clear()
	if mode in ["ready","paused"] and command.restart:
		mode = "playing"
		if menu_camera:
			camera.top_level = false
			camera.transform = Transform3D.IDENTITY
			camera.h_offset = 0
			camera.v_offset = 0
			camera.fov = 65
			menu_camera = false
			update_camera()
		pilot.menu_open = false
		pilot.clear()
		return
	if mode == "result" and command.restart:
		get_tree().reload_current_scene()
		return
	pilot.menu_open = mode != "playing"
	for child in combat.get_children():
		if child is Bolt:
			child.set_physics_process(mode == "playing")
	if mode != "playing":
		return
	coaching.observe(command,delta)
	unit.simulate(command,delta)
	update_camera(delta)
	combat.step(command,delta)
	if combat.won or combat.lost:
		mode = "result"
		pilot.menu_open = true
		pilot.clear()
		if combat.won:
			if best_time == 0 or combat.elapsed < best_time: best_time = combat.elapsed
			best_score = maxi(best_score,rules.score(combat,unit))
			save_settings()

# Boundary for a future host-authoritative 4-player session. No transport yet.
func capture_snapshot(tick: int) -> Dictionary:
	var enemies: Array = []
	for target in combat.targets:
		enemies.append({"id":target.target_number,"hp":target.hp,"role":target.role,"intent":target.brain.state,"attack_time":target.melee_clock.elapsed,"position":[target.position.x,target.position.y,target.position.z],"velocity":[target.velocity.x,target.velocity.y,target.velocity.z]})
	return {"schema":3,"arena":arena.index,"difficulty":rules.level,"broken_covers":arena.removed_covers,"attack":{"stage":combat.attack.stage(),"time":combat.attack.elapsed,"combo":combat.combo},"tick":tick,"mode":mode,"player":{"id":0,"state":unit.state.snapshot(),"position":[unit.position.x,unit.position.y,unit.position.z],"velocity":[unit.velocity.x,unit.velocity.y,unit.velocity.z],"yaw":unit.yaw,"ammo":combat.rifle.ammo,"reload":combat.rifle.reload_left,"weapon":combat.weapon},"enemies":enemies,"kills":combat.kills,"elapsed":combat.elapsed}
