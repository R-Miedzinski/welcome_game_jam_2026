class_name CPUController
extends Node

var state_label_text = {
	PokerGameStateManager.PlayerAction.FOLD: "Folding",
	PokerGameStateManager.PlayerAction.CHECK: "Calling",
	PokerGameStateManager.PlayerAction.RAISE: "Raising",
	PokerGameStateManager.PlayerAction.ALL_IN: "Going All-In",
	"FISH": "Fishing"
}

signal submit_player_decision(player_id: String, decision: PokerGameStateManager.PlayerAction, new_bet: int)

@export var player_id: String

@export var cash_label: Label3D
@export var state_label: Label3D

@export var decision_schema: DecisionSchema
@export var deck: DeckManager

var starting_cash: int = 0:
	set(value):
		starting_cash = value
		cash = starting_cash
var max_fishes: int = 0:
	set(value):
		max_fishes = value
		remaining_fishes = max_fishes
var raise_amount: int = 2

var cash: int = 0:
	set(value):
		cash = value
		if cash_label:
			cash_label.text = player_id + ": " + str(cash) + " $"
var remaining_fishes: int = 0

var player_hand: PackedStringArray = []

var already_raised: bool = false

func _ready() -> void:
	cash = starting_cash
	remaining_fishes = max_fishes

func make_decision(table_cards: Array, current_bet: int, player_bet: int) -> void:
	print("CPU player %s making decision with table cards: %s, current bet: %d, player bet: %d" % [player_id, table_cards, current_bet, player_bet])
	var schema_decision = decision_schema.get_decision(table_cards.size(), player_hand[1], player_hand[0])
	print("CPU player %s schema decision: %s" % [player_id, schema_decision])
	var decision_outcome = null
	if schema_decision != null:
		decision_outcome = schema_decision.decision_can_fish if _can_fish() else schema_decision.decision_cannot_fish
	print("CPU player %s decision outcome: %s; cards in hand: %s; he can fish: %s" % [player_id, decision_outcome, player_hand, _can_fish()])

	var desired_decision = null

	# Decision pre-flop: if no table cards
	if table_cards.size() == 0:
		if decision_outcome == DecisionSchema.DecisionOutcome.FISH:
			_fish()
			return make_decision(table_cards, current_bet, player_bet)
		else:
			desired_decision = _map_decision_to_action(decision_outcome)
			if desired_decision == -1:
				desired_decision = DecisionSchema.DecisionOutcome.FOLD

	elif table_cards.size() > 0:
		var evaluation = evaluate_hand(table_cards)
		var hand_score = evaluation.get("hand_score", 0)

		print("CPU player %s hand score: %d" % [player_id, hand_score])
		if hand_score >= Preloads.Poker.SCORING_THRESHOLDS.get(Preloads.Poker.Combination.STRAIGHT):
			desired_decision = _map_decision_to_action(DecisionSchema.DecisionOutcome.RAISE)
		elif hand_score >= Preloads.Poker.SCORING_THRESHOLDS.get(Preloads.Poker.Combination.ONE_PAIR):
			desired_decision = _map_decision_to_action(DecisionSchema.DecisionOutcome.CALL)
		else:
			if decision_outcome == DecisionSchema.DecisionOutcome.FISH:
				_fish()
				return make_decision(table_cards, current_bet, player_bet)
			else:
				desired_decision = _map_decision_to_action(decision_outcome)
				if desired_decision == -1:
					desired_decision = DecisionSchema.DecisionOutcome.FOLD

	print("CPU player %s final desired decision: %s" % [player_id, desired_decision])
	var action_with_bet = _make_bet(desired_decision, current_bet, player_bet)
	cash -= action_with_bet[1]

	print("CPU player %s action with bet: %s" % [player_id, action_with_bet])
	_update_state_label(action_with_bet[0])
	submit_player_decision.emit(player_id, action_with_bet[0], action_with_bet[1])

func evaluate_hand(table_cards: Array) -> Dictionary:
	var held_cards: Array[Preloads.Poker.Card] = []
	for card in player_hand:
		held_cards.append(Preloads.Poker.Card.new(card))

	var community_cards: Array[Preloads.Poker.Card] = []
	for card in table_cards:
		community_cards.append(Preloads.Poker.Card.new(card))

	return Preloads.Poker.PokerEngine.evaluate_hand(held_cards, community_cards)

func can_draw_card(count: int = 1) -> bool:
	return player_hand.size() + count <= 2

func add_card_to_hand(cards_string: String) -> void:
	var cards: PackedStringArray = cards_string.split(",")
	if not can_draw_card(cards.size()):
		push_error("CPU hand is full.")
		return

	player_hand += cards
	_sort_hand()

func clear_hand() -> void:
	player_hand.clear()

func serialize() -> Dictionary:
	return {
		"starting_cash": starting_cash,
		"max_fishes": max_fishes,
		"player_id": player_id,
		"cash": cash,
		"remaining_fishes": remaining_fishes,
		"player_hand": player_hand,
		"already_raised": already_raised
	}

func load_state(state: Dictionary) -> void:
	starting_cash = state.get("starting_cash", 0)
	max_fishes = state.get("max_fishes", 0)
	player_id = state.get("player_id", "")
	cash = state.get("cash", 0)
	remaining_fishes = state.get("remaining_fishes", 0)
	player_hand = state.get("player_hand", [])
	already_raised = state.get("already_raised", false)

func _update_state_label(action) -> void:
	if state_label:
		state_label.text = state_label_text.get(action, "") + " " + str(player_hand)

func _can_fish() -> bool:
	return remaining_fishes > 0

func _fish() -> void:
	print("CPU player %s attempting to fish. Remaining fishes: %d" % [player_id, remaining_fishes])
	if not _can_fish():
		push_error("CPU player %s cannot fish." % player_id)
		return
	remaining_fishes -= 1
	_update_state_label("FISH")

	# remove lowest card from hand
	var card1_rank = Preloads.Poker.Card.new(player_hand.get(0)).rank
	var card2_rank = Preloads.Poker.Card.new(player_hand.get(1)).rank
	if card1_rank <= card2_rank:
		player_hand.remove_at(0)
	else:
		player_hand.remove_at(1)

	# draw new card
	var drawn_card: String = deck.draw(1)
	add_card_to_hand(drawn_card)
	print("CPU player %s drew card: %s; new hand: %s" % [player_id, drawn_card, player_hand])

func _sort_hand() -> void:
	if player_hand.size() != 2:
		return

	var card1_rank = Preloads.Poker.Card.new(player_hand.get(0)).rank
	var card2_rank = Preloads.Poker.Card.new(player_hand.get(1)).rank
	if card1_rank > card2_rank:
		var temp = player_hand.get(0)
		player_hand.set(0, player_hand.get(1))
		player_hand.set(1, temp)

func _map_decision_to_action(decision: DecisionSchema.DecisionOutcome) -> int:
	match decision:
		DecisionSchema.DecisionOutcome.FOLD:
			return PokerGameStateManager.PlayerAction.FOLD
		DecisionSchema.DecisionOutcome.CALL:
			return PokerGameStateManager.PlayerAction.CHECK
		DecisionSchema.DecisionOutcome.RAISE:
			return PokerGameStateManager.PlayerAction.RAISE
		_:
			return -1

# returns [final PlayerAction, bet_amount]  
func _make_bet(desired_decision: PokerGameStateManager.PlayerAction, current_bet: int, player_bet: int) -> Array:
	var final_action: int = desired_decision
	var bet_amount: int = 0
	var to_call: int = current_bet - player_bet

	var can_raise = cash > to_call + raise_amount

	print("CPU player %s making bet with desired decision: %s, current bet: %d, player bet: %d, to call: %d, cash: %d" % [player_id, desired_decision, current_bet, player_bet, to_call, cash])
	match desired_decision:
		PokerGameStateManager.PlayerAction.FOLD:
			bet_amount = 0
		PokerGameStateManager.PlayerAction.CHECK:
			bet_amount = min(cash, to_call)
			if current_bet == 0:
				bet_amount = min(cash, to_call + raise_amount)
				final_action = PokerGameStateManager.PlayerAction.RAISE
			
			# TODO: enable after ALL_IN implemented
			if bet_amount == cash:
				final_action = PokerGameStateManager.PlayerAction.ALL_IN
		PokerGameStateManager.PlayerAction.RAISE:
			if can_raise:
				bet_amount = to_call + raise_amount
			else:
				bet_amount = min(cash, to_call)
				final_action = PokerGameStateManager.PlayerAction.ALL_IN # TODO: change to ALL_IN when implemented
		_:
			final_action = PokerGameStateManager.PlayerAction.FOLD
			bet_amount = 0

	return [final_action, bet_amount]
	
