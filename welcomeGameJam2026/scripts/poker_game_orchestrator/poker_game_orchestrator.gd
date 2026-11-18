class_name PokerGameOrchestrator
extends Node

signal emit_player_decision(player_id: String, action: PokerGameStateManager.PlayerAction, amount: int)

@export var player_controller: PlayerController
@export var cpu1_controller: CPUController
@export var cpu2_controller: CPUController
@export var cpu3_controller: CPUController

@export var game_state: PokerGameStateManager
@export var deck: DeckManager

@export var end_game_screen: EndGameScreen
@export var help_screen: HelpScreen

var cpu_controllers: Dictionary = {}
var loaded_from_serialized_state: bool = false

func _ready() -> void:
	_validate_exports()

	emit_player_decision.connect(game_state._on_player_action)

	game_state.game_state_changed.connect(_on_game_state_changed)
	game_state.request_card_draw.connect(_on_request_card_draw)
	game_state.request_player_action.connect(_on_request_player_action)
	game_state.request_hand_evaluation.connect(_on_hand_evaluation_request)
	game_state.showdown_winners.connect(_on_showdown_winners)
	game_state.send_winnings.connect(_on_send_winnings)

	if is_instance_valid(player_controller) and is_instance_valid(player_controller.player_ui):
		game_state.community_cards_changed.connect(player_controller.player_ui.update_table_cards_display)
		player_controller.player_ui.help_button.pressed.connect(_on_help_button_pressed)

	game_state.register_player(player_controller.player_id)
	player_controller.max_fishes = Preloads.Instance.max_fishes
	player_controller.starting_cash = Preloads.Instance.initial_cash
	player_controller.raise_amount = Preloads.Instance.minimum_raise
	player_controller.submit_player_decision.connect(_on_submit_player_decision)
	player_controller.going_fishing.connect(_on_player_going_fishing)

	_setup_cpu_player(cpu1_controller)
	_setup_cpu_player(cpu2_controller)
	_setup_cpu_player(cpu3_controller)

	load_serialized_state()
	if is_instance_valid(deck) and deck.deck.size() == 0:
		deck._initialize_deck()

	if not loaded_from_serialized_state:
		game_state.new_play()

func serialize_and_save_state() -> void:
	var state: Dictionary = {
		"player_controller": player_controller.serialize(),
		"cpu1_controller": cpu1_controller.serialize(),
		"cpu2_controller": cpu2_controller.serialize(),
		"cpu3_controller": cpu3_controller.serialize(),
		"game_state": game_state.serialize(),
		"deck": deck.serialize()
	}

	Preloads.serialized_state = state

# TODO: Revisit serialization when fishing game is completed
func load_serialized_state() -> void:
	var state: Dictionary = Preloads.serialized_state
	if state.keys().size() == 0 and state.values().size() == 0:
		return
	loaded_from_serialized_state = true

	player_controller.load_state(state.get("player_controller", {}))
	cpu1_controller.load_state(state.get("cpu1_controller", {}))
	cpu2_controller.load_state(state.get("cpu2_controller", {}))
	cpu3_controller.load_state(state.get("cpu3_controller", {}))
	deck.load_state(state.get("deck", {}))
	game_state.load_state(state.get("game_state", {}))

func _setup_cpu_player(cpu_controller: CPUController) -> void:
	cpu_controller.submit_player_decision.connect(_on_submit_player_decision)
	cpu_controller.max_fishes = Preloads.Instance.max_fishes
	cpu_controller.starting_cash = Preloads.Instance.initial_cash
	cpu_controller.raise_amount = Preloads.Instance.minimum_raise

	game_state.register_player(cpu_controller.player_id)
	cpu_controllers[cpu_controller.player_id] = cpu_controller

# TODO: move to async/animation controlled draw, decision and action flow
func _on_request_card_draw(player_ids: PackedStringArray) -> void:
	print("Requesting card draw for players: %s" % [player_ids])
	for player_id in player_ids:
		if player_id == player_controller.player_id:
			if player_controller.can_draw_card(2):
				player_controller.add_card_to_hand(deck.draw(2))
			player_controller.remaining_fishes = player_controller.max_fishes
		elif cpu_controllers.has(player_id):
			if cpu_controllers[player_id].can_draw_card(2):
				cpu_controllers[player_id].add_card_to_hand(deck.draw(2))
			cpu_controllers[player_id].remaining_fishes = cpu_controllers[player_id].max_fishes
			print("CPU player hand: %s" % [cpu_controllers[player_id].player_hand])

	game_state.game_state_change(PokerGameStateManager.GameState.PLAYER_TURN)

func _on_request_player_action(player_id: String) -> void:
	print("Requesting player action for player: %s" % [player_id])
	if player_id == player_controller.player_id:
			player_controller.start_player_turn(game_state.current_bet, game_state.get_player_bet(player_id))
	elif cpu_controllers.has(player_id):
		cpu_controllers[player_id].make_decision(game_state.community_cards, game_state.current_bet, game_state.get_player_bet(player_id))

func _on_hand_evaluation_request(player_id: String, community_cards: Array) -> void:
	print("Requesting hand evaluation for player: %s with community cards: %s" % [player_id, community_cards])
	if player_id == player_controller.player_id:
		var evaluation = player_controller.evaluate_hand(community_cards)
		var score = evaluation.get("hand_score", 0)
		print("Player %s evaluated hand with score: %d" % [player_id, score])
		print("Combination: %s" % [evaluation.get("combination", "")])
		print("Top Cards: %s" % [evaluation.get("highest_cards", [])])
		game_state.submit_hand_evaluation(player_id, score)
	elif cpu_controllers.has(player_id):
		var evaluation = cpu_controllers[player_id].evaluate_hand(community_cards)
		var score = evaluation.get("hand_score", 0)
		print("CPU player %s evaluated hand with score: %d" % [player_id, score])
		print("Combination: %s" % [evaluation.get("combination", "")])
		print("Top Cards: %s" % [evaluation.get("highest_cards", [])])
		game_state.submit_hand_evaluation(player_id, score)

func _on_submit_player_decision(player_id: String, action: PokerGameStateManager.PlayerAction, amount: int) -> void:
	emit_player_decision.emit(player_id, action, amount)

func _on_showdown_winners(winner_ids: PackedStringArray) -> void:
	print("Showdown winners: %s" % [winner_ids])

	for cpu_controller in cpu_controllers.values():
		cpu_controller.clear_hand()

	if _check_end_game():
		get_tree().paused = true
		return

	await get_tree().create_timer(5.0).timeout
	player_controller.clear_hand()
	game_state.new_play()

func _on_send_winnings(winner_id: String, amount: int) -> void:
	print("Player %s received winnings: %d" % [winner_id, amount])
	if winner_id == player_controller.player_id:
		player_controller.cash += amount
		player_controller.already_raised = false
	elif cpu_controllers.has(winner_id):
		var cpu_controller = cpu_controllers.get(winner_id)
		cpu_controller.cash += amount
		cpu_controller.already_raised = false

		if cpu_controller.cash <= 0 and game_state.get_player_state(cpu_controller.player_id) != PokerGameStateManager.PlayerState.OUT:
			game_state.player_state_change(cpu_controller.player_id, PokerGameStateManager.PlayerState.OUT)

func _on_game_state_changed(_old_state: int, _new_state: int) -> void:
	player_controller.already_raised = false
	for cpu_controller in cpu_controllers.values():
		cpu_controller.already_raised = false

func _check_end_game() -> bool:
	if player_controller.cash <= 0:
		end_game_screen.show_lost()
		return true
	elif cpu_controllers.values().all(func(c): return c.cash <= 0):
		end_game_screen.show_won()
		return true
	return false

func _on_player_going_fishing(discarded_card: String) -> void:
	deck.reshuffle(discarded_card)
	serialize_and_save_state()
	get_tree().change_scene_to_packed(Preloads.fishing_scene)

func _on_help_button_pressed() -> void:
	help_screen.visible = true

func _validate_exports() -> void:
	if not is_instance_valid(help_screen):
		push_error("Help screen is not assigned or invalid.")
	if not is_instance_valid(end_game_screen):
		push_error("End game screen is not assigned or invalid.")
	if not is_instance_valid(player_controller):
		push_error("Player controller is not assigned or invalid.")
	if not is_instance_valid(deck):
		push_error("Deck is not assigned or invalid.")
