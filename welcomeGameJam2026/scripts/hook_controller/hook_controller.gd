class_name HookController
extends Node


@export var hook_speed: float = 1.0
@export var movement_margin: float = 0.1
@export var hook: FishingHook

@export var player_controller_speed_modifier: float = 1.2
@export var fishing_orchestrator: FishingOrchestrator

var is_active: bool = false

func _ready() -> void:
	if not is_instance_valid(hook):
			push_error("HookController: hook is not assigned or invalid.")
			return

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hook) or not is_active:
			return

	fishing_orchestrator.player_controller_modifier = 1.0
	fishing_orchestrator.is_sped_up = false

	if Input.is_action_pressed("HookMoveLeft") and hook.position.x > movement_margin * Preloads.Instance.WINDOW_WIDTH_VPX:
			hook.move(Vector2(-hook_speed * delta, 0))
	elif Input.is_action_pressed("HookMoveRight") and hook.position.x < (1.0 - movement_margin) * Preloads.Instance.WINDOW_WIDTH_VPX:
			hook.move(Vector2(hook_speed * delta, 0))

	if Input.is_action_pressed("HookMoveDown"):
		fishing_orchestrator.player_controller_modifier = player_controller_speed_modifier
		fishing_orchestrator.is_sped_up = true
