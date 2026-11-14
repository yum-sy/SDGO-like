extends Node
var muted := false
var pool: Array[AudioStreamPlayer] = []
var cursor := 0
const EFFECTS = {
	"reload":preload("res://assets/audio/impactMetal_000.ogg"),
	"ready":preload("res://assets/audio/forceField_000.ogg"),
	"shot":preload("res://assets/audio/laserLarge_000.ogg"),
	"enemy":preload("res://assets/audio/laserSmall_000.ogg"),
	"saber":preload("res://assets/audio/forceField_000.ogg"),
	"hit":preload("res://assets/audio/impactMetal_000.ogg"),
	"destroy":preload("res://assets/audio/explosionCrunch_000.ogg")}
func _ready() -> void:
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12
		add_child(voice)
		pool.append(voice)
func play_effect(kind: String) -> void:
	if muted or DisplayServer.get_name() == "headless" or not EFFECTS.has(kind):
		return
	var voice := pool[cursor]
	cursor = (cursor+1)%pool.size()
	voice.pitch_scale = 1.6 if kind == "reload" else (1.25 if kind == "ready" else 1.0)
	voice.volume_db = -18 if kind in ["reload","ready"] else -12
	voice.stream = EFFECTS[kind]
	voice.play()

func _exit_tree() -> void:
	for voice in pool: voice.stop()
