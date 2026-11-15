extends Control
const Layout = preload("res://scripts/control_layout.gd")
var game: Node3D
const DamageGauge = preload("res://scripts/damage_gauge.gd")
var health_gauges := {}
var redraw_clock := 0.0
var font: Font = ThemeDB.fallback_font
const INK = Color(0.87,0.94,1)
const MINT = Color(0.35,1,0.8)
func _process(delta: float) -> void:
	if is_instance_valid(game) and is_instance_valid(game.combat):
		for actor in [game.unit]+game.combat.targets:
			var key: int = actor.get_instance_id()
			if not health_gauges.has(key): health_gauges[key] = DamageGauge.new()
			var maximum: float = 100.0 if actor == game.unit else float(actor.max_hp)
			health_gauges[key].update(actor.hp/maximum,delta if game.mode == "playing" else 0)
	redraw_clock += delta
	if not is_instance_valid(game) or not game.low_quality or redraw_clock >= 1.0/30.0:
		redraw_clock = 0
		queue_redraw()
func health_bar(at: Vector2, width: float, actor: Node, tint: Color) -> void:
	var maximum: float = 100.0 if actor == game.unit else float(actor.max_hp)
	var ratio: float = actor.hp/maximum
	var gauge = health_gauges.get(actor.get_instance_id())
	bar(at,width,gauge.trailing if gauge != null else ratio,Color(1,0.62,0.22))
	draw_rect(Rect2(at,Vector2(width*ratio,9)),tint)
func text(at: Vector2, value: String, px: int = 20, tint: Color = INK) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)
func bar(at: Vector2, width: float, ratio: float, tint: Color) -> void:
	draw_rect(Rect2(at,Vector2(width,9)),Color(0.04,0.09,0.14,0.9))
	draw_rect(Rect2(at,Vector2(width*clampf(ratio,0,1),9)),tint)
func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.combat): return
	if game.mode != "playing":
		preload("res://scripts/showcase_menu.gd").draw(self)
		return
	var battle = game.combat
	var player = game.unit
	var pilot = game.pilot
	var center := size*0.5
	var left := 32.0+Layout.safe.x
	var top := 24.0+Layout.safe.y
	draw_colored_polygon(PackedVector2Array([Vector2(left-12,top-10),Vector2(left+270,top-10),Vector2(left+270,top+170),Vector2(left+250,top+190),Vector2(left-12,top+190)]),Color(0.025,0.055,0.08,0.88))
	draw_line(Vector2(left-12,top-10),Vector2(left+95,top-10),MINT,3)
	text(Vector2(left,top+12),"RX-78-2  /  "+game.rules.LEVELS[game.rules.level],13,MINT)
	text(Vector2(left,top+46),"%03d" % player.hp,30,INK)
	text(Vector2(left+72,top+44),"ARMOR",12,Color("8fa6b6"))
	health_bar(Vector2(left,top+56),250,player,Color("a9d9ef"))
	text(Vector2(left,top+89),"BOOST",12,Color("8fa6b6"))
	text(Vector2(left+200,top+89),"%03d" % player.booster,16,MINT)
	bar(Vector2(left,top+98),250,player.booster/100.0,MINT)
	var rifle = battle.rifle
	var name_text := "BEAM RIFLE" if battle.weapon == 0 else "BEAM SABER"
	var ammo_text := "%d / 6" % rifle.ammo if battle.weapon == 0 else "%d / 3" % battle.combo
	text(Vector2(left,top+136),name_text,18)
	text(Vector2(left+192,top+136),ammo_text,20,MINT)
	if rifle.reload_left > 0:
		bar(Vector2(left,top+151),250,1-rifle.reload_left/1.6,Color("f1ba74"))
		text(Vector2(left,top+179),"RELOAD  %.1fs" % rifle.reload_left,13,Color("f1ba74"))
	else:
		for round_index in range(6):
			draw_rect(Rect2(Vector2(left+round_index*42,top+151),Vector2(34,5)),MINT if round_index < rifle.ammo else Color("344857"))
		text(Vector2(left,top+179),"SABER  "+battle.attack.stage(),12,Color("8fa6b6"))
	var mission_x := size.x-290-Layout.safe.z
	draw_rect(Rect2(Vector2(mission_x,top-10),Vector2(266,64)),Color(0.025,0.055,0.08,0.88))
	text(Vector2(mission_x+14,top+12),"ELIMINATE HOSTILES",12,Color("8fa6b6"))
	for i in range(3):
		draw_rect(Rect2(Vector2(mission_x+14+i*24,top+26),Vector2(16,8)),MINT if i < battle.kills else Color("344857"))
	text(Vector2(mission_x+100,top+36),"%d / 3" % battle.kills,20,INK)
	text(Vector2(mission_x+182,top+36),"%04.1fs" % battle.elapsed,16,MINT)
	if battle.hurt_left > 0:
		draw_rect(Rect2(Vector2.ZERO,size),Color(1,0.12,0.1,battle.hurt_left*0.4))
		var incoming: Vector3 = Basis(Vector3.UP,-player.yaw)*(player.last_hit_from-player.position)
		var toward := Vector2(incoming.x,incoming.z).normalized()
		var perpendicular := Vector2(-toward.y,toward.x)
		var marker := center+toward*110
		draw_colored_polygon(PackedVector2Array([marker+toward*14,marker-toward*5+perpendicular*10,marker-toward*5-perpendicular*10]),Color(1,0.45,0.25))
	if game.mode == "playing":
		var progress := "%d/1" % mini(battle.melee_kills,1) if game.arena.index == 0 else "%d/2" % mini(game.rules.cover_breaks,2)
		text(Vector2(left,top+215),"BONUS  /  "+game.rules.specialty_name()+"  "+progress,12,MINT)
		if not battle.auto_aim: text(center+Vector2(-45,30),"FREE AIM",16,MINT)
		if battle.notice_left > 0:
			var width := font.get_string_size(battle.notice,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
			draw_rect(Rect2(Vector2(center.x-width/2-18,70),Vector2(width+36,40)),Color(0.02,0.07,0.11,0.8))
			text(Vector2(center.x-width/2,97),battle.notice,20,MINT)
		for cover in get_tree().get_nodes_in_group("breakable_cover"):
			if cover.hp <= 0 or cover.hp == 75: continue
			var at: Vector3 = cover.global_position+Vector3.UP*2.9
			if not game.camera.is_position_behind(at):
				var screen: Vector2 = game.camera.unproject_position(at)
				bar(screen-Vector2(24,0),48,cover.hp/75.0,Color(0.7,0.85,1))
		var radar := Vector2(size.x-105-Layout.safe.z,(240 if pilot.touch_visible else 154)+Layout.safe.y)
		draw_circle(radar,67,Color(0.025,0.07,0.1,0.72))
		draw_arc(radar,67,0,TAU,48,Color(0.4,0.65,0.7,0.6),1)
		draw_line(radar+Vector2(-60,0),radar+Vector2(60,0),Color(0.3,0.5,0.55,0.35))
		draw_line(radar+Vector2(0,-60),radar+Vector2(0,60),Color(0.3,0.5,0.55,0.35))
		draw_colored_polygon(PackedVector2Array([radar+Vector2(0,-7),radar+Vector2(-4,4),radar+Vector2(4,4)]),MINT)
		for enemy in battle.targets:
			if enemy.hp <= 0: continue
			var relative: Vector3 = Basis(Vector3.UP,-player.yaw)*(enemy.position-player.position)
			var dot_pos := Vector2(relative.x,relative.z)*1.5
			dot_pos = dot_pos.limit_length(59)
			draw_circle(radar+dot_pos,4,Color(1,0.55,0.25) if enemy.windup > 0 else Color(0.95,0.4,0.4))
		var gap: float = 5+rifle.cooldown/rifle.INTERVAL*7
		var reticle_tint := MINT if rifle.reload_left == 0 else Color(1,0.8,0.35)
		for axis in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			draw_line(center+axis*gap,center+axis*(gap+6),reticle_tint,1.5)
		if rifle.reload_left > 0:
			draw_arc(center,23,-PI/2,-PI/2+TAU*(1-rifle.reload_left/rifle.RELOAD_TIME),40,reticle_tint,2)
		if battle.attack.running:
			text(center+Vector2(-36,56),"SABER %d" % battle.combo,16,Color(1,0.5,0.8))
		for popup in battle.damage_popups:
			if not game.camera.is_position_behind(popup.point):
				var point: Vector2 = game.camera.unproject_position(popup.point)
				text(point+Vector2(55,-12-(0.65-popup.life)*55),str(popup.amount),26,Color(popup.tint, minf(1,popup.life*4)))
		for target in battle.targets:
			if target.hp <= 0: continue
			var point: Vector3 = target.aim_point()
			var at: Vector2 = game.camera.unproject_position(point)
			if game.camera.is_position_behind(point) or not Rect2(Vector2(40,40),size-Vector2(80,80)).has_point(at):
				var direction: Vector3 = game.camera.global_basis.inverse()*(point-game.camera.global_position)
				text(Vector2(44 if direction.x<0 else size.x-90,size.y*0.5),"< ZAKU" if direction.x<0 else "ZAKU >",14,Color(1,0.65,0.3))
				continue
			if target == battle.selected:
				for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
					var edge: Vector2 = at+corner*Vector2(34,38)
					draw_line(edge,edge-Vector2(corner.x*12,0),MINT,2)
					draw_line(edge,edge-Vector2(0,corner.y*12),MINT,2)
				text(at+Vector2(-30,-44),"%s / %dm" % [target.role,player.position.distance_to(target.position)],16,MINT)
			health_bar(at+Vector2(-25,42),50,target,Color(1,0.5,0.2) if target.windup>0 else MINT)
			if target.windup > 0:
				text(at+Vector2(-30,-63),"MELEE!" if target.attack_kind == "melee" else ("ROCKET / EVADE" if target.role == "SUPPORT" else "BURST / COVER"),16,Color(1,0.6,0.15))
				draw_arc(at,46,-PI/2,-PI/2+TAU*(1-target.windup/(1.0 if target.role == "SUPPORT" else (0.55 if target.attack_kind == "melee" else 0.65))),24,Color(1,0.6,0.15),3)
		if battle.hit_left > 0:
			for axis in [Vector2(1,1),Vector2(-1,1)]: draw_line(center-axis*12,center+axis*12,Color.WHITE,2)
		if pilot.touch_visible:
			var origin: Vector2 = Vector2(135+Layout.safe.x,size.y-135-Layout.safe.w) if pilot.stick_id == -1 else pilot.stick_origin
			draw_circle(origin,80,Color(0.5,0.8,1,0.16))
			draw_arc(origin,80,0,TAU,32,Color(0.7,0.9,1,0.5),2)
			draw_circle(origin+pilot.touch_move*60,24,Color(0.7,0.9,1,0.5))
			var buttons := Layout.buttons(size)
			for action in buttons:
				var rect: Rect2 = buttons[action]
				var active: bool = pilot.held(action)
				var accent := Color("ef9dc7") if action == "melee" else (MINT if action == "fire" else Color("9ac9ed"))
				if action in ["fire","melee","boost","dash"]:
					var radius: float = rect.size.x*0.5
					draw_circle(rect.get_center(),radius,Color(0.1,0.4,0.5,0.8) if active else Color(0.04,0.1,0.17,0.65))
					draw_arc(rect.get_center(),radius-2,0,TAU,32,accent if active else Color(accent,0.65),2)
				else:
					draw_rect(rect,Color(0.1,0.4,0.5,0.8) if active else Color(0.04,0.1,0.17,0.5))
					draw_rect(rect,Color(accent,0.4),false,1)
				var label: String = {"cycle":"TARGET","weapon":"SWAP","aim":"AUTO ON" if battle.auto_aim else "FREE AIM"}.get(action,action.to_upper())
				var label_width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
				text(rect.get_center()+Vector2(-label_width*0.5,6),label,20,accent)
				var button_progress := -1.0
				if action == "fire" and rifle.reload_left > 0: button_progress = 1-rifle.reload_left/rifle.RELOAD_TIME
				elif action == "melee" and battle.attack.running: button_progress = battle.attack.elapsed/battle.attack.duration()
				elif action == "boost": button_progress = player.booster/100.0
				if button_progress >= 0:
					draw_rect(Rect2(rect.position+Vector2(8,rect.size.y-10),Vector2((rect.size.x-16)*clampf(button_progress,0,1),4)),MINT)
		var hint: String = game.coaching.hint(battle,pilot.touch_visible)
		if not hint.is_empty():
			var hint_width := font.get_string_size(hint,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
			var hint_y := size.y-32-Layout.safe.w if pilot.touch_visible else size.y-54-Layout.safe.w
			draw_rect(Rect2(Vector2(center.x-hint_width/2-16,hint_y-23),Vector2(hint_width+32,34)),Color(0.02,0.05,0.08,0.9))
			text(Vector2(center.x-hint_width/2,hint_y),hint,16,INK)
		return
