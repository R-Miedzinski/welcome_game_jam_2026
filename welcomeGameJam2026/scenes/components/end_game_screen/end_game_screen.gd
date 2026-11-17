class_name EndGameScreen
extends Control

@onready var won_label = %WonLabel
@onready var lost_label = %LostLabel

@onready var menu_button_main_menu = %MenuButtonMainMenu
@onready var menu_button_quit_game = %MenuButtonQuitGame

func _ready() -> void:
	visible = false
	won_label.visible = false
	lost_label.visible = false

	menu_button_main_menu.pressed.connect(_on_main_menu_pressed)
	menu_button_quit_game.pressed.connect(_on_quit_game_pressed)

func show_won() -> void:
	visible = true
	won_label.visible = true
	lost_label.visible = false

func show_lost() -> void:
	visible = true
	won_label.visible = false
	lost_label.visible = true

func _on_main_menu_pressed() -> void:
	Preloads.Instance.reset_game_data()
	get_tree().change_scene_to_packed(Preloads.menu_scene)

func _on_quit_game_pressed() -> void:
	get_tree().quit()
