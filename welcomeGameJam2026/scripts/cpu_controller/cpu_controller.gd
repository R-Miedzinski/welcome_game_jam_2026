class_name CPUController
extends Node

@export var starting_cash: int = 0
@export var max_fishes: int = 0
@export var player_id: String
@export var cash_label: Label3D

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

func make_decision(table_cards: Array, current_bet: int, player_bet: int) -> Array:
	var evaluation = evaluate_hand(table_cards)
	print("CPU player %s evaluated hand" % player_id)
	print("Score: %d" % [evaluation.get("hand_score", 0)])
	var decision: PokerGameStateManager.PlayerAction = PokerGameStateManager.PlayerAction.CHECK
	var new_bet: int = 0
	var to_check = current_bet - player_bet

	# TODO: improve on CPU decisionmaking
	if to_check == 0 and not already_raised:
		print("CPU player %s deciding to RAISE" % player_id)
		decision = PokerGameStateManager.PlayerAction.RAISE
		already_raised = true
	elif (to_check > 0 and to_check <= cash) or (to_check == 0 and already_raised):
		print("CPU player %s CHECKING" % player_id)
		decision = PokerGameStateManager.PlayerAction.CHECK
	else: 
		print("CPU player %s FOLDED" % player_id)
		decision = PokerGameStateManager.PlayerAction.FOLD

	if decision == PokerGameStateManager.PlayerAction.RAISE:
		new_bet = current_bet - player_bet + 2
	elif decision == PokerGameStateManager.PlayerAction.FOLD:
		new_bet = 0
	else:
		new_bet = min(to_check, cash)

	cash -= new_bet

	return [decision, new_bet]

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
