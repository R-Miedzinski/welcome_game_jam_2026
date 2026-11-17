class_name FishingHook
extends Node2D

signal caught_fish(card: String)
signal caught_junk()

@onready var hitbox = %Hitbox

func _ready() -> void:
	hitbox.area_entered.connect(_on_area_entered)

func move(offset: Vector2) -> void:
	position.x = clampf(position.x + offset.x, 0, Preloads.WINDOW_WIDTH_VPX)
	position.y = clampf(position.y + offset.y, 0, Preloads.WINDOW_HEIGHT_VPX)

func _on_area_entered(body: Node) -> void:
	if body.is_in_group("fish"):
		caught_fish.emit(body.get_parent().card_string)
	elif body.is_in_group("junk"):
		caught_junk.emit()