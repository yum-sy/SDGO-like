extends RefCounted
const Layout = preload("res://scripts/control_layout.gd")
const INK := Color("e6f0f5")
const MUTED := Color("8fa6b6")
const ACCENT := Color("69ead0")
static func panel(h: Control, rect: Rect2, alpha: float = 0.92) -> void:
	h.draw_rect(rect,Color(0.025,0.055,0.085,alpha))
	h.draw_rect(rect,Color(0.35,0.57,0.65,0.22),false,1)
static func draw(h: Control) -> void:
	var g = h.game
	var b = g.combat
	var size: Vector2 = h.size
	var x := 48.0+Layout.safe.x
	var top := 120.0+Layout.safe.y
	var ready: bool = g.mode == "ready"
	var result: bool = g.mode == "result"
	var touch: bool = g.pilot.touch_visible
	if not ready: h.draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.03,0.05,0.74))
	panel(h,Rect2(x-16,top-24,580,size.y-top-18),0.94 if not ready else 0.88)
	h.draw_rect(Rect2(x-16,top-24,4,64),ACCENT)
	h.text(Vector2(x,top+14),"SDGO-like   /   PLAYABLE SHOWCASE",14,ACCENT)
	if ready:
		h.text(Vector2(x,top+76),"SMALL SCALE.",50,INK)
		h.text(Vector2(x,top+133),"FULL IMPACT.",50,INK)
		h.text(Vector2(x,top+176),"Close the gap. Read the attack. Own the fight.",18,MUTED)
		panel(h,Rect2(x,top+204,528,106),0.65)
		h.text(Vector2(x+18,top+234),"YOUR MISSION",13,ACCENT)
		h.text(Vector2(x+18,top+266),"Defeat three specialist Zaku units.",23,INK)
		h.text(Vector2(x+18,top+292),"Rifle at range. Saber up close. Dash out of danger.",16,MUTED)
		h.text(Vector2(x,top+350),"01  MOVE       02  LOCK & FIRE       03  CLOSE & STRIKE",14,ACCENT)
		h.text(Vector2(x,top+377),"LEFT STICK       HOLD FIRE                 TAP MELEE" if touch else "WASD / stick     LMB / FIRE                 RMB / MELEE",15,MUTED)
		var right := size.x-380-Layout.safe.z
		h.text(Vector2(right,size.y-185),"RX-78-2",36,INK)
		h.text(Vector2(right,size.y-154),"GENERAL PURPOSE / CLOSE COMBAT",12,ACCENT)
		h.text(Vector2(right,size.y-120),"BEAM RIFLE   +   BEAM SABER",16,INK)
		h.text(Vector2(right,size.y-88),"Single-player combat prototype",14,MUTED)
	elif result:
		h.text(Vector2(x,top+68),"MISSION CLEAR" if b.won else "UNIT DOWN",42,ACCENT if b.won else Color("ffa274"))
		h.text(Vector2(x,top+104),"Three threats neutralized. Sortie complete." if b.won else "Change your angle. Break cover. Try again.",17,MUTED)
		var values := ["%04.1fs" % b.elapsed,"%d%%" % (100*b.hits/maxi(1,b.shots)),"%03d" % g.unit.hp]
		var captions := ["CLEAR TIME","RIFLE ACCURACY","ARMOR LEFT"]
		for i in range(3):
			panel(h,Rect2(x+i*180,top+134,168,88),0.65)
			h.text(Vector2(x+14+i*180,top+165),captions[i],12,MUTED)
			h.text(Vector2(x+14+i*180,top+204),values[i],30,INK)
		h.text(Vector2(x,top+268),"SORTIE SCORE",14,ACCENT)
		h.text(Vector2(x,top+319),"%05d" % g.rules.score(b,g.unit),48,INK)
		h.text(Vector2(x+250,top+318),"BEST  %05d" % g.best_score,19,MUTED)
		h.text(Vector2(x,top+362),"%d / 3 DESTROYED    /    %d SABER FINISHES" % [b.kills,b.melee_kills],16,MUTED)
		var rx := size.x-430-Layout.safe.z
		panel(h,Rect2(rx-24,top+50,370,330),0.8)
		var grade := "S" if b.won and g.unit.hp >= 80 and b.elapsed < 30 else ("A" if b.won and g.unit.hp >= 50 else ("B" if b.won else "--"))
		h.text(Vector2(rx,top+87),"COMBAT RATING",14,MUTED)
		h.text(Vector2(rx,top+180),grade,92,ACCENT)
		var medals: Array[bool] = g.rules.medals(b,g.unit)
		var names := ["SPEED / UNDER 45s","ARMOR / 60+ REMAINING",g.rules.specialty_name()]
		for i in range(3):
			h.draw_circle(Vector2(rx+7,top+222+i*40),5,ACCENT if medals[i] else Color("364857"))
			h.text(Vector2(rx+26,top+228+i*40),names[i],15,INK if medals[i] else MUTED)
	else:
		h.text(Vector2(x,top+76),"TAKE A BREATHER.",38,INK)
		h.text(Vector2(x,top+116),"Your sortie resumes exactly where you left it.",18,MUTED)
		var lines := ["WASD   Move     /     Hold mouse button + drag to look","LMB / F   Rifle     /     RMB / V   Saber combo","SPACE   Jump & boost     /     SHIFT   Dash","TAB   Find target     /     R   Reload","Q / E   Switch weapon     /     C   Free aim"]
		if touch: lines = ["LEFT STICK   Move", "FIRE / BOOST   Shoot / Rise", "EMPTY SPACE DRAG   Turn camera", "MELEE   One tap, one swing", "DASH   Evade    /    TARGET   Find enemy"]
		for i in range(lines.size()): h.text(Vector2(x,top+174+i*34),lines[i],17,INK)
		h.text(Vector2(x,top+372),"DISPLAY  %d FPS   /   AVG %d" % [Engine.get_frames_per_second(),g.average_fps],14,MUTED)
	var buttons := Layout.menu_buttons(size)
	for key in buttons:
		var rect: Rect2 = buttons[key]
		var main: bool = key == "restart"
		var hover := rect.has_point(h.get_global_mouse_position())
		h.draw_rect(rect,ACCENT if main else (Color("263e50") if hover else Color("122636")))
		h.draw_rect(rect,Color(0.5,0.8,0.84,0.4),false,1)
		var label: String = ""
		match key:
			"restart": label = ("" if touch else "ENTER  /  ")+("LAUNCH SORTIE" if ready else ("RETRY SORTIE" if result else "RESUME SORTIE"))
			"arena": label = "N  /  "+g.arena.NAMES[g.arena.index] if g.mode != "paused" else "MAP LOCKED"
			"difficulty": label = "H  /  "+g.rules.LEVELS[g.rules.level] if g.mode != "paused" else "DIFFICULTY LOCKED"
			"mute": label = "M  /  AUDIO OFF" if g.sounds.muted else "M  /  AUDIO ON"
			"quality": label = "L / LOW FX" if g.low_quality else "L / HIGH FX"
		h.text(rect.position+Vector2(16,rect.size.y*0.5+6),label,20 if main else 14,Color("0b2530") if main else INK)
	h.text(Vector2(x,size.y-20),"UNOFFICIAL FAN PROTOTYPE    /    Install & controls in the top toolbar",12,MUTED)
