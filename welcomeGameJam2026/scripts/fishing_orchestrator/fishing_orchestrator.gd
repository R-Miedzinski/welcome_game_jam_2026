class_name FishingOrchestrator
extends Node

signal exit_from_fishing_request()

@export var fishing_hook: FishingHook
@export var deck: DeckManager
@export var fishing_layers_parent: Node
@export var fishing_layer_despawn: Area2D
@export var fishing_layer_spawn: Node2D

@export var starting_speed: float = 100.0
@export var speed_increment: float = 10.0
@export var speed_multiplier: float = 1.5

var player_controller_modifier: float = 1.0
var is_sped_up: bool = false
var current_speed: float = 0.0:
	set(value):
		current_speed = value
		for layer in fishing_layers:
			layer.speed = current_speed
	get:
		return current_speed * player_controller_modifier

var fishing_layers: Array[FishingLayer] = []
var layer_wrap_counts: Array[int] = []
var layer_height: float = 0
var scroll_distance: float = 0.0

func _ready() -> void:
	fishing_hook.caught_fish.connect(_on_caught_fish)
	fishing_hook.caught_junk.connect(_on_caught_junk)

	if is_instance_valid(fishing_layers_parent):
		_setup_fishing_layers()

func _process(delta: float) -> void:
	if fishing_layers.size() < 3:
		return

	scroll_distance += current_speed * delta
	var wrap_distance = float(layer_height * fishing_layers.size())
	for i in range(fishing_layers.size()):
		var layer = fishing_layers[i]
		var starting_y = (i - 0.5) * layer_height
		var wraps = max(0, ceil((scroll_distance - (starting_y - fishing_layer_despawn.position.y)) / wrap_distance))
		layer.position.y = starting_y - scroll_distance + wraps * wrap_distance
		while layer_wrap_counts[i] < wraps:
			layer_wrap_counts[i] += 1
			layer.move_to_bottom()

func start() -> void:
	current_speed = starting_speed

func _on_caught_fish(card: String) -> void:
	deck.take_out(card)
	Preloads.serialized_state["deck"] = deck.serialize()
	_add_card_to_player_state(card)

	exit_from_fishing_request.emit()

func _on_caught_junk() -> void:
	var card = deck.draw()
	Preloads.serialized_state["deck"] = deck.serialize()
	_add_card_to_player_state(card)

	exit_from_fishing_request.emit()

func _add_card_to_player_state(card: String) -> void:
	if Preloads.serialized_state.has("player_controller"):
		var player_controller_state = Preloads.serialized_state.get("player_controller", {})
		player_controller_state["player_hand"].append(card)
		Preloads.serialized_state["player_controller"] = player_controller_state

func _setup_fishing_layers() -> void:
	for layer in fishing_layers_parent.get_children():
		if layer is FishingLayer:
			fishing_layers.append(layer)

	if fishing_layers.size() < 3:
		push_error("Not enough valid fishing layers found!")
		return

	var layer_width = Preloads.Instance.WINDOW_WIDTH_VPX
	layer_height = float(Preloads.Instance.WINDOW_HEIGHT_VPX) / float(fishing_layers.size() - 2.0)
	fishing_layer_spawn.position = Vector2(0, (fishing_layers.size() - 1.5) * layer_height)
	fishing_layer_despawn.position = Vector2(0, -layer_height * 1.5)
	for i in range(fishing_layers.size()):
		var layer = fishing_layers[i]
		layer_wrap_counts.append(0)
		layer.width = layer_width
		layer.height = layer_height
		layer.position = Vector2(0, (i - 0.5) * layer_height)

		layer.speed = current_speed
		layer.deck = deck
		layer.layer_moved_to_bottom.connect(_on_layer_moved_to_bottom)

func _on_layer_moved_to_bottom() -> void:
	current_speed = current_speed/player_controller_modifier + speed_increment
	speed_increment *= speed_multiplier
