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

var game_seed: int = 0

func _ready() -> void:
  Instance = self
  reset_game_data()

func reset_game_data() -> void:
  serialized_state = {}

  _set_seed()
  seed(game_seed)

func _set_seed() -> void:
  game_seed = 0 # Time.get_ticks_usec()