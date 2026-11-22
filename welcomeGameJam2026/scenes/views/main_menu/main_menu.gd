class_name MainMenu 
extends Control

@export var menu_soundtrack: AudioStream

@onready var play_button: Button = %MenuButtonStartGame
@onready var options_button: Button = %MenuButtonOptions
@onready var quit_button: Button = %MenuButtonQuitGame

@onready var options: Options = %Options

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	options.visible = false

	if menu_soundtrack:
		SoundManager.play_soundtrack(menu_soundtrack)

func _on_play_pressed() -> void:
	Preloads.Instance.reset_game_data()
	get_tree().paused = false
	get_tree().change_scene_to_packed(Preloads.Instance.poker_scene)
	
func _on_options_pressed() -> void:
	options.open()

func _on_quit_pressed() -> void:
	get_tree().quit()
