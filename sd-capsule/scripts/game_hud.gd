extends Control
const Layout = preload("res://scripts/control_layout.gd")
var game: Node3D
var font: Font = ThemeDB.fallback_font
const INK = Color(0.87,0.94,1)
const MINT = Color(0.35,1,0.8)
func _process(_delta: float) -> void:
	queue_redraw()
func text(at: Vector2, value: String, px: int = 20, tint: Color = INK) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)
func bar(at: Vector2, width: float, ratio: float, tint: Color) -> void:
	draw_rect(Rect2(at,Vector2(width,9)),Color(0.04,0.09,0.14,0.9))
	draw_rect(Rect2(at,Vector2(width*clampf(ratio,0,1),9)),tint)
func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.combat): return
	var battle = game.combat
	var player = game.unit
	var pilot = game.pilot
	var center := size*0.5
	var left := 44.0+Layout.safe.x
	draw_rect(Rect2(Vector2(left-20,22+Layout.safe.y),Vector2(310,160)),Color(0.02,0.06,0.1,0.72))
	text(Vector2(left,48),"RX-78 // "+game.rules.LEVELS[game.rules.level],18,MINT)
	text(Vector2(left,78),"HP %03d    ZAKU %d / 3" % [player.hp,battle.kills],22)
	bar(Vector2(left,89),265,player.hp/100.0,Color(0.5,0.85,1))
	text(Vector2(left,122),"BOOST %03d%s" % [player.booster,"  COOLING" if player.state.boost_locked else ""],16)
	bar(Vector2(left,131),265,player.booster/100.0,MINT)
	text(Vector2(left,168),"THRUSTER READY" if player.booster >= 22 else "THRUSTER RECHARGING",14)
	var rifle = battle.rifle
	var name_text := "BEAM RIFLE" if battle.weapon == 0 else "BEAM SABER"
	var ammo_text := "%d / 6" % rifle.ammo if battle.weapon == 0 else "COMBO %d / 3" % battle.combo
	text(Vector2(left,215),name_text+"    "+ammo_text,24)
	if rifle.reload_left > 0:
		text(Vector2(left,244),"RELOADING %.1f s" % rifle.reload_left,18,Color(1,0.8,0.35))
		bar(Vector2(left,257),265,1-rifle.reload_left/1.6,Color(1,0.8,0.35))
	else:
		text(Vector2(left,244),"SABER "+battle.attack.stage(),16)
		for round_index in range(6):
			draw_rect(Rect2(Vector2(left+round_index*30,257),Vector2(23,5)),MINT if round_index < rifle.ammo else Color(0.2,0.3,0.35))
	text(Vector2(size.x-260-Layout.safe.z,36+Layout.safe.y),"TIME  %05.1f" % battle.elapsed,20)
	text(Vector2(44,size.y-20),"Models: nickqd / krit yamsaso · CC BY 4.0     Audio & props: Kenney · CC0",12)
	if battle.hurt_left > 0:
		draw_rect(Rect2(Vector2.ZERO,size),Color(1,0.12,0.1,battle.hurt_left*0.4))
		var incoming: Vector3 = Basis(Vector3.UP,-player.yaw)*(player.last_hit_from-player.position)
		var toward := Vector2(incoming.x,incoming.z).normalized()
		var perpendicular := Vector2(-toward.y,toward.x)
		var marker := center+toward*110
		draw_colored_polygon(PackedVector2Array([marker+toward*14,marker-toward*5+perpendicular*10,marker-toward*5-perpendicular*10]),Color(1,0.45,0.25))
	if game.mode == "playing":
		var progress := "%d/1" % mini(battle.melee_kills,1) if game.arena.index == 0 else "%d/2" % mini(game.rules.cover_breaks,2)
		text(Vector2(left,292),"BONUS: "+game.rules.specialty_name()+"  "+progress,14,MINT)
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
		var radar := Vector2(size.x-105-Layout.safe.z,(240 if pilot.touch_visible else 135)+Layout.safe.y)
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
		draw_line(center-Vector2(6,0),center+Vector2(6,0),MINT)
		draw_line(center-Vector2(0,6),center+Vector2(0,6),MINT)
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
			bar(at+Vector2(-25,42),50,float(target.hp)/target.max_hp,Color(1,0.5,0.2) if target.windup>0 else MINT)
			if target.windup > 0:
				text(at+Vector2(-30,-63),"MELEE!" if target.attack_kind == "melee" else "INCOMING",16,Color(1,0.6,0.15))
				draw_arc(at,46,-PI/2,-PI/2+TAU*(1-target.windup/(1.0 if target.role == "SUPPORT" else (0.55 if target.attack_kind == "melee" else 0.65))),24,Color(1,0.6,0.15),3)
		if battle.hit_left > 0:
			for axis in [Vector2(1,1),Vector2(-1,1)]: draw_line(center-axis*12,center+axis*12,Color.WHITE,2)
		if pilot.touch_visible:
			var origin: Vector2 = Vector2(135+Layout.safe.x,size.y-135-Layout.safe.w) if pilot.stick_id == -1 else pilot.stick_origin
			draw_circle(origin,65,Color(0.5,0.8,1,0.16))
			draw_arc(origin,65,0,TAU,32,Color(0.7,0.9,1,0.5),2)
			draw_circle(origin+pilot.touch_move*50,24,Color(0.7,0.9,1,0.5))
			var buttons := Layout.buttons(size)
			for action in buttons:
				var rect: Rect2 = buttons[action]
				var active: bool = pilot.held(action)
				draw_rect(rect,Color(0.1,0.5,0.65,0.65) if active else Color(0.1,0.2,0.3,0.48))
				draw_rect(rect,Color(0.6,0.85,1,0.4),false,1)
				var label: String = {"cycle":"TARGET","weapon":"SWAP","aim":"AUTO ON" if battle.auto_aim else "FREE AIM"}.get(action,action.to_upper())
				text(rect.position+Vector2(12,rect.size.y*0.5+6),label,20)
		elif battle.elapsed < 8:
			text(Vector2(44,size.y-77),"WASD move   SPACE jump / boost   SHIFT dash   TAB target   Q/E weapon   C free aim",16)
			text(Vector2(44,size.y-51),"LMB / F fire   RMB / V saber   R reload   ESC pause   M sound   L quality   T touch UI",16)
		return
	# Menu stays over the full 3D viewport; it never reserves screen space.
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.035,0.06,0.8))
	var x := center.x-280
	var y := center.y-125
	var title := "READY TO LAUNCH" if game.mode == "ready" else ("PAUSED" if game.mode == "paused" else ("MISSION COMPLETE" if battle.won else "UNIT DOWN"))
	text(Vector2(x,y),title,36,MINT if not battle.lost else Color(1,0.5,0.4))
	var detail: String = game.arena.NAMES[game.arena.index]+" / 3 SPECIALIST ZAKU"
	if game.mode == "result": detail = "Destroyed %d / 3   Time %.1fs   Accuracy %d%%" % [battle.kills,battle.elapsed,100*battle.hits/maxi(1,battle.shots)]
	text(Vector2(x,y+44),detail,19)
	if game.mode == "result" and battle.won:
		var grade := "S" if player.hp >= 80 and battle.elapsed < 30 else ("A" if player.hp >= 50 else "B")
		text(Vector2(x+460,y),grade,64,MINT)
	if game.mode == "paused":
		text(Vector2(x,y-35),"%d FPS / AVG %d" % [Engine.get_frames_per_second(),game.average_fps],16)
	if game.mode == "result":
		var awards: Array[bool] = game.rules.medals(battle,player)
		var labels := ["SPEED <45s","ARMOR 60+",game.rules.specialty_name()]
		for i in range(3):
			text(Vector2(x+i*190,y+79),("+ " if awards[i] else "- ")+labels[i],15,MINT if awards[i] else Color(0.5,0.6,0.65))
		text(Vector2(x,y+111),"SCORE %05d    BEST %05d" % [game.rules.score(battle,player),game.best_score],22)
	else:
		text(Vector2(x,y+78),"BONUS: "+game.rules.specialty_name()+" / finish <45s / armor 60+",17)
		text(Vector2(x,y+108),"C / AUTO: free aim. Break crates to open new routes.",18)
	text(Vector2(x,y+148),"ENTER / TAP TO "+("RETRY" if game.mode == "result" else "PLAY"),26,MINT)
	text(Vector2(x,y+185),"BEST %.1fs / %05d PTS" % [game.best_time,game.best_score] if game.best_time>0 else "Clear the sortie and earn optional medals.",16)
	var buttons := Layout.menu_buttons(size)
	for key in buttons:
		var rect: Rect2 = buttons[key]
		draw_rect(rect,Color(0.15,0.27,0.36))
		var label := ("SOUND OFF" if game.sounds.muted else "SOUND ON") if key == "mute" else ("QUALITY LOW" if game.low_quality else "QUALITY HIGH")
		if key == "arena": label = "MAP LOCKED IN COMBAT" if game.mode == "paused" else "N / "+game.arena.NAMES[game.arena.index]
		if key == "difficulty": label = "LOCKED" if game.mode == "paused" else "H / "+game.rules.LEVELS[game.rules.level]
		text(rect.position+Vector2(16,33),label,18 if key in ["arena","difficulty"] else 20)
