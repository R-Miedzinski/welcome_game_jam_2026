class_name PokerGameStateManager
extends Node

const MIN_SCORE_THRESHOLD: int = -2147483648

enum GameState {
	INIT, # 0
	WAITING, # 1
	DEALING, # 2
	PLAYER_TURN, # 3
	SHOWDOWN, # 4
	LAST_MAN_STANDING, # 5
	LOADED # 6
}

const ALLOWED_GAME_TRANSITIONS = [
	[GameState.INIT, GameState.WAITING],
	[GameState.WAITING, GameState.PLAYER_TURN],
	[GameState.DEALING, GameState.PLAYER_TURN],
	[GameState.DEALING, GameState.SHOWDOWN],
	[GameState.PLAYER_TURN, GameState.DEALING],
	[GameState.PLAYER_TURN, GameState.LAST_MAN_STANDING],
	[GameState.LOADED, GameState.INIT],
	[GameState.LOADED, GameState.WAITING],
	[GameState.LOADED, GameState.DEALING],
	[GameState.LOADED, GameState.PLAYER_TURN],
	[GameState.LOADED, GameState.SHOWDOWN],
	[GameState.LOADED, GameState.LAST_MAN_STANDING],
]

enum PlayerState {
	INIT, # 0
	ACTIVE, # 1
	CHECKED, # 2
	RAISED, # 3
	FOLDED, # 4 
	OUT, # 5
	ALL_IN, # 6
	LOADED # 7
}

const ALLOWED_PLAYER_TRANSITIONS = [
	[PlayerState.INIT, PlayerState.ACTIVE],
	[PlayerState.ACTIVE, PlayerState.FOLDED],
	[PlayerState.ACTIVE, PlayerState.CHECKED],
	[PlayerState.ACTIVE, PlayerState.RAISED],
	[PlayerState.ACTIVE, PlayerState.ALL_IN],
	[PlayerState.CHECKED, PlayerState.ACTIVE],
	[PlayerState.RAISED, PlayerState.ACTIVE],
	[PlayerState.ACTIVE, PlayerState.OUT],
	[PlayerState.CHECKED, PlayerState.OUT],
	[PlayerState.RAISED, PlayerState.OUT],
	[PlayerState.FOLDED, PlayerState.OUT],
	[PlayerState.ALL_IN, PlayerState.OUT],
	[PlayerState.ACTIVE, PlayerState.INIT],
	[PlayerState.CHECKED, PlayerState.INIT],
	[PlayerState.RAISED, PlayerState.INIT],
	[PlayerState.FOLDED, PlayerState.INIT],
	[PlayerState.ALL_IN, PlayerState.INIT],
	[PlayerState.LOADED, PlayerState.INIT],
	[PlayerState.LOADED, PlayerState.ACTIVE],
	[PlayerState.LOADED, PlayerState.FOLDED],
	[PlayerState.LOADED, PlayerState.CHECKED],
	[PlayerState.LOADED, PlayerState.RAISED],
	[PlayerState.LOADED, PlayerState.OUT],
	[PlayerState.LOADED, PlayerState.ALL_IN],
]

enum PlayerAction {
	FOLD, # 0
	CHECK, # 1
	RAISE, # 2
	ALL_IN, # 3
}

signal game_state_changed(old_state: GameState, new_state: GameState)
signal player_state_changed(player_id: String, old_state: PlayerState, new_state: PlayerState)
signal pot_value_changed(old_pot: int, new_pot: int)
signal community_cards_changed(new_cards: PackedStringArray)

signal round_started(dealer_id: String)
signal request_player_action(player_id: String)
signal request_card_draw(player_ids: PackedStringArray)

signal request_hand_evaluation(player_id: String, community_cards: Array)
signal showdown_winners(winner_ids: PackedStringArray)

signal send_winnings(winner_id: String, amount: int)

@export var deck: DeckManager

var game_state: GameState = GameState.INIT
var player_states: Dictionary = {}
var player_bets: Dictionary = {}
var player_phase_bets: Dictionary = {}
var player_blind_posted: Dictionary = {}
var player_order: Array = []

var round_number: int = 0
var dealer_index: int = -1
var blind_bet: int = 0
var current_bet: int = 0
var phase_bet: int = 0
var pot: int = 0:
	set(value):
		var old_pot = pot
		pot = value
		emit_signal("pot_value_changed", old_pot, pot)
	
var community_cards: PackedStringArray = []
var showdown_scores: Dictionary = {}
var showdown_players: PackedStringArray = []

var round_started_emitted: bool = false

var state_change_stack: Array[Callable] = []

func _ready() -> void:
	if deck == null:
		push_error("DeckManager is not assigned")
		return

func _process(_delta: float) -> void:
	while state_change_stack.size() > 0:
		var callable = state_change_stack.pop_front()
		callable.call()

func new_play() -> void:
	if not _should_game_start():
		print("Game cannot start, not enough active players.")
		return

	game_state = GameState.INIT
	showdown_scores.clear()
	showdown_players.clear()
	round_started_emitted = false

	for key in player_bets.keys():
		player_bets[key] = 0
		player_phase_bets[key] = 0
		player_blind_posted[key] = false
	pot = 0
	current_bet = 0
	phase_bet = blind_bet
	community_cards.clear()
	community_cards_changed.emit(community_cards)
	deck.shuffle()
	round_number += 1
	_advance_dealer()

	for key in player_states.keys():
		if player_states[key] != PlayerState.OUT and player_states[key] != PlayerState.INIT:
			player_state_change(key, PlayerState.INIT)
	
	game_state_change(GameState.WAITING)

func register_player(player_id: String) -> void:
	player_states[player_id] = PlayerState.ACTIVE
	player_bets[player_id] = 0
	player_phase_bets[player_id] = 0
	player_blind_posted[player_id] = false
	player_order.append(player_id)

func post_blind(player_id: String, blind_amount: int) -> void:
	player_bets[player_id] += blind_amount
	player_blind_posted[player_id] = true
	pot += blind_amount
	current_bet = max(current_bet, blind_amount)

func get_player_bet(player_id: String) -> int:
	return player_bets.get(player_id, 0)

func get_player_phase_bet(player_id: String) -> int:
	return player_phase_bets.get(player_id, 0)

func get_player_state(player_id: String) -> PlayerState:
	return player_states.get(player_id, null)

func get_dealer() -> String:
	return player_order[dealer_index] if dealer_index >= 0 and dealer_index < player_order.size() else ""

func serialize() -> Dictionary:
	return {
		"dealer_index": dealer_index,
		"blind_bet": blind_bet,
		"current_bet": current_bet,
		"phase_bet": phase_bet,
		"pot": pot,
		"community_cards": community_cards,
		"showdown_scores": showdown_scores,
		"showdown_players": showdown_players,
		"player_states": player_states,
		"player_bets": player_bets,
		"player_phase_bets": player_phase_bets,
		"player_blind_posted": player_blind_posted,
		"player_order": player_order,
		"game_state": game_state,
		"round_started_emitted": round_started_emitted,
		"round_number": round_number
	}

func load_state(state: Dictionary) -> void:
	dealer_index = state.get("dealer_index", 0)
	blind_bet = state.get("blind_bet", 0)
	current_bet = state.get("current_bet", 0)
	phase_bet = state.get("phase_bet", 0)
	pot = state.get("pot", 0)
	community_cards = state.get("community_cards", [])
	community_cards_changed.emit(community_cards)

	showdown_scores = state.get("showdown_scores", [])
	showdown_players = state.get("showdown_players", [])

	player_bets = state.get("player_bets", {})
	player_phase_bets = state.get("player_phase_bets", {})
	player_blind_posted = state.get("player_blind_posted", {})
	player_order = state.get("player_order", [])
	
	round_started_emitted = state.get("round_started_emitted", false)
	round_number = state.get("round_number", 0)

	game_state = GameState.LOADED
	game_state_change(state.get("game_state", GameState.WAITING))

	var desired_player_states = state.get("player_states", {})
	player_states.clear()
	for key in desired_player_states.keys():
		player_states[key] = PlayerState.LOADED
		player_state_change(key, desired_player_states[key])

func player_state_change(player_id: String, new_state: PlayerState) -> void:
	print("Requesting player state change for player %s from %s to %s" % [player_id, player_states.get(player_id, null), new_state])
	var current_state = player_states.get(player_id, null)
	if current_state == null:
		return

	for transition in ALLOWED_PLAYER_TRANSITIONS:
		if transition[0] == current_state and transition[1] == new_state:
			player_states[player_id] = new_state
			player_state_changed.emit(player_id, current_state, new_state)
			state_change_stack.append(_transition_player_state.bind(player_id, current_state, new_state))
			return
	push_error("Invalid state transition from %s to %s for player %s" % [current_state, new_state, player_id])

func game_state_change(new_state: GameState) -> void:
	print("Requesting game state change from %s to %s" % [game_state, new_state])
	var current_state = game_state
	for transition in ALLOWED_GAME_TRANSITIONS:
		if transition[0] == current_state and transition[1] == new_state:
			game_state = new_state
			game_state_changed.emit(current_state, new_state)
			state_change_stack.append(_transition_game_state.bind(current_state, new_state))
			return
	push_error("Invalid game state transition from %s to %s for game" % [current_state, new_state])

func submit_hand_evaluation(player_id: String, score: int) -> void:
	if game_state != GameState.SHOWDOWN or not showdown_players.has(player_id):
		push_error("Unexpected hand evaluation for player %s." % [player_id])
		return

	showdown_scores[player_id] = score
	if showdown_scores.size() < showdown_players.size():
		return

	var best_score: int = MIN_SCORE_THRESHOLD
	var winner_ids: PackedStringArray = []
	var winnings: Dictionary = {}
	for evaluated_player in showdown_players:
		var player_score: int = showdown_scores[evaluated_player]
		if player_score > best_score:
			best_score = player_score
			winner_ids = [evaluated_player]
		elif player_score == best_score:
			winner_ids.append(evaluated_player)

	var total_bets: int = 0
	for bettor in player_bets.keys():
		total_bets += get_player_bet(bettor)
	if total_bets != pot:
		push_error("Cannot split pot: player bets do not match the pot.")
		return

	for id in player_bets.keys():
		winnings[id] = 0
	# Rotate remainder slots between contributions while returning capped shares to bettors.
	var remainder_index: int = 0
	for bettor in player_bets.keys():
		var bet: int = get_player_bet(bettor)
		var distributed: int = 0
		for i in range(winner_ids.size()):
			var id: String = winner_ids[i]
			var eligible_bet: int = bet
			if get_player_state(id) == PlayerState.ALL_IN:
				eligible_bet = min(bet, get_player_bet(id))
			var amount: int = floor(float(eligible_bet) / float(winner_ids.size()))
			var remainder_position: int = (i - remainder_index + winner_ids.size()) % winner_ids.size()
			if remainder_position < eligible_bet % winner_ids.size():
				amount += 1
			winnings[id] += amount
			distributed += amount
		var refund: int = bet - distributed
		if refund > 0:
			winnings[bettor] = winnings.get(bettor, 0) + refund
		remainder_index = (remainder_index + bet % winner_ids.size()) % winner_ids.size()

	current_bet = 0
	pot = 0
	for id in winnings:
		send_winnings.emit(id, winnings[id])
	showdown_winners.emit(winner_ids)

func _advance_dealer() -> void:
	var count = player_order.size()
	if count == 0:
		return
	var index = dealer_index
	for i in range(count):
		index = (index + 1) % count
		if player_states.get(player_order[index], PlayerState.OUT) != PlayerState.OUT:
			dealer_index = index
			return
	dealer_index = (dealer_index + 1) % count

func _transition_player_state(player_id: String, old_state: PlayerState, new_state: PlayerState) -> void:
	if old_state == PlayerState.LOADED:
		if new_state == PlayerState.ACTIVE:
			request_player_action.emit(player_id)

		return

	if new_state == PlayerState.RAISED or new_state == PlayerState.CHECKED or new_state == PlayerState.ALL_IN or new_state == PlayerState.FOLDED:
		var next_player = _try_get_next_player_to_move(player_id)
		if next_player != "":
			if not _check_if_should_advance_player_turn():
				game_state_change(GameState.LAST_MAN_STANDING)
				return

			player_state_change(next_player, PlayerState.ACTIVE)
		else:
			game_state_change(GameState.DEALING)
	elif new_state == PlayerState.ACTIVE:
		request_player_action.emit(player_id)

func _transition_game_state(old_state: GameState, new_state: GameState) -> void:
	if old_state == GameState.LOADED:
		return

	match new_state:
		GameState.WAITING:
			var plarticipating_players: PackedStringArray = []
			for player_id in player_order:
				if not _is_player_in_final_state(player_id):
					plarticipating_players.append(player_id)
			request_card_draw.emit(plarticipating_players)
		GameState.DEALING:
			if community_cards.size() == 0:
				community_cards.append_array(deck.draw(3).split(","))
				community_cards_changed.emit(community_cards)
			elif (community_cards.size() < 5):
				community_cards.append(deck.draw())
				community_cards_changed.emit(community_cards)
			
			if community_cards.size() == 5:
				game_state_change(GameState.SHOWDOWN)
				return

			phase_bet = current_bet
			for key in player_phase_bets.keys():
				player_phase_bets[key] = 0
			_move_active_players_to_init()
			game_state_change(GameState.PLAYER_TURN)
		GameState.PLAYER_TURN:
			if not _check_if_should_advance_player_turn():
				game_state_change(GameState.LAST_MAN_STANDING)
				return

			if not round_started_emitted:
				round_started_emitted = true
				round_started.emit(player_order[dealer_index])
			
			var first_player = _get_first_player_to_move()
			if first_player == "":
				game_state_change(GameState.DEALING)
				return
			player_state_change(first_player, PlayerState.ACTIVE)
		GameState.SHOWDOWN:
			_begin_showdown()
		GameState.LAST_MAN_STANDING:
			var last_player: String = ""
			for player_id in player_order:
				if not _is_player_in_final_state(player_id):
					last_player = player_id
					break

			if last_player == "":
				push_error("Cannot award pot without an eligible player.")
				return

			var winnings: int = pot
			current_bet = 0
			pot = 0
			send_winnings.emit(last_player, winnings)
			var winners: PackedStringArray = [last_player]
			showdown_winners.emit(winners)

func _check_if_should_advance_player_turn() -> bool:
	var active_player_count: int = 0
	for player_id in player_order:
		if _is_player_in_final_state(player_id) == false:
			active_player_count += 1
	return active_player_count > 1

func _move_active_players_to_init() -> void:
	for player_id in player_order:
		if not _is_player_in_final_state(player_id) and get_player_state(player_id) != PlayerState.INIT and get_player_state(player_id) != PlayerState.ALL_IN:
			player_state_change(player_id, PlayerState.INIT)

func _get_first_player_to_move() -> String:
	var dealer_id: String = player_order[dealer_index]
	if not _is_player_in_final_state(dealer_id) and get_player_state(dealer_id) != PlayerState.ALL_IN:
		return dealer_id
	# Dealer is folded/out, so continue with the next eligible player after them.
	return _try_get_next_player_to_move(dealer_id)

func _begin_showdown() -> void:
	showdown_scores.clear()
	showdown_players.clear()

	for player_id in player_order:
		if not _is_player_in_final_state(player_id):
			showdown_players.append(player_id)

	if showdown_players.is_empty():
		push_error("Cannot start showdown without an eligible player.")
		return

	for player_id in showdown_players:
		request_hand_evaluation.emit(player_id, community_cards.duplicate())


func _try_get_next_player_to_move(current_player_id: String) -> String:
	var current_index = player_order.find(current_player_id)
	if current_index == -1:
		push_error("Player %s not found in player order." % [current_player_id])
		return ""
	var next_index = (current_index + 1) % player_order.size()
	while next_index != current_index:
		if _is_player_in_final_state(player_order[next_index]) \
		or (\
			(\
				get_player_state(player_order[next_index]) == PlayerState.CHECKED \
				or get_player_state(player_order[next_index]) == PlayerState.RAISED\
			) \
			and current_bet - player_bets[player_order[next_index]] <= 0\
			)\
			or get_player_state(player_order[next_index]) == PlayerState.ALL_IN:
			next_index += 1
			next_index %= player_order.size()
			continue
			
		return player_order[next_index]
		
	print("No next player to move found.")
	return ""

func _is_player_in_final_state(player_id: String) -> bool:
	return get_player_state(player_id) == PlayerState.FOLDED or get_player_state(player_id) == PlayerState.OUT

func _on_player_action(player_id: String, action: PlayerAction, amount: int) -> void:
	if not game_state == GameState.PLAYER_TURN:
		push_error("Cannot perform player action when it is not the player's turn.")
		return

	match action:
		PlayerAction.FOLD:
			player_state_change(player_id, PlayerState.FOLDED)
		PlayerAction.CHECK:
			pot += amount
			player_bets[player_id] = player_bets.get(player_id, 0) + amount
			player_phase_bets[player_id] = player_phase_bets.get(player_id, 0) + amount
			current_bet = max(current_bet, player_bets[player_id])
			phase_bet = max(phase_bet, player_phase_bets[player_id])
			player_state_change(player_id, PlayerState.CHECKED)
		PlayerAction.RAISE:
			pot += amount
			player_bets[player_id] = player_bets.get(player_id, 0) + amount
			player_phase_bets[player_id] = player_phase_bets.get(player_id, 0) + amount
			current_bet = player_bets[player_id]
			phase_bet = player_phase_bets[player_id]
			player_state_change(player_id, PlayerState.RAISED)
		PlayerAction.ALL_IN:
			pot += amount
			player_bets[player_id] = player_bets.get(player_id, 0) + amount
			player_phase_bets[player_id] = player_phase_bets.get(player_id, 0) + amount
			current_bet = max(current_bet, player_bets[player_id])
			phase_bet = max(phase_bet, player_phase_bets[player_id])
			player_state_change(player_id, PlayerState.ALL_IN)

	print("Current pot: %s" % [pot])

func _should_game_start() -> bool:
	var active_player_count = 0
	for player_id in player_order:
		if get_player_state(player_id) != PlayerState.OUT:
			active_player_count += 1

	return active_player_count >= 2
