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
	var left := 44.0
	draw_rect(Rect2(Vector2(24,22),Vector2(310,160)),Color(0.02,0.06,0.1,0.72))
	text(Vector2(left,48),"CAPSULE // SORTIE 01",18,MINT)
	text(Vector2(left,78),"HP %03d    ZAKU %d / 3" % [player.hp,battle.kills],22)
	bar(Vector2(left,89),265,player.hp/100.0,Color(0.5,0.85,1))
	text(Vector2(left,122),"BOOST %03d%s" % [player.booster,"  COOLING" if player.state.boost_locked else ""],16)
	bar(Vector2(left,131),265,player.booster/100.0,MINT)
	text(Vector2(left,168),"%d FPS  /  AVG %d  /  %s" % [Engine.get_frames_per_second(),game.average_fps,"LOW" if game.low_quality else "HIGH"],14)
	var rifle = battle.rifle
	var name_text := "BEAM RIFLE" if battle.weapon == 0 else "BEAM SABER"
	var ammo_text := "%d / 6" % rifle.ammo if battle.weapon == 0 else "COMBO %d / 3" % battle.combo
	text(Vector2(left,215),name_text+"    "+ammo_text,24)
	if rifle.reload_left > 0:
		text(Vector2(left,244),"RELOADING %.1f s" % rifle.reload_left,18,Color(1,0.8,0.35))
	else:
		text(Vector2(left,244),"SABER CD %.1f s" % battle.melee_cooldown,16)
	text(Vector2(size.x-260,36),"TIME  %05.1f" % battle.elapsed,20)
	text(Vector2(44,size.y-20),"Models: nickqd / krit yamsaso · CC BY 4.0     Audio & props: Kenney · CC0",12)
	if battle.hurt_left > 0:
		draw_rect(Rect2(Vector2.ZERO,size),Color(1,0.12,0.1,battle.hurt_left*0.4))
	if game.mode == "playing":
		draw_line(center-Vector2(6,0),center+Vector2(6,0),MINT)
		draw_line(center-Vector2(0,6),center+Vector2(0,6),MINT)
		for target in battle.targets:
			if target.hp <= 0: continue
			var point: Vector3 = target.aim_point()
			var at: Vector2 = game.camera.unproject_position(point)
			if game.camera.is_position_behind(point) or not Rect2(Vector2(40,40),size-Vector2(80,80)).has_point(at):
				var direction: Vector3 = game.camera.global_basis.inverse()*(point-game.camera.global_position)
				text(Vector2(44 if direction.x<0 else size.x-90,size.y*0.5),"< ZAKU" if direction.x<0 else "ZAKU >",14,Color(1,0.65,0.3))
				continue
			if target == battle.selected:
				draw_rect(Rect2(at-Vector2(30,34),Vector2(60,68)),MINT,false,2)
				text(at+Vector2(-30,-44),"LOCK %d" % target.target_number,16,MINT)
			bar(at+Vector2(-25,42),50,target.hp/100.0,Color(1,0.5,0.2) if target.windup>0 else MINT)
			if target.windup > 0: text(at+Vector2(-16,-28),"!",26,Color(1,0.6,0.15))
		if battle.hit_left > 0:
			for axis in [Vector2(1,1),Vector2(-1,1)]: draw_line(center-axis*12,center+axis*12,Color.WHITE,2)
		if pilot.touch_visible:
			var origin: Vector2 = Vector2(135,size.y-135) if pilot.stick_id == -1 else pilot.stick_origin
			draw_circle(origin,65,Color(0.5,0.8,1,0.16))
			draw_arc(origin,65,0,TAU,32,Color(0.7,0.9,1,0.5),2)
			draw_circle(origin+pilot.touch_move*50,24,Color(0.7,0.9,1,0.5))
			var buttons := Layout.buttons(size)
			for action in buttons:
				var rect: Rect2 = buttons[action]
				var active: bool = pilot.held(action)
				draw_rect(rect,Color(0.1,0.5,0.65,0.65) if active else Color(0.1,0.2,0.3,0.48))
				draw_rect(rect,Color(0.6,0.85,1,0.4),false,1)
				var label: String = {"cycle":"TARGET","weapon":"SWAP"}.get(action,action.to_upper())
				text(rect.position+Vector2(12,rect.size.y*0.5+6),label,16)
		else:
			text(Vector2(44,size.y-77),"WASD move   SPACE jump / boost   SHIFT dash   TAB target   Q/E weapon",16)
			text(Vector2(44,size.y-51),"LMB / F fire   RMB / V saber   R reload   ESC pause   M sound   L quality   T touch UI",16)
		return
	# Menu stays over the full 3D viewport; it never reserves screen space.
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.035,0.06,0.8))
	var x := center.x-280
	var y := center.y-125
	var title := "READY TO LAUNCH" if game.mode == "ready" else ("PAUSED" if game.mode == "paused" else ("MISSION COMPLETE" if battle.won else "UNIT DOWN"))
	text(Vector2(x,y),title,36,MINT if not battle.lost else Color(1,0.5,0.4))
	var detail := "RX78 vs 3 Zaku  /  rifle + 3-hit saber combo"
	if game.mode == "result": detail = "Destroyed %d / 3   Time %.1fs   Accuracy %d%%" % [battle.kills,battle.elapsed,100*battle.hits/maxi(1,battle.shots)]
	text(Vector2(x,y+44),detail,19)
	text(Vector2(x,y+78),"Enemy orange flash = shot incoming. Dash or use cover.",18)
	text(Vector2(x,y+108),"Saber: get within 3m, hold RMB / V. Hit 3 knocks back.",18)
	text(Vector2(x,y+148),"ENTER / TAP TO "+("RETRY" if game.mode == "result" else "PLAY"),26,MINT)
	text(Vector2(x,y+185),"BEST %.1fs" % game.best_time if game.best_time>0 else "Defeat all three to set your first record.",16)
	var buttons := Layout.menu_buttons(size)
	for key in buttons:
		var rect: Rect2 = buttons[key]
		draw_rect(rect,Color(0.15,0.27,0.36))
		var label := ("SOUND OFF" if game.sounds.muted else "SOUND ON") if key == "mute" else ("QUALITY LOW" if game.low_quality else "QUALITY HIGH")
		text(rect.position+Vector2(16,33),label,16)
