class_name FishingLayer
extends Area2D

signal layer_moved_to_bottom()

@export var junk_weight: int = 1
@export var fish_weight: int = 2
@export var max_spawns_per_layer: int = 3
@export var min_spawns_per_layer: int = 1

var speed: float = 100.0
var spawn_position: Node2D

var width: int = 1:
  set(value):
    width = value
    if is_instance_valid(collision_shape):
      print("Setting collision shape width to: ", width)
      collision_shape.shape.size.x = width
      collision_shape.position.x = width / 2
var height: int = 1:
  set(value):
    height = value
    if is_instance_valid(collision_shape):
      print("Setting collision shape height to: ", height)
      collision_shape.shape.size.y = height
      collision_shape.position.y = height / 2

var deck: DeckManager
var fish_in_layer: Array = []
var junk_in_layer: Array = []

@onready var collision_shape = %CollisionShape2D

func _ready() -> void:
  area_entered.connect(_on_area_entered)

  _update_collision_shape()

func _process(delta: float) -> void:
  position.y -= speed * delta

func spawn_fish() -> void:
  var spawns = int(randf_range(min_spawns_per_layer, max_spawns_per_layer + 1))
  var cards_to_spawn = deck.peek_random(spawns).split(",")

  for i in range(spawns):
    var decider = randf() * (junk_weight + fish_weight)
    var scene_instance
    if decider < junk_weight:
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

    var side_offset = randf_range(0.00, 0.20)
    if randf() < 0.5:
      side_offset = 1 - side_offset
    scene_instance.position = collision_shape.position + Vector2((side_offset - 0.5) * width, randf() * height)
    
    scene_instance.speed.x = speed / 2
    scene_instance.is_moving = true

func _on_area_entered(area: Area2D) -> void:
  if area is FishingLayer:
    return

  for fish in fish_in_layer:
    fish.queue_free()
  for junk in junk_in_layer:
    junk.queue_free()
  fish_in_layer.clear()
  junk_in_layer.clear()

  position = spawn_position.position
  spawn_fish()
  layer_moved_to_bottom.emit()

func _update_collision_shape() -> void:
  if is_instance_valid(collision_shape):
    collision_shape.shape.size = Vector2(width, height)
    collision_shape.position = Vector2(width / 2, height / 2)
