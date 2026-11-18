class_name Preloads 
extends Node

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

static var saved_deck: String = "";
static var serialized_state: Dictionary = {}

var game_seed: int = 0

func _ready() -> void:
  Instance = self
  reset_game_data()

func reset_game_data() -> void:
  saved_deck = ""
  serialized_state = {}

  _set_seed()
  seed(game_seed)

func _set_seed() -> void:
  game_seed = 0 # Time.get_ticks_usec()