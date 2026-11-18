class_name Junk
extends Node2D

var is_moving: bool = false
var speed: Vector2 = Vector2(100.0, 0)
var direction: int = 1

@onready var sprite: AnimatedSprite2D = %Sprite

func _ready() -> void:
	if is_moving:
		direction = sign(Preloads.Instance.WINDOW_WIDTH_VPX / 2 - position.x)

	sprite.frames = Preloads.Instance.get_junk_sprite()

func _process(delta: float) -> void:
	if is_moving:
		position.x += speed.x * direction * delta
		position.y -= speed.y *  delta
