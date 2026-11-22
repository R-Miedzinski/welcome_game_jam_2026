class_name SealProp
extends Node3D

signal ate_fish()

@export var animate: bool = true
@export var eat_animation: String = "eat"
@export var idle_animation: String = "idle"
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if animate:
		anim_player.play("idle")
		anim_player.animation_finished.connect(_on_animation_finished)

func eat_fish() -> void:
	if animate:
		anim_player.play(eat_animation)

func _on_animation_finished(anim_name: String) -> void:
	if animate and anim_name == eat_animation:
		anim_player.play(idle_animation)
		ate_fish.emit()