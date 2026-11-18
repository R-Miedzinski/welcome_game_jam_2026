class_name Preloads 
extends Node

const WINDOW_WIDTH_VPX: int = 1152
const WINDOW_HEIGHT_VPX: int = 648

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
@export var fish_sprites: Dictionary[String, SpriteFrames] = {

}
@export var sprite_animation_names: Dictionary[String, String] = {
	"default": "default",
	"static": "static"
}

@export var initial_cash: int = 1000
@export var blind_bet: int = 10
@export var minimum_raise: int = 25
@export var max_fishes: int = 1

var game_seed: int = 0

func _ready() -> void:
	Instance = self
	reset_game_data()

func reset_game_data() -> void:
	serialized_state = {}

	_set_seed()
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

func get_junk_sprite() -> SpriteFrames:
	if junk_sprites.size() > 0:
		return junk_sprites[randi() % junk_sprites.size()]
	push_error("Junk sprite not found.")
	return null

func _set_seed() -> void:
	game_seed = 0 # Time.get_ticks_usec()
