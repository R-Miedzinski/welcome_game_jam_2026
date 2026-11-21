class_name NPC
extends Node3D

signal animation_finished(anim_name: String)

@export_category("Animation Voicelines")
@export var fish_voicelines: Array[AudioStream] = []
@export var call_voicelines: Array[AudioStream] = []
@export var raise_voicelines: Array[AudioStream] = []
@export var fold_voicelines: Array[AudioStream] = []
@export var out_voicelines: Array[AudioStream] = []

var local_random: RandomNumberGenerator = RandomNumberGenerator.new()
var anim_to_vo_map: Dictionary[String, Array] = {
	"fish": fish_voicelines,
	"call": call_voicelines,
	"raise": raise_voicelines,
	"fold": fold_voicelines,
	"out": out_voicelines
}

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	local_random.seed = Time.get_ticks_msec()

func play_animation(anim_name: String) -> void:
	if animation_player.current_animation == anim_name:
		return
	else:
		animation_player.stop()

	var voicelines = anim_to_vo_map.get(anim_name, [])
	if voicelines.size() > 0:
		var voiceline = voicelines[local_random.randi_range(0, voicelines.size() - 1)]
		SoundManager.play_voiceline(voiceline)

	animation_player.play(anim_name)

func _on_animation_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)