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

var cpu_controllers: Dictionary = {}
var loaded_from_serialized_state: bool = false

func _ready() -> void:
	emit_player_decision.connect(game_state._on_player_action)

	game_state.request_card_draw.connect(_on_request_card_draw)
	game_state.request_player_action.connect(_on_request_player_action)
	game_state.request_hand_evaluation.connect(_on_hand_evaluation_request)
	game_state.showdown_winners.connect(_on_showdown_winners)
	if is_instance_valid(player_controller) and is_instance_valid(player_controller.player_ui):
		game_state.community_cards_changed.connect(player_controller.player_ui.update_table_cards_display)

	game_state.register_player(player_controller.player_id)
	game_state.register_player(cpu1_controller.player_id)
	game_state.register_player(cpu2_controller.player_id)
	game_state.register_player(cpu3_controller.player_id)

	player_controller.submit_player_decision.connect(_on_submit_player_decision)
	player_controller.going_fishing.connect(_on_player_going_fishing)

	cpu_controllers[cpu1_controller.player_id] = cpu1_controller
	cpu_controllers[cpu2_controller.player_id] = cpu2_controller
	cpu_controllers[cpu3_controller.player_id] = cpu3_controller

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

	game_state.game_state_change(PokerGameStateManager.GameState.DEALING)

func _on_request_player_action(player_id: String) -> void:
	print("Requesting player action for player: %s" % [player_id])
	if player_id == player_controller.player_id:
			player_controller.start_player_turn(game_state.current_bet, game_state.get_player_bet(player_id))
	elif cpu_controllers.has(player_id):
		var decision = cpu_controllers[player_id].make_decision(game_state.community_cards, game_state.current_bet, game_state.get_player_bet(player_id))
		print("CPU player %s made decision: %s" % [player_id, decision])
		emit_player_decision.emit(player_id, decision[0], decision[1])

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
	var per_player_winnings: int = game_state.pot / winner_ids.size() 
	game_state.pot = 0
	
	for winner_id in winner_ids:
		print("Player %s won %d" % [winner_id, per_player_winnings])
		if winner_id == player_controller.player_id:
			player_controller.cash += per_player_winnings
		elif cpu_controllers.has(winner_id):
			cpu_controllers[winner_id].cash += per_player_winnings

	for cpu_controller in cpu_controllers.values():
		cpu_controller.already_raised = false
		cpu_controller.clear_hand()

		if cpu_controller.cash <= 0 and game_state.get_player_state(cpu_controller.player_id) != PokerGameStateManager.PlayerState.OUT:
			game_state.player_state_change(cpu_controller.player_id, PokerGameStateManager.PlayerState.OUT)

	if _check_end_game():
		get_tree().paused = true
		return

	await get_tree().create_timer(5.0).timeout
	player_controller.clear_hand()
	game_state.new_play()

func _check_end_game() -> bool:
	if player_controller.cash <= 0:
		end_game_screen.show_lost()
		return true
	elif cpu_controllers.values().all(func(c): return c.cash <= 0):
		end_game_screen.show_won()
		return true
	return false

func _on_player_going_fishing(discarded_card: String) -> void:
	print("Player is going fishing.")
	deck.reshuffle(discarded_card)
	serialize_and_save_state()
	get_tree().change_scene_to_packed(Preloads.fishing_scene)
