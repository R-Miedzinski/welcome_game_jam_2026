class_name NPC
extends Node3D

signal animation_finished(anim_name: String)

@export_category("Animation Voicelines")
@export var fish_voicelines: Array[AudioStream] = []
@export var call_voicelines: Array[AudioStream] = []
@export var raise_voicelines: Array[AudioStream] = []
@export var fold_voicelines: Array[AudioStream] = []
@export var out_voicelines: Array[AudioStream] = []
@export var all_in_voicelines: Array[AudioStream] = []

@export_category("Other Voicelines")
@export var win_voicelines: Array[AudioStream] = []
@export var lose_voicelines: Array[AudioStream] = []
@export var split_voicelines: Array[AudioStream] = []

@export_category("Voiceline Settings")
@export var voiceline_volume_offset_db: float = 0.0

var local_random: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var anim_to_vo_map: Dictionary[String, Array] = {
	"fish": fish_voicelines,
	"call": call_voicelines,
	"raise": raise_voicelines,
	"fold": fold_voicelines,
	"out": out_voicelines,
	"all_in": all_in_voicelines,
	"split": split_voicelines,
	"win": win_voicelines,
	"lose": lose_voicelines
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

	play_voiceline_for_animation(anim_name)

	animation_player.play(anim_name)

func play_voiceline_for_animation(anim_name: String) -> void:
	var voicelines = anim_to_vo_map.get(anim_name, [])
	if voicelines.size() > 0:
		var voiceline = voicelines[local_random.randi_range(0, voicelines.size() - 1)]
		SoundManager.play_voiceline(voiceline, voiceline_volume_offset_db)

func play_lose_voiceline() -> void:
	play_voiceline_for_animation("lose")

func play_win_voiceline() -> void:
	play_voiceline_for_animation("win")

func play_split_voiceline() -> void:
	play_voiceline_for_animation("split")

func _on_animation_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)
