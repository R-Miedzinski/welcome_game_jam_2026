class_name PokerTable
extends Node3D

@export var soundtrack: AudioStream

func _ready() -> void:
	if soundtrack:
		SoundManager.play_soundtrack(soundtrack)
