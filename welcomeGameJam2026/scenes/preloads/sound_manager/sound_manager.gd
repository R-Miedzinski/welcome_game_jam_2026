class_name SoundManager
extends Node

static var Instance: SoundManager = null:
  set(value):
    if Instance != null and Instance != value:
      Instance.queue_free()
    Instance = value

@onready var soundtrack_player: AudioStreamPlayer = %SoundtrackPlayer
@onready var sfx_player: AudioStreamPlayer = %SFXPlayer
@onready var ui_player: AudioStreamPlayer = %UIPlayer

func _ready() -> void:
    Instance = self

func play_soundtrack(stream: AudioStream) -> void:
  soundtrack_player.stream = stream
  soundtrack_player.play()

func play_sfx(stream: AudioStream) -> void:
  sfx_player.stream = stream
  sfx_player.play()

func play_ui(stream: AudioStream) -> void:
  ui_player.stream = stream
  ui_player.play()

func set_master_volume(volume: float) -> void:
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume)

func set_soundtrack_volume(volume: float) -> void:
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Soundtrack"), volume)

func set_sfx_volume(volume: float) -> void:
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume)

func set_ui_volume(volume: float) -> void:
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), volume)
