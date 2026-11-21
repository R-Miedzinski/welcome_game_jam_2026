class_name FishingGame
extends Control

@onready var sequence_controller: AnimationPlayer = %SequenceController
@onready var deck: DeckManager = %DeckManager
@onready var fishing_orchestrator: FishingOrchestrator = %FishingOrchestrator
@onready var hook_controller: HookController = %HookController

func _ready() -> void:
	sequence_controller.animation_finished.connect(_on_animation_finished)
	fishing_orchestrator.exit_from_fishing_request.connect(_on_exit_from_fishing_request)

	sequence_controller.play("move_hook_to_start")

	_load_serialized_state()

func _load_serialized_state() -> void:
	deck.load_state(Preloads.serialized_state.get("deck", ""))

	if is_instance_valid(deck) and deck.deck.size() == 0:
		deck._initialize_deck()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "move_hook_to_start":
		hook_controller.is_active = true
		fishing_orchestrator.start()

func _on_exit_from_fishing_request() -> void:
	call_deferred("_go_back_to_table_scene")

func _go_back_to_table_scene() -> void:
	get_tree().change_scene_to_packed(Preloads.poker_scene)
