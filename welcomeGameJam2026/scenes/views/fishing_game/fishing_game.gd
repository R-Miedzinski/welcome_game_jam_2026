extends Node2D

@onready var debug_timer: Timer = %DebugTimer

func _ready() -> void:
	debug_timer.timeout.connect(_on_debug_timeout)


func _on_debug_timeout() -> void:
	print("Debug timer timeout.")
	get_tree().change_scene_to_packed(Preloads.poker_scene)
