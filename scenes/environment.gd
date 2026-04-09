extends WorldEnvironment


func _ready() -> void:
	for mechanic in [
		preload("res://objects/ship_lighting_mechanic.gd").new(),
		preload("res://objects/ship_audio_mechanic.gd").new(),
	]:
		add_child(mechanic)
