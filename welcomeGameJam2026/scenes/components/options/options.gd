class_name Options
extends Control


@onready var game_form: Form = %GameForm
@onready var audio_form: Form = %AudioForm

@onready var apply_changes_button: Button = %ApplyChangesButton
@onready var cancel_button: Button = %CancelButton

func _ready() -> void:
	apply_changes_button.pressed.connect(_on_apply_changes_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	game_form.form_submitted.connect(_on_game_form_submitted)
	audio_form.form_submitted.connect(_on_audio_form_submitted)

func open() -> void:
	_reset_forms()
	visible = true

func _reset_forms() -> void:
	game_form.setup_form_data(Preloads.Instance.game_options)
	audio_form.setup_form_data(Preloads.Instance.audio_options)

func _on_apply_changes_pressed() -> void:
	if not game_form.is_valid() or not audio_form.is_valid():
		push_error("Cannot apply options: a form contains invalid data.")
		return
	game_form.submit()
	audio_form.submit()
	visible = false

func _on_cancel_pressed() -> void:
	_reset_forms()
	visible = false

func _on_game_form_submitted(_form_name: String, form_data: Dictionary) -> void:
	Preloads.Instance.game_options.assign(form_data)
	Preloads.Instance._update_game_options()

func _on_audio_form_submitted(_form_name: String, form_data: Dictionary) -> void:
	Preloads.Instance.audio_options.assign(form_data)
	Preloads.Instance._update_audio_options()
