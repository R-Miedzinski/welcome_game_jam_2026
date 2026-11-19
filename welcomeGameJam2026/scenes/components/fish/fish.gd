class_name Fish
extends Node2D

signal pressed()
signal mouse_entered()
signal mouse_exited()

@export var card_string: String:
	set(value):
		card_string = value
		_refresh_display()
@export var selectable: bool = false

@onready var card_label = %CardLabel
@onready var button = %Button
@onready var sprite: AnimatedSprite2D = %Sprite

var is_moving: bool = false
var speed: Vector2 = Vector2(100.0, 0)
var direction: int = 1

var initial_label_position: Vector2 = Vector2.ZERO

var selected: bool = false:
	set(value):
		selected = value
		if value:
			_begin_hover()
		else:
			_end_hover()

func _ready() -> void:
	if is_instance_valid(button) and not is_moving:
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(_on_mouse_entered)
		button.mouse_exited.connect(_on_mouse_exited)

	if is_instance_valid(card_label):
		initial_label_position = card_label.position

	if is_moving:
		button.disabled = true
		direction = sign(Preloads.Instance.WINDOW_WIDTH_VPX / 2 - position.x)

	_refresh_display()

func _process(delta: float) -> void:
	if is_moving:
		position.x += speed.x * direction * delta
		position.y -= speed.y *  delta

func _refresh_display() -> void:
	if is_instance_valid(card_label):
		card_label.text = card_string

	if is_instance_valid(sprite):
		sprite.sprite_frames = Preloads.Instance.get_fish_sprite(card_string)

		if sprite.sprite_frames == null: return
		sprite.animation = Preloads.Instance.sprite_animation_names.get("default") if is_moving else Preloads.Instance.sprite_animation_names.get("static")
		card_label.text = card_string[0]
		if card_label.text == "0":
			card_label.text = "10"

	if is_instance_valid(card_label):
		var offset = Preloads.Instance.get_fish_label_offset(card_string)
		card_label.position = initial_label_position + offset

func _begin_hover() -> void:
	if not selected and selectable:
		scale = Vector2(1.1, 1.1)

func _end_hover() -> void:
	if not selected and selectable:
		scale = Vector2(1, 1)

func _on_button_pressed() -> void:
	emit_signal("pressed")

func _on_mouse_entered() -> void:
	emit_signal("mouse_entered")
	_begin_hover()

func _on_mouse_exited() -> void:
	emit_signal("mouse_exited")
	_end_hover()
