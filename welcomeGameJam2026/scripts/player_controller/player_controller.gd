# TODO: Extract repetitions and create a base class for player and cpu controllers
class_name PlayerController
extends Node

signal submit_player_decision(player_id: String, decision: PokerGameStateManager.PlayerAction, new_bet: int)
signal going_fishing(discarded_card: String)
signal player_cash_changed(new_cash: int)

@export var player_id: String

@export var deck: DeckManager
@export var poker_game_manager: PokerGameStateManager
@export var seal: SealProp

var player_hand: PackedStringArray = []
var cash: int:
	get:
		return cash
	set(value):
		cash = value
		player_cash_changed.emit(cash)

var max_fishes: int = 0:
	set(value):
		max_fishes = value
		remaining_fishes = max_fishes
var starting_cash: int:
	set(value):
		starting_cash = value
		cash = starting_cash
var raise_amount: int = 0
var blind_bet: int = 0

var remaining_fishes: int = 0
var selected_fish_index: int = -1

var already_raised: bool = false
var is_turn_active: bool = false
var entered_blind: bool = false

var decision: PokerGameStateManager.PlayerAction;
var new_bet: int = 0

func _ready() -> void:
	if not is_instance_valid(deck):
		push_error("DeckManager instance is not valid.")

	cash = starting_cash
	remaining_fishes = max_fishes
	already_raised = false

func can_raise() -> bool:
	return not already_raised and cash > new_bet + raise_amount

func can_draw_card(count: int = 1) -> bool:
	return player_hand.size() + count <= 2

func add_card_to_hand(cards_string: String) -> void:
	var cards: PackedStringArray = cards_string.split(",")
	if not can_draw_card(cards.size()):
		push_error("Player hand is full.")
		return

	player_hand += cards

func clear_hand() -> void:
	player_hand.clear()

func post_blind() -> int:
	var blind_amount = min(blind_bet, cash)
	cash -= blind_amount
	entered_blind = true
	return blind_amount

func start_player_turn(current_bet: int = 0, player_bet: int = 0) -> void:
	new_bet = current_bet - player_bet
	if not entered_blind and new_bet == 0:
		new_bet = blind_bet
	new_bet = min(new_bet, cash)
	is_turn_active = true

func end_player_turn() -> void:
	is_turn_active = false

func evaluate_hand(table_cards: Array) -> Dictionary:
	var held_cards: Array[Preloads.Poker.Card] = []
	for card in player_hand:
		held_cards.append(Preloads.Poker.Card.new(card))

	var community_cards: Array[Preloads.Poker.Card] = []
	for card in table_cards:
		community_cards.append(Preloads.Poker.Card.new(card))

	return Preloads.Poker.PokerEngine.evaluate_hand(held_cards, community_cards)

func serialize() -> Dictionary:
	return {
		"starting_cash": starting_cash,
		"max_fishes": max_fishes,
		"player_id": player_id,
		"cash": cash,
		"remaining_fishes": remaining_fishes,
		"player_hand": player_hand,
		"already_raised": already_raised,
		"selected_fish_index": selected_fish_index,
		"entered_blind": entered_blind,
		"raise_amount": raise_amount,
		"blind_bet": blind_bet
	}

func load_state(state: Dictionary) -> void:
	starting_cash = state.get("starting_cash", 0)
	max_fishes = state.get("max_fishes", 0)
	player_id = state.get("player_id", "")
	cash = state.get("cash", 0)
	remaining_fishes = state.get("remaining_fishes", 0)
	player_hand = state.get("player_hand", [])
	already_raised = state.get("already_raised", false)
	selected_fish_index = state.get("selected_fish_index", -1)
	entered_blind = state.get("entered_blind", false)
	raise_amount = state.get("raise_amount", 0)
	blind_bet = state.get("blind_bet", 0)

func _on_call_button_pressed() -> void:
	if new_bet >= cash:
		submit_player_decision.emit(player_id, PokerGameStateManager.PlayerAction.ALL_IN, cash)
		entered_blind = true
		cash = 0
		end_player_turn()
		return

	submit_player_decision.emit(player_id, PokerGameStateManager.PlayerAction.CHECK, new_bet)
	cash -= new_bet
	end_player_turn()

func _on_fish_selected(fish_index: int, selected: bool) -> void:
	selected_fish_index = fish_index if selected else -1

func _on_fold_button_pressed() -> void:
	submit_player_decision.emit(player_id, PokerGameStateManager.PlayerAction.FOLD, 0)
	end_player_turn()

func _on_raise_button_pressed() -> void:
	var raise_bet = min(new_bet + raise_amount, cash)
	submit_player_decision.emit(player_id, PokerGameStateManager.PlayerAction.RAISE, raise_bet)
	cash -= raise_bet
	already_raised = true
	end_player_turn()

func _on_go_fish_button_pressed() -> void:
	if selected_fish_index != -1 and remaining_fishes > 0:
		var discarded_card = player_hand.get(selected_fish_index)
		player_hand.remove_at(selected_fish_index)


		if is_instance_valid(seal):
			seal.ate_fish.connect(_on_seal_ate_fish.bind(discarded_card))
			seal.eat_fish()
		else:
			_dispatch_go_fish(discarded_card)

func _dispatch_go_fish(discarded_card) -> void:
	remaining_fishes -= 1
	selected_fish_index = -1
	going_fishing.emit(discarded_card)

func _on_seal_ate_fish(discarded_card) -> void:
	_dispatch_go_fish(discarded_card)
	seal.ate_fish.disconnect(_on_seal_ate_fish)
