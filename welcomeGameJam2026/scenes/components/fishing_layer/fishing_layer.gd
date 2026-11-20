class_name FishingLayer
extends Area2D

signal layer_moved_to_bottom()

@export var junk_weight: int = 1
@export var fish_weight: int = 2
@export var max_spawns_per_layer: int = 3
@export var min_spawns_per_layer: int = 1
@export_range(1, 100, 1) var spawn_columns: int = 4
@export_range(1, 100, 1) var spawn_rows: int = 1
@export var background_texture: Texture2D

@export_category("Speed")
@export() var distance_from_center_scaling: Vector2 = Vector2(0.5, 1.5)
@export var distance_from_center_factor: float = 0.5
@export_range(0.0, 100.0, 1.0) var speed_randomness_percent: float = 20.0
@export_range(0.0, 100.0, 1.0) var junk_speed_percent: float = 25.0


var speed: float = 100.0

var width: int = 1:
  set(value):
    width = value
    if is_instance_valid(collision_shape):
      print("Setting collision shape width to: ", width)
      collision_shape.shape.size.x = width
      collision_shape.position.x = width / 2.0
    if is_instance_valid(background):
      _update_background()
var height: int = 1:
  set(value):
    height = value
    if is_instance_valid(collision_shape):
      print("Setting collision shape height to: ", height)
      collision_shape.shape.size.y = height
      collision_shape.position.y = height / 2.0
    if is_instance_valid(background):
      _update_background()

var deck: DeckManager
var fish_in_layer: Array = []
var junk_in_layer: Array = []

@onready var collision_shape = %CollisionShape2D
@onready var background = %Sprite2D

func _ready() -> void:
  _update_collision_shape()
  _update_background()

func spawn_fish() -> void:
  if spawn_columns <= 0 or spawn_rows <= 0:
    push_error("Fishing layer spawn grid must have at least one row and column.")
    return
  if width <= 0 or height <= 0:
    push_error("Fishing layer must have a positive width and height.")
    return

  var spawns = int(randf_range(min_spawns_per_layer, max_spawns_per_layer + 1))
  var cells: Array[Vector2i] = []
  for row in range(spawn_rows):
    for column in range(spawn_columns):
      cells.append(Vector2i(column, row))
  cells.shuffle()
  if spawns > cells.size():
    push_warning("Fishing layer spawn count exceeds available cells; limiting spawns to %d." % cells.size())
    spawns = cells.size()

  var cards_to_spawn = deck.peek_random(spawns).split(",")
  var cell_size = Vector2(float(width) / spawn_columns, float(height) / spawn_rows)

  for i in range(spawns):
    var decider = randf() * (junk_weight + fish_weight)
    var scene_instance
    var is_junk_spawn = decider < junk_weight
    if is_junk_spawn:
      # spawn junk
      scene_instance = Preloads.Instance.junk_scene.instantiate()
      call_deferred("add_child", scene_instance)
      junk_in_layer.append(scene_instance)
    else:
      # spawn fish
      scene_instance = Preloads.Instance.fish_scene.instantiate()
      call_deferred("add_child", scene_instance)
      scene_instance.card_string = cards_to_spawn[i]
      fish_in_layer.append(scene_instance)

    var cell = cells[i]
    scene_instance.position = (Vector2(cell) + Vector2(randf_range(-0.2, 1), randf_range(0.10, 0.90))) * cell_size
    
    var distance_from_center = absf(scene_instance.position.x - width * 0.5) / (width * 0.5)
    var distance_factor = lerpf(distance_from_center_scaling.x, distance_from_center_scaling.y, distance_from_center)
    var randomness = speed_randomness_percent / 100.0
    scene_instance.speed.x = speed * distance_from_center_factor * distance_factor * randf_range(1.0 - randomness, 1.0 + randomness)
    if is_junk_spawn:
      scene_instance.speed.x = scene_instance.speed.x * (junk_speed_percent / 100.0)
    scene_instance.is_moving = true

func move_to_bottom() -> void:
  for fish in fish_in_layer:
    fish.queue_free()
  for junk in junk_in_layer:
    junk.queue_free()
  fish_in_layer.clear()
  junk_in_layer.clear()

  spawn_fish()
  layer_moved_to_bottom.emit()

func _update_collision_shape() -> void:
  if is_instance_valid(collision_shape):
    collision_shape.shape.size = Vector2(width, height)
    collision_shape.position = Vector2(width / 2.0, height / 2.0)

func _update_background() -> void:
  if background_texture and is_instance_valid(background):
    background.texture = background_texture
    var texture_size = Vector2(background_texture.get_size())
    if texture_size.x > 0 and texture_size.y > 0:
      background.scale = Vector2(width, height) / texture_size
      background.position = Vector2(width / 2.0, height / 2.0) if background.centered else Vector2.ZERO
