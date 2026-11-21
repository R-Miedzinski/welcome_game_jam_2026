class_name Preloads 
extends Node

const WINDOW_WIDTH_VPX: int = 1920
const WINDOW_HEIGHT_VPX: int = 1080

static var Instance: Preloads:
	set(value):
		if Instance != null and Instance != value:
			Instance.queue_free()
		Instance = value

static var Poker = preload("res://scripts/poker_engine/poker_engine.gd"):
		set(value):
			pass

static var poker_scene: PackedScene = preload("res://scenes/views/poker_table/poker_table.tscn")
static var fishing_scene: PackedScene = preload("res://scenes/views/fishing_game/fishing_game.tscn")
static var menu_scene: PackedScene = preload("res://scenes/views/main_menu/main_menu.tscn")

static var fish_scene: PackedScene = preload("res://scenes/components/fish/fish.tscn")
static var junk_scene: PackedScene = preload("res://scenes/components/junk/junk.tscn")

static var serialized_state: Dictionary = {}

@export var junk_sprites: Array[SpriteFrames] = []
@export var fish_sprites: Dictionary[String, SpriteFrames] = {}
@export var fish_label_offsets: Dictionary[String, Vector2] = {
	"C": Vector2.ZERO,
	"D": Vector2.ZERO,
	"H": Vector2.ZERO,
	"S": Vector2.ZERO,
	"JC": Vector2.ZERO,
	"JD": Vector2.ZERO,
	"JH": Vector2.ZERO,
	"JS": Vector2.ZERO,
	"QC": Vector2.ZERO,
	"QD": Vector2.ZERO,
	"QH": Vector2.ZERO,
	"QS": Vector2.ZERO,
	"KC": Vector2.ZERO,
	"KD": Vector2.ZERO,
	"KH": Vector2.ZERO,
	"KS": Vector2.ZERO
}
@export var sprite_animation_names: Dictionary[String, String] = {
	"default": "default",
	"static": "static"
}

@export var game_options: Dictionary[String, Variant] = {
	"starting_cash": 1000,
	"blind_bet": 10,
	"raise_amount": 25,
	"max_fishes": 1,
	"seed": "0",
	"language": "eng"
}:
	set (value):
		game_options = value
		_update_game_options()

@export var audio_options: Dictionary[String, Variant] = {
	"master": 100.0,
	"sfx": 100.0,
	"soundtrack": 100.0,
	"ui": 100.0,
	"voicelines": 100.0
}: 
	set(value):
		audio_options = value
		_update_audio_options()

var game_seed: int = 0

func _ready() -> void:
	Instance = self
	reset_game_data()
	_update_game_options()
	_update_audio_options()

func reset_game_data() -> void:
	serialized_state = {}

	_set_seed()
	_set_language()
	seed(game_seed)

func get_fish_sprite(card_string: String) -> SpriteFrames:
	if card_string.length() < 2:
		push_warning("Invalid card string: %s" % [card_string])
		return null

	if fish_sprites.has(card_string):
		return fish_sprites.get(card_string)
	elif fish_sprites.has(card_string[1]):
		return fish_sprites.get(card_string[1])
	push_error("Fish sprite not found for card string: %s" % [card_string])
	return null

func get_fish_label_offset(card_string: String) -> Vector2:
	if card_string.length() < 2:
		push_warning("Invalid card string: %s" % [card_string])
		return Vector2.ZERO

	if fish_label_offsets.has(card_string):
		return fish_label_offsets.get(card_string)
	elif fish_label_offsets.has(card_string[1]):
		return fish_label_offsets.get(card_string[1])
	push_error("Fish label offset not found for card string: %s" % [card_string])
	return Vector2.ZERO

func get_junk_sprite() -> SpriteFrames:
	if junk_sprites.size() > 0:
		return junk_sprites[randi() % junk_sprites.size()]
	push_error("Junk sprite not found.")
	return null

func _set_seed() -> void:
	game_seed = game_options.get("seed", "0").hash()

func _set_language() -> void:
	var language = game_options.get("language", "eng")
	TranslationServer.set_locale(language)

func _update_game_options() -> void:
	_set_seed()
	_set_language()

func _update_audio_options() -> void:
	print("Updating audio options: %s" % audio_options)
	SoundManager.set_master_volume(audio_options.get("master", 100.0))
	SoundManager.set_sfx_volume(audio_options.get("sfx", 100.0))
	SoundManager.set_soundtrack_volume(audio_options.get("soundtrack", 100.0))
	SoundManager.set_ui_volume(audio_options.get("ui", 100.0))
	SoundManager.set_voicelines_volume(audio_options.get("voicelines", 100.0))
