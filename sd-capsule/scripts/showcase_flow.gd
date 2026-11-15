extends RefCounted
# Optional coaching only: never gates movement, combat, score or victory.
var moved := 0.0
var fired := false
var slashed := false
var dashed := false
func observe(command: Dictionary, delta: float) -> void:
	if command.get("move",Vector2.ZERO).length() > 0.1: moved += delta
	fired = fired or command.get("fire",false)
	slashed = slashed or command.get("melee",false)
	dashed = dashed or command.get("dash",false)
func hint(battle: Node, touch: bool) -> String:
	if battle.elapsed > 25: return ""
	if moved < 0.4: return "MOVE  /  Left stick" if touch else "MOVE  /  WASD   -   Drag the view to look around"
	if not fired: return "RIFLE  /  FIRE button. Auto-lock handles aim." if touch else "RIFLE  /  Left mouse or F. Auto-lock handles aim."
	if not dashed: return "EVADE  /  Move + DASH to leave the orange attack zone." if touch else "EVADE  /  Move + SHIFT to leave the orange attack zone."
	if not slashed: return "CLOSE COMBAT  /  Tap MELEE near an enemy." if touch else "CLOSE COMBAT  /  Press right mouse or V near an enemy."
	return "TACTICS  /  TARGET finds enemies. FREE AIM breaks cover." if touch else "TACTICS  /  TAB finds enemies. C toggles free aim to break cover."
