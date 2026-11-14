extends RefCounted
# Score/optional medals never gate the three-target victory condition.
const LEVELS = ["STANDARD","VETERAN"]
static var selected := 0
var level := 0
var arena_id := 0
var cover_breaks := 0
func specialty_name() -> String:
	return "SABER FINISH" if arena_id == 0 else "BREAK 2 COVERS"
func medals(battle: Node, player: Node) -> Array[bool]:
	return [battle.won and battle.elapsed <= 45,battle.won and player.hp >= 60,battle.won and (battle.melee_kills > 0 if arena_id == 0 else cover_breaks >= 2)]
func score(battle: Node, player: Node) -> int:
	if not battle.won: return battle.kills*300
	var bonus := 0
	for earned in medals(battle,player):
		if earned: bonus += 250
	var total: int = battle.kills*300+player.hp*5+int(maxf(0,60-battle.elapsed)*10)+bonus
	return int(total*(1.4 if level == 1 else 1.0))
func record_key() -> String:
	return "sortie_%d_%d" % [arena_id,level]
