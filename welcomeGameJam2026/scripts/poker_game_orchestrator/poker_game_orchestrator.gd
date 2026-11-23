class_name PokerGameOrchestrator
extends Node

signal emit_player_decision(player_id: String, action: PokerGameStateManager.PlayerAction, amount: int)

@export_category("Controllers")
@export var player_controller: PlayerController
@export var cpu1_controller: CPUController
@export var cpu2_controller: CPUController
@export var cpu3_controller: CPUController

@export_category("Game and UI elements")
@export var game_state: PokerGameStateManager
@export var deck: DeckManager

@export var player_ui: PlayerUI
@export var end_game_screen: EndGameScreen
@export var help_screen: HelpScreen

@export_category("Message Feed Messages")
@export var npc_state_change_messages: Dictionary[PokerGameStateManager.PlayerState, String] = {
	PokerGameStateManager.PlayerState.OUT: "NPC_OUT_MSG",
}
@export var npc_action_messages: Dictionary[PokerGameStateManager.PlayerAction, String] = {
	PokerGameStateManager.PlayerAction.FOLD: "NPC_FOLD_MSG",
	PokerGameStateManager.PlayerAction.CHECK: "NPC_CALL_MSG",
	PokerGameStateManager.PlayerAction.RAISE: "NPC_RAISE_MSG",
	PokerGameStateManager.PlayerAction.ALL_IN: "NPC_ALL_IN_MSG",
}

@export var player_state_change_messages: Dictionary[PokerGameStateManager.PlayerState, String] = {
	PokerGameStateManager.PlayerState.OUT: "PLAYER_OUT_MSG",
}
@export var player_action_messages: Dictionary[PokerGameStateManager.PlayerAction, String] = {
	PokerGameStateManager.PlayerAction.FOLD: "PLAYER_FOLD_MSG",
	PokerGameStateManager.PlayerAction.CHECK: "PLAYER_CALL_MSG",
	PokerGameStateManager.PlayerAction.RAISE: "PLAYER_RAISE_MSG",
	PokerGameStateManager.PlayerAction.ALL_IN: "PLAYER_ALL_IN_MSG",
}

@export var game_state_change_messages: Dictionary[PokerGameStateManager.GameState, String] = {}

@export_category("Poker Game SFX")
@export var sfx: Dictionary[String, AudioStream] = {
	"win_round": null,
	"lose_round": null,
	"win_game": null,
	"lose_game": null,
	"chips_in": null,
	"chips_out": null,
	"drawing_cards": null,
	"showdown": null
}

var cpu_controllers: Dictionary = {}
var loaded_from_serialized_state: bool = false

func _ready() -> void:
	_validate_exports()

	emit_player_decision.connect(game_state._on_player_action)

	game_state.game_state_changed.connect(_on_game_state_changed)
	game_state.player_state_changed.connect(_on_player_state_changed)
	game_state.request_card_draw.connect(_on_request_card_draw)
	game_state.request_player_action.connect(_on_request_player_action)
	game_state.request_hand_evaluation.connect(_on_hand_evaluation_request)
	game_state.showdown_winners.connect(_on_showdown_winners)
	game_state.send_winnings.connect(_on_send_winnings)
	game_state.round_started.connect(_on_round_started)

	if is_instance_valid(player_ui):
		game_state.community_cards_changed.connect(_on_community_cards_changed)
		game_state.pot_value_changed.connect(_on_pot_value_changed)

		player_ui.help_button.pressed.connect(_on_help_button_pressed)
		player_ui.quit_game_button.pressed.connect(_on_quit_game_button_pressed)
		player_ui.main_menu_button.pressed.connect(_on_main_menu_button_pressed)

		player_ui.next_play_button.pressed.connect(_on_next_play_button_pressed)
		player_ui.disable_next_play_button()

		player_ui.call_button.pressed.connect(_on_call_button_pressed)
		player_ui.fold_button.pressed.connect(_on_fold_button_pressed)
		player_ui.raise_button.pressed.connect(_on_raise_button_pressed)
		player_ui.go_fish_button.pressed.connect(_on_go_fish_button_pressed)
		player_ui.fish_selected.connect(_on_fish_selected)

	player_controller.submit_player_decision.connect(_on_submit_player_decision)
	player_controller.going_fishing.connect(_on_player_going_fishing)
	player_controller.player_cash_changed.connect(_update_player_cash)

	game_state.register_player(player_controller.player_id)

	player_controller.max_fishes = Preloads.Instance.game_options.get("max_fishes", 0)
	player_controller.starting_cash = Preloads.Instance.game_options.get("starting_cash", 0)
	player_controller.raise_amount = Preloads.Instance.game_options.get("raise_amount", 0)
	player_controller.blind_bet = Preloads.Instance.game_options.get("blind_bet", 0)
	player_controller.entered_blind = false

	game_state.blind_bet = Preloads.Instance.game_options.get("blind_bet", 0)

	_setup_cpu_player(cpu1_controller)
	_setup_cpu_player(cpu2_controller)
	_setup_cpu_player(cpu3_controller)

	load_serialized_state()
	if is_instance_valid(deck) and deck.deck.size() == 0:
		deck._initialize_deck()

	if not loaded_from_serialized_state:
		player_ui.message_feed.add_message(tr("GAME_START_MSG").format({
			"starting_amount": Preloads.Instance.game_options.get("starting_cash", 0)
		}))
		game_state.new_play()
	else:
		_update_ui_from_state()

func serialize_and_save_state() -> void:
	var state: Dictionary = {
		"player_controller": player_controller.serialize(),
		"cpu1_controller": cpu1_controller.serialize(),
		"cpu2_controller": cpu2_controller.serialize(),
		"cpu3_controller": cpu3_controller.serialize(),
		"game_state": game_state.serialize(),
		"deck": deck.serialize(),
		"messages_feed": player_ui.message_feed.serialize_messages()
	}

	Preloads.serialized_state = state

func load_serialized_state() -> void:
	var state: Dictionary = Preloads.serialized_state
	if state.keys().size() == 0 and state.values().size() == 0:
		return
	loaded_from_serialized_state = true

	deck.load_state(state.get("deck", {}))
	player_controller.load_state(state.get("player_controller", {}))
	cpu1_controller.load_state(state.get("cpu1_controller", {}))
	cpu2_controller.load_state(state.get("cpu2_controller", {}))
	cpu3_controller.load_state(state.get("cpu3_controller", {}))
	game_state.load_state(state.get("game_state", {}))
	player_ui.message_feed.deserialize_messages(state.get("messages_feed", []))

func _setup_cpu_player(cpu_controller: CPUController) -> void:
	cpu_controller.submit_player_decision.connect(_on_submit_player_decision)
	player_ui.connect_cpu_display(cpu_controller.player_id)
	if is_instance_valid(cpu_controller.avatar):
		player_ui.set_cpu_avatar(cpu_controller.player_id, cpu_controller.avatar)

	game_state.register_player(cpu_controller.player_id)
	
	cpu_controller.max_fishes = Preloads.Instance.game_options.get("max_fishes", 0)
	cpu_controller.starting_cash = Preloads.Instance.game_options.get("starting_cash", 0)
	cpu_controller.raise_amount = Preloads.Instance.game_options.get("raise_amount", 0)
	cpu_controller.blind_bet = Preloads.Instance.game_options.get("blind_bet", 0)
	cpu_controller.entered_blind = false

	cpu_controllers[cpu_controller.player_id] = cpu_controller
	cpu_controller.npc_model.play_animation(cpu_controller.current_idle_animation)

func _on_request_card_draw(player_ids: PackedStringArray) -> void:
	print("Requesting card draw for players: %s" % [player_ids])
	for player_id in player_ids:
		if player_id == player_controller.player_id:
			if player_controller.can_draw_card(2):
				player_controller.add_card_to_hand(deck.draw(2))
			player_controller.remaining_fishes = player_controller.max_fishes
			player_controller.entered_blind = false

			var blind_posted = player_controller.post_blind()
			game_state.post_blind(player_id, blind_posted)

			if player_controller.cash == 0:
				game_state.player_state_change(player_id, PokerGameStateManager.PlayerState.ALL_IN)
			_update_player_cards_display()
		elif cpu_controllers.has(player_id):
			var cpu_controller = cpu_controllers[player_id]
			if cpu_controller.can_draw_card(2):
				cpu_controller.add_card_to_hand(deck.draw(2))
			cpu_controller.remaining_fishes = cpu_controller.max_fishes
			cpu_controller.entered_blind = false

			var blind_posted = cpu_controller.post_blind()
			game_state.post_blind(player_id, blind_posted)

			if cpu_controller.cash == 0:
				game_state.player_state_change(player_id, PokerGameStateManager.PlayerState.ALL_IN)

			player_ui.update_cpu_display(cpu_controller.player_id, cpu_controller.cash, game_state.get_player_state(cpu_controller.player_id))

	_play_sfx_if_valid(sfx.get("drawing_cards"))
	game_state.game_state_change(PokerGameStateManager.GameState.PLAYER_TURN)

func _on_request_player_action(player_id: String) -> void:
	print("Requesting player action for player: %s" % [player_id])
	var player_phase_bet = game_state.get_player_phase_bet(player_id)
	if player_id == player_controller.player_id:
		player_controller.start_player_turn(game_state.phase_bet, player_phase_bet)
		_update_player_ui_for_turn()
	elif cpu_controllers.has(player_id):
		cpu_controllers[player_id].make_decision(game_state.community_cards, game_state.phase_bet, player_phase_bet)

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
	if amount > 0:
		_play_sfx_if_valid(sfx.get("chips_in"))
	
	if player_id == player_controller.player_id:
		_end_player_turn_ui()
		_post_player_action_message(player_id, action, amount)
	elif cpu_controllers.has(player_id):
		_post_npc_action_message(player_id, action, amount)
		if action == PokerGameStateManager.PlayerAction.FOLD:
			cpu_controllers[player_id].current_idle_animation = "idle_out"

func _on_showdown_winners(winner_ids: PackedStringArray) -> void:
	print("Showdown winners: %s" % [winner_ids])

	var showdown_players = cpu_controllers.values().filter(func(cpu_controller):
		return game_state.get_player_state(cpu_controller.player_id) != PokerGameStateManager.PlayerState.OUT and \
			game_state.get_player_state(cpu_controller.player_id) != PokerGameStateManager.PlayerState.FOLDED
		)

	# Add player to showdown list if they haven't folded or gone out
	var all_showdown_players = []
	if game_state.get_player_state(player_controller.player_id) != PokerGameStateManager.PlayerState.OUT and \
		 game_state.get_player_state(player_controller.player_id) != PokerGameStateManager.PlayerState.FOLDED:
		all_showdown_players.append(player_controller)
	all_showdown_players.append_array(showdown_players)
	_play_sfx_if_valid(sfx.get("showdown"))

	if player_controller.player_id in winner_ids:
		_play_sfx_if_valid(sfx.get("win_round"))
	else:
		_play_sfx_if_valid(sfx.get("lose_round"))

	for cpu_controller in showdown_players:
		player_ui.show_cpu_cards(cpu_controller.player_id, cpu_controller.player_hand)

		if cpu_controller.player_id in winner_ids and winner_ids.size() > 1:
			cpu_controller.npc_model.play_split_voiceline()
		elif cpu_controller.player_id in winner_ids:
			cpu_controller.npc_model.play_win_voiceline()
		else:
			cpu_controller.npc_model.play_lose_voiceline()

	_post_round_end_message(all_showdown_players, winner_ids)

	for cpu_controller in showdown_players:
		cpu_controller.clear_hand()
		player_ui.update_cpu_display(cpu_controller.player_id, cpu_controller.cash, game_state.get_player_state(cpu_controller.player_id))

	for cpu_controller in cpu_controllers.values():
		if cpu_controller.cash <= 0 and game_state.get_player_state(cpu_controller.player_id) != PokerGameStateManager.PlayerState.OUT:
			game_state.player_state_change(cpu_controller.player_id, PokerGameStateManager.PlayerState.OUT)
			cpu_controller.current_idle_animation = "idle_out"
			cpu_controller.npc_model.play_animation("out")

	if _check_end_game():
		get_tree().paused = true
		return

	player_ui.enable_next_play_button()

func _on_round_started(dealer_id: String) -> void:
	_post_round_started_message(dealer_id)

func _on_community_cards_changed(new_cards: PackedStringArray) -> void:
	player_ui.update_table_cards_display(new_cards)
	_post_cards_dealt_message(new_cards)

func _on_send_winnings(winner_id: String, amount: int) -> void:
	print("Player %s received winnings: %d" % [winner_id, amount])
	if winner_id == player_controller.player_id:
		player_controller.cash += amount
		player_controller.already_raised = false
		_play_sfx_if_valid(sfx.get("chips_out"))
		_update_player_cash(player_controller.cash)
	elif cpu_controllers.has(winner_id):
		var cpu_controller = cpu_controllers.get(winner_id)
		cpu_controller.cash += amount
		cpu_controller.already_raised = false
		_play_sfx_if_valid(sfx.get("chips_out"))

func _on_player_state_changed(player_id: String, _old_state: PokerGameStateManager.PlayerState, new_state: PokerGameStateManager.PlayerState) -> void:
	if is_instance_valid(player_ui) and player_id != player_controller.player_id:
		player_ui.update_cpu_display(player_id, cpu_controllers[player_id].cash, new_state)

	if player_id == player_controller.player_id:
		_post_player_state_change_message(player_id, new_state)
	elif cpu_controllers.has(player_id):
		_post_npc_state_change_message(player_id, new_state)

func _on_game_state_changed(old_state: int, new_state: int) -> void:
	player_controller.already_raised = false
	for cpu_controller in cpu_controllers.values():
		cpu_controller.already_raised = false

	_post_game_state_change_message(new_state)

	if old_state == PokerGameStateManager.GameState.INIT and new_state == PokerGameStateManager.GameState.WAITING:
		var is_player_moving_from_out = false

		for cpu_controller in cpu_controllers.values():
			if game_state.get_player_state(cpu_controller.player_id) != PokerGameStateManager.PlayerState.OUT and \
			 cpu_controller.current_idle_animation == "idle_out":
				cpu_controller.npc_model.play_animation("fold_back")
				cpu_controller.current_idle_animation = "idle"
				is_player_moving_from_out = true
			
		if is_player_moving_from_out:
			await get_tree().create_timer(2.0).timeout

func _check_end_game() -> bool:
	if player_controller.cash <= 0:
		_play_sfx_if_valid(sfx.get("lose_game"))
		end_game_screen.show_lost()
		return true
	elif cpu_controllers.values().all(func(c): return c.cash <= 0):
		_play_sfx_if_valid(sfx.get("win_game"))
		end_game_screen.show_won()
		return true
	return false

func _start_next_play() -> void:
	player_controller.clear_hand()
	_update_player_cards_display()
	for cpu_controller in cpu_controllers.values():
		cpu_controller.clear_hand()
		player_ui.hide_cpu_cards(cpu_controller.player_id)

	game_state.new_play()

func _on_next_play_button_pressed() -> void:
	_start_next_play()
	player_ui.disable_next_play_button()

func _on_player_going_fishing(discarded_card: String) -> void:
	deck.reshuffle(discarded_card)
	serialize_and_save_state()
	get_tree().change_scene_to_packed(Preloads.fishing_scene)

func _on_help_button_pressed() -> void:
	help_screen.visible = true

func _on_main_menu_button_pressed() -> void:
	Preloads.Instance.reset_game_data()
	get_tree().change_scene_to_packed(Preloads.menu_scene)

func _on_quit_game_button_pressed() -> void:
	get_tree().quit()

func _on_call_button_pressed() -> void:
	player_controller._on_call_button_pressed()

func _on_fold_button_pressed() -> void:
	player_controller._on_fold_button_pressed()

func _on_raise_button_pressed() -> void:
	player_controller._on_raise_button_pressed()

func _on_fish_selected(fish_index: int, selected: bool) -> void:
	player_controller._on_fish_selected(fish_index, selected)
	_update_go_fish_button_state()

func _on_go_fish_button_pressed() -> void:
	player_controller._on_go_fish_button_pressed()
	_update_player_cards_display()

func _on_pot_value_changed(_old_pot: int, new_pot: int) -> void:
	if is_instance_valid(player_ui):
		player_ui.update_current_pot_display(new_pot)

func _update_player_cards_display() -> void:
	if is_instance_valid(player_ui):
		player_ui.update_cards_display(player_controller.player_hand)

func _update_player_cash(new_cash: int) -> void:
	if is_instance_valid(player_ui):
		player_ui.update_cash_display(new_cash)

func _update_player_ui_for_turn() -> void:
	if not is_instance_valid(player_ui):
		return

	player_ui.turn_start_update(player_controller.new_bet, player_controller.new_bet + player_controller.raise_amount, player_controller.remaining_fishes)
	player_ui.enable_fold_button()

	if (player_controller.cash > 0 and game_state.phase_bet > 0) or player_controller.entered_blind == false:
		player_ui.enable_call_button()
	else:
		player_ui.disable_call_button()

	if player_controller.can_raise():
		player_ui.enable_raise_button()
	else:
		player_ui.disable_raise_button()

	_update_go_fish_button_state()

func _end_player_turn_ui() -> void:
	if not is_instance_valid(player_ui):
		return

	player_ui.end_turn_update()
	player_ui.disable_call_button()
	player_ui.disable_fold_button()
	player_ui.disable_raise_button()
	player_ui.disable_go_fish_button()
	player_controller._on_fish_selected(0, false)

func _update_go_fish_button_state() -> void:
	if not is_instance_valid(player_ui):
		return

	if player_controller.remaining_fishes > 0 and \
	player_controller.selected_fish_index != -1 and \
	game_state.get_player_state(player_controller.player_id) == PokerGameStateManager.PlayerState.ACTIVE:
		player_ui.enable_go_fish_button()
	else:
		player_ui.disable_go_fish_button()

func _update_ui_from_state() -> void:
	if not is_instance_valid(player_ui):
		return

	_update_player_cards_display()
	_update_player_cash(player_controller.cash)
	player_ui.update_current_pot_display(game_state.pot)

func _validate_exports() -> void:
	if not is_instance_valid(help_screen):
		push_error("Help screen is not assigned or invalid.")
	if not is_instance_valid(end_game_screen):
		push_error("End game screen is not assigned or invalid.")
	if not is_instance_valid(player_controller):
		push_error("Player controller is not assigned or invalid.")
	if not is_instance_valid(deck):
		push_error("Deck is not assigned or invalid.")
	if not is_instance_valid(player_ui):
		push_error("Player UI is not assigned or invalid.")

func _play_sfx_if_valid(stream: AudioStream, offset_db: float = 0.0) -> void:
	if stream != null:
		SoundManager.play_sfx(stream, offset_db)

func _post_player_action_message(player_id: String, action: PokerGameStateManager.PlayerAction, amount: int) -> void:
	if not is_instance_valid(player_ui) or not player_action_messages.has(action):
		return
	
	var message_key = player_action_messages[action]
	var message_text = tr(message_key).format({
		"player_name": player_id,
		"amount": amount,
		"current_bet": game_state.get_player_bet(player_id)
	})
	player_ui.message_feed.add_message(message_text)

func _post_npc_action_message(player_id: String, action: PokerGameStateManager.PlayerAction, amount: int) -> void:
	if not is_instance_valid(player_ui) or not npc_action_messages.has(action):
		return
	
	var cpu_name = player_id
	var message_key = npc_action_messages[action]
	var message_text = tr(message_key).format({
		"player_name": cpu_name,
		"amount": amount,
		"current_bet": game_state.get_player_bet(player_id)
	})
	player_ui.message_feed.add_message(message_text)

func _post_player_state_change_message(player_id: String, state: PokerGameStateManager.PlayerState) -> void:
	if not is_instance_valid(player_ui) or not player_state_change_messages.has(state):
		return
	
	var message_key = player_state_change_messages[state]
	var message_text = tr(message_key).format({
		"player_name": player_id,
		"current_round": game_state.round_number if player_id == player_controller.player_id and game_state else cpu_controllers[player_id].rounds_played
	})
	player_ui.message_feed.add_message(message_text)

func _post_npc_state_change_message(player_id: String, state: PokerGameStateManager.PlayerState) -> void:
	if not is_instance_valid(player_ui) or not npc_state_change_messages.has(state):
		return
	
	var cpu_name = player_id
	var message_key = npc_state_change_messages[state]
	var message_text = tr(message_key).format({
		"player_name": cpu_name,
		"current_round": game_state.round_number if game_state else 0
	})
	player_ui.message_feed.add_message(message_text)

func _post_game_state_change_message(new_state: int) -> void:
	if not is_instance_valid(player_ui) or not game_state_change_messages.has(new_state):
		return
	
	var message_key = game_state_change_messages[new_state]
	var dealer_id = game_state.get_dealer() if game_state else "Unknown"
	
	var message_text = tr(message_key).format({
		"player_name": dealer_id,
		"starting_amount": player_controller.starting_cash if player_controller else 0
	})
	player_ui.message_feed.add_message(message_text)

func _post_round_started_message(dealer_id: String) -> void:
	if not is_instance_valid(player_ui):
		return
	
	var message_text = tr("GAME_DEAL_MSG").format({
		"player_name": dealer_id
	})
	player_ui.message_feed.add_message(message_text)

func _post_cards_dealt_message(community_cards: PackedStringArray) -> void:
	if not is_instance_valid(player_ui) or community_cards.is_empty():
		return
	
	var message_key = ""
	
	match community_cards.size():
		3:
			message_key = "GAME_FIRST_CARDS"
		4:
			message_key = "GAME_FOURTH_CARD"
		5:
			message_key = "GAME_FIFTH_CARD"
		_:
			return
	
	var message_text = tr(message_key).format({
		"card1": _get_card_name(community_cards[0]) if community_cards.size() > 0 else "",
		"card2": _get_card_name(community_cards[1]) if community_cards.size() > 1 else "",
		"card3": _get_card_name(community_cards[2]) if community_cards.size() > 2 else "",
		"card4": _get_card_name(community_cards[3]) if community_cards.size() > 3 else "",
		"card5": _get_card_name(community_cards[4]) if community_cards.size() > 4 else ""
	})
	player_ui.message_feed.add_message(message_text)

func _post_round_end_message(showdown_players: Array, winner_ids: PackedStringArray) -> void:
	if not is_instance_valid(player_ui) or showdown_players.is_empty():
		return
	
	# Handle early fold (single winner, not a showdown)
	if showdown_players.size() == 1:
		var message = tr("ROUND_END_MSG").format({
			"winner_name": showdown_players[0].player_id
		})
		player_ui.message_feed.add_message(message)
		return
	
	var message_key = ""
	var message_format = {}
	
	if winner_ids.size() < 2:
		match showdown_players.size():
			2:
				message_key = "ROUND_END_SHOWDOWN_2_MSG"
				var p1 = showdown_players[0]
				var p2 = showdown_players[1]
				message_format = {
					"player1": p1.player_id,
					"combination_name1": _get_combination_name(p1.evaluate_hand(game_state.community_cards).get("combination", "")),
					"player2": p2.player_id,
					"combination_name2": _get_combination_name(p2.evaluate_hand(game_state.community_cards).get("combination", "")),
					"winning_name": winner_ids[0] if winner_ids.size() > 0 else ""
				}
			3:
				message_key = "ROUND_END_SHOWDOWN_3_MSG"
				var p1 = showdown_players[0]
				var p2 = showdown_players[1]
				var p3 = showdown_players[2]
				message_format = {
					"player1": p1.player_id,
					"combination_name1": _get_combination_name(p1.evaluate_hand(game_state.community_cards).get("combination", "")),
					"player2": p2.player_id,
					"combination_name2": _get_combination_name(p2.evaluate_hand(game_state.community_cards).get("combination", "")),
					"player3": p3.player_id,
					"combination_name3": _get_combination_name(p3.evaluate_hand(game_state.community_cards).get("combination", "")),
					"winning_name": winner_ids[0] if winner_ids.size() > 0 else ""
				}
			4:
				message_key = "ROUND_END_SHOWDOWN_4_MSG"
				var p1 = showdown_players[0]
				var p2 = showdown_players[1]
				var p3 = showdown_players[2]
				var p4 = showdown_players[3]
				message_format = {
					"player1": p1.player_id,
					"combination_name1": _get_combination_name(p1.evaluate_hand(game_state.community_cards).get("combination", "")),
					"player2": p2.player_id,
					"combination_name2": _get_combination_name(p2.evaluate_hand(game_state.community_cards).get("combination", "")),
					"player3": p3.player_id,
					"combination_name3": _get_combination_name(p3.evaluate_hand(game_state.community_cards).get("combination", "")),
					"player4": p4.player_id,
					"combination_name4": _get_combination_name(p4.evaluate_hand(game_state.community_cards).get("combination", "")),
					"winning_name": winner_ids[0] if winner_ids.size() > 0 else ""
				}
			_:
				return
	else:
		match winner_ids.size():
			2:
				message_key = "ROUND_END_SPLIT_2_MSG"
				var p1 = winner_ids[0]
				var p2 = winner_ids[1]
				var combination1 = (player_controller if player_controller.player_id == p1 else cpu_controllers[p1]).evaluate_hand(game_state.community_cards).get("combination", "")
				var combination2 = (player_controller if player_controller.player_id == p2 else cpu_controllers[p2]).evaluate_hand(game_state.community_cards).get("combination", "")
				message_format = {
					"player1": p1,
					"combination_name1": _get_combination_name(combination1),
					"player2": p2,
					"combination_name2": _get_combination_name(combination2)
				}
			3:
				message_key = "ROUND_END_SPLIT_3_MSG"
				var p1 = winner_ids[0]
				var p2 = winner_ids[1]
				var p3 = winner_ids[2]
				var combination1 = (player_controller if player_controller.player_id == p1 else cpu_controllers[p1]).evaluate_hand(game_state.community_cards).get("combination", "")
				var combination2 = (player_controller if player_controller.player_id == p2 else cpu_controllers[p2]).evaluate_hand(game_state.community_cards).get("combination", "")
				var combination3 = (player_controller if player_controller.player_id == p3 else cpu_controllers[p3]).evaluate_hand(game_state.community_cards).get("combination", "")
				message_format = {
					"player1": p1,
					"combination_name1": _get_combination_name(combination1),
					"player2": p2,
					"combination_name2": _get_combination_name(combination2),
					"player3": p3,
					"combination_name3": _get_combination_name(combination3)
				}
			4:
				message_key = "ROUND_END_SPLIT_4_MSG"
				var p1 = winner_ids[0]
				var p2 = winner_ids[1]
				var p3 = winner_ids[2]
				var p4 = winner_ids[3]
				var combination1 = (player_controller if player_controller.player_id == p1 else cpu_controllers[p1]).evaluate_hand(game_state.community_cards).get("combination", "")
				var combination2 = (player_controller if player_controller.player_id == p2 else cpu_controllers[p2]).evaluate_hand(game_state.community_cards).get("combination", "")
				var combination3 = (player_controller if player_controller.player_id == p3 else cpu_controllers[p3]).evaluate_hand(game_state.community_cards).get("combination", "")
				var combination4 = (player_controller if player_controller.player_id == p4 else cpu_controllers[p4]).evaluate_hand(game_state.community_cards).get("combination", "")
				message_format = {
					"player1": p1,
					"combination_name1": _get_combination_name(combination1),
					"player2": p2,
					"combination_name2": _get_combination_name(combination2),
					"player3": p3,
					"combination_name3": _get_combination_name(combination3),
					"player4": p4,
					"combination_name4": _get_combination_name(combination4)
				}
			_:
				return
	
	var message_text = tr(message_key).format(message_format)
	player_ui.message_feed.add_message(message_text)

func _get_combination_name(combination: Preloads.Poker.Combination) -> String:
	match combination:
		Preloads.Poker.Combination.ROYAL_FLUSH:
			return tr("ROYAL_FLUSH")
		Preloads.Poker.Combination.STRAIGHT_FLUSH:
			return tr("STRAIGHT_FLUSH")
		Preloads.Poker.Combination.FOUR_OF_A_KIND:
			return tr("FOUR_OF_A_KIND")
		Preloads.Poker.Combination.FULL_HOUSE:
			return tr("FULL_HOUSE")
		Preloads.Poker.Combination.FLUSH:
			return tr("FLUSH")
		Preloads.Poker.Combination.STRAIGHT:
			return tr("STRAIGHT")
		Preloads.Poker.Combination.THREE_OF_A_KIND:
			return tr("THREE_OF_A_KIND")
		Preloads.Poker.Combination.TWO_PAIR:
			return tr("TWO_PAIR")
		Preloads.Poker.Combination.ONE_PAIR:
			return tr("ONE_PAIR")
		Preloads.Poker.Combination.HIGH_CARD:
			return tr("HIGH_CARD")
		_:
			return ""
		
func _get_card_name(card_string: String) -> String:
	var rank = card_string[0]
	var suit = card_string[1]

	var rank_string = ""
	var suit_string = ""
	match rank:
		"A":
			rank_string = tr("ACE")
		"K":
			rank_string = tr("KING")
		"Q":
			rank_string = tr("QUEEN")
		"J":
			rank_string = tr("JACK")
		"T":
			rank_string = tr("TEN")
		"9":
			rank_string = tr("NINE")
		"8":
			rank_string = tr("EIGHT")
		"7":
			rank_string = tr("SEVEN")
		"6":
			rank_string = tr("SIX")
		"5":
			rank_string = tr("FIVE")
		"4":
			rank_string = tr("FOUR")
		"3":
			rank_string = tr("THREE")
		"2":
			rank_string = tr("TWO")

	match suit:
		"H":
			suit_string = tr("HEARTS")
		"D":
			suit_string = tr("DIAMONDS")
		"C":
			suit_string = tr("CLUBS")
		"S":
			suit_string = tr("SPADES")

	return "%s %s" % [rank_string, suit_string]

func _exit_tree() -> void:
	# Disconnect all game_state signals
	if game_state:
		if game_state.game_state_changed.is_connected(_on_game_state_changed):
			game_state.game_state_changed.disconnect(_on_game_state_changed)
		if game_state.player_state_changed.is_connected(_on_player_state_changed):
			game_state.player_state_changed.disconnect(_on_player_state_changed)
		if game_state.request_card_draw.is_connected(_on_request_card_draw):
			game_state.request_card_draw.disconnect(_on_request_card_draw)
		if game_state.request_player_action.is_connected(_on_request_player_action):
			game_state.request_player_action.disconnect(_on_request_player_action)
		if game_state.request_hand_evaluation.is_connected(_on_hand_evaluation_request):
			game_state.request_hand_evaluation.disconnect(_on_hand_evaluation_request)
		if game_state.showdown_winners.is_connected(_on_showdown_winners):
			game_state.showdown_winners.disconnect(_on_showdown_winners)
		if game_state.send_winnings.is_connected(_on_send_winnings):
			game_state.send_winnings.disconnect(_on_send_winnings)
		if game_state.round_started.is_connected(_on_round_started):
			game_state.round_started.disconnect(_on_round_started)
		
		if is_instance_valid(player_ui):
			if game_state.community_cards_changed.is_connected(_on_community_cards_changed):
				game_state.community_cards_changed.disconnect(_on_community_cards_changed)
			if game_state.pot_value_changed.is_connected(_on_pot_value_changed):
				game_state.pot_value_changed.disconnect(_on_pot_value_changed)
	
	# Disconnect all player_ui signals
	if is_instance_valid(player_ui):
		if player_ui.help_button.pressed.is_connected(_on_help_button_pressed):
			player_ui.help_button.pressed.disconnect(_on_help_button_pressed)
		if player_ui.quit_game_button.pressed.is_connected(_on_quit_game_button_pressed):
			player_ui.quit_game_button.pressed.disconnect(_on_quit_game_button_pressed)
		if player_ui.main_menu_button.pressed.is_connected(_on_main_menu_button_pressed):
			player_ui.main_menu_button.pressed.disconnect(_on_main_menu_button_pressed)
		if player_ui.next_play_button.pressed.is_connected(_on_next_play_button_pressed):
			player_ui.next_play_button.pressed.disconnect(_on_next_play_button_pressed)
		if player_ui.call_button.pressed.is_connected(_on_call_button_pressed):
			player_ui.call_button.pressed.disconnect(_on_call_button_pressed)
		if player_ui.fold_button.pressed.is_connected(_on_fold_button_pressed):
			player_ui.fold_button.pressed.disconnect(_on_fold_button_pressed)
		if player_ui.raise_button.pressed.is_connected(_on_raise_button_pressed):
			player_ui.raise_button.pressed.disconnect(_on_raise_button_pressed)
		if player_ui.go_fish_button.pressed.is_connected(_on_go_fish_button_pressed):
			player_ui.go_fish_button.pressed.disconnect(_on_go_fish_button_pressed)
		if player_ui.fish_selected.is_connected(_on_fish_selected):
			player_ui.fish_selected.disconnect(_on_fish_selected)
	
	# Disconnect player_controller signals
	if player_controller:
		if player_controller.submit_player_decision.is_connected(_on_submit_player_decision):
			player_controller.submit_player_decision.disconnect(_on_submit_player_decision)
		if player_controller.going_fishing.is_connected(_on_player_going_fishing):
			player_controller.going_fishing.disconnect(_on_player_going_fishing)
		if player_controller.player_cash_changed.is_connected(_update_player_cash):
			player_controller.player_cash_changed.disconnect(_update_player_cash)
	
	# Disconnect CPU controller signals
	for cpu_controller in cpu_controllers.values():
		if cpu_controller.submit_player_decision.is_connected(_on_submit_player_decision):
			cpu_controller.submit_player_decision.disconnect(_on_submit_player_decision)
