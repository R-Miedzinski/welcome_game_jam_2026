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

var selected: bool = false:
	set(value):
		selected = value
		if value:
			_begin_hover()
		else:
			_end_hover()

func _ready() -> void:
	if is_instance_valid(button):
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(_on_mouse_entered)
		button.mouse_exited.connect(_on_mouse_exited)

	_refresh_display()

func _refresh_display() -> void:
	if is_instance_valid(card_label):
		card_label.text = card_string

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
