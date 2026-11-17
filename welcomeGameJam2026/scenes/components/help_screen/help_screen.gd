class_name HelpScreen
extends Control

@onready var menu_button_close_help: Button = %MenuButtonCloseHelp

func _ready() -> void:
	visible = false
	menu_button_close_help.pressed.connect(_on_menu_button_close_help_pressed)

func _on_menu_button_close_help_pressed() -> void:
	visible = false
