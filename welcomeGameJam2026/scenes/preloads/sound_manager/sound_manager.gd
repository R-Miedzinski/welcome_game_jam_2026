extends Node

@export var ui_button_sound: AudioStream
@export var sfx_global_offset_db: float = 0.0
@export var soundtrack_global_offset_db: float = 0.0
@export var ui_global_offset_db: float = 0.0
@export var voicelines_global_offset_db: float = 0.0

@onready var soundtrack_player_node: AudioStreamPlayer = %SoundtrackPlayer
@onready var sfx_bus_name: StringName = &"SFX"
@onready var ui_bus_name: StringName = &"UI"
@onready var voicelines_bus_name: StringName = &"VoiceLines"

var min_volume_db: float = -72.0
var max_volume_db: float = 6

var active_sfx_players: Array[AudioStreamPlayer] = []
var active_ui_players: Array[AudioStreamPlayer] = []
var active_voiceline_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_scan_existing_buttons(get_tree().root)

func play_soundtrack(stream: AudioStream) -> void:
	soundtrack_player_node.stream = stream
	if soundtrack_global_offset_db != 0.0:
		soundtrack_player_node.volume_db = soundtrack_global_offset_db
	soundtrack_player_node.play()

func play_sfx(stream: AudioStream, offset_db: float = 0.0, playback_speed: float = 0.0) -> void:
	_play_sound(stream, sfx_bus_name, active_sfx_players, offset_db, playback_speed)

func play_ui(stream: AudioStream, offset_db: float = 0.0, playback_speed: float = 0.0) -> void:
	_play_sound(stream, ui_bus_name, active_ui_players, offset_db, playback_speed)

func play_voiceline(stream: AudioStream, offset_db: float = 0.0, playback_speed: float = 0.0) -> void:
	_play_sound(stream, voicelines_bus_name, active_voiceline_players, offset_db, playback_speed)

func set_master_volume(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _scale_volume_to_db(volume))

func set_soundtrack_volume(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Soundtrack"), _scale_volume_to_db(volume))

func set_sfx_volume(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _scale_volume_to_db(volume))

func set_ui_volume(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), _scale_volume_to_db(volume))

func set_voicelines_volume(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("VoiceLines"), _scale_volume_to_db(volume))

func _play_sound(stream: AudioStream, bus_name: StringName, players_array: Array[AudioStreamPlayer], custom_volume_offset_db: float = 0.0, playback_speed: float = 0.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	if custom_volume_offset_db != 0.0:
		player.volume_db = custom_volume_offset_db

	if playback_speed != 0.0:
		player.pitch_scale = playback_speed

	if sfx_global_offset_db != 0.0 and bus_name == sfx_bus_name:
		player.volume_db += sfx_global_offset_db
	elif ui_global_offset_db != 0.0 and bus_name == ui_bus_name:
		player.volume_db += ui_global_offset_db
	elif voicelines_global_offset_db != 0.0 and bus_name == voicelines_bus_name:
		player.volume_db += voicelines_global_offset_db
	add_child(player)
	
	players_array.append(player)
	player.finished.connect(func(): _on_player_finished(player, players_array))
	
	player.play()

func _on_player_finished(player: AudioStreamPlayer, players_array: Array[AudioStreamPlayer]) -> void:
	players_array.erase(player)
	player.queue_free()

func _on_node_added(node: Node) -> void:
	if node is Button and not node.get_parent() is Fish:
		_on_button_entered(node)

func _scan_existing_buttons(node: Node) -> void:
	if node is Button and not node.get_parent() is Fish:
		_on_button_entered(node)

	for child in node.get_children():
		_scan_existing_buttons(child)

func _scale_volume_to_db(volume: float) -> float:
	var linear_volume := clampf(volume / 100.0, 0.0, 1.0)
	if linear_volume == 0.0:
		return min_volume_db
	return clampf(linear_to_db(linear_volume), min_volume_db, max_volume_db)

func _on_button_entered(button: Button) -> void:
	button.tree_exiting.connect(_on_button_exited.bind(button))
	button.pressed.connect(_on_button_pressed)

func _on_button_exited(button: Button) -> void:
	button.tree_exiting.disconnect(_on_button_exited.bind(button))
	button.pressed.disconnect(_on_button_pressed)

func _on_button_pressed() -> void:
	play_ui(ui_button_sound)
