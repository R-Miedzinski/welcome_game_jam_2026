# TODO: Extract repetitions and create a base class for player and cpu controllers
class_name PlayerController
extends Node

signal submit_player_decision(player_id: String, decision: PokerGameStateManager.PlayerAction, new_bet: int)
signal going_fishing(discarded_card: String)

@export var player_id: String

@export var player_ui: PlayerUI
@export var deck: DeckManager
@export var poker_game_manager: PokerGameStateManager

var player_hand: PackedStringArray = []
var cash: int:
	set(value):
		cash = value
		if is_instance_valid(player_ui):
			player_ui.update_cash_display(cash)
	get:
		return cash

var max_fishes: int = 0:
	set(value):
		max_fishes = value
		remaining_fishes = max_fishes
var starting_cash: int:
	set(value):
		starting_cash = value
		cash = starting_cash
var raise_amount: int = 0

var remaining_fishes: int = 0
var selected_fish_index: int = -1:
	set(value):
		selected_fish_index = value
		if is_instance_valid(player_ui):
			if selected_fish_index != -1 and remaining_fishes > 0:
				player_ui.enable_go_fish_button()
			else:
				player_ui.disable_go_fish_button()

var already_raised: bool = false
var is_turn_active: bool = false

var decision: PokerGameStateManager.PlayerAction;
var new_bet: int = 0

func _ready() -> void:
	if not is_instance_valid(player_ui):
		push_error("PlayerUI instance is not valid.")

	if not is_instance_valid(deck):
		push_error("DeckManager instance is not valid.")

	cash = starting_cash
	remaining_fishes = max_fishes
	already_raised = false

	end_player_turn()

	player_ui.quit_button.pressed.connect(_on_quit_button_pressed)
	player_ui.call_button.pressed.connect(_on_call_button_pressed)
	player_ui.fold_button.pressed.connect(_on_fold_button_pressed)
	player_ui.raise_button.pressed.connect(_on_raise_button_pressed)
	player_ui.go_fish_button.pressed.connect(_on_go_fish_button_pressed)
	player_ui.fish_selected.connect(_on_fish_selected)

	poker_game_manager.pot_value_changed.connect(_on_pot_value_changed)

func can_draw_card(count: int = 1) -> bool:
	return player_hand.size() + count <= 2

func add_card_to_hand(cards_string: String) -> void:
	var cards: PackedStringArray = cards_string.split(",")
	if not can_draw_card(cards.size()):
		push_error("Player hand is full.")
		return

	player_hand += cards
	player_ui.update_cards_display(player_hand)

func clear_hand() -> void:
	player_hand.clear()
	player_ui.update_cards_display(player_hand)

func start_player_turn(current_bet: int = 0, player_bet: int = 0) -> void:
	new_bet = min(cash, current_bet - player_bet)
	is_turn_active = true

	if is_instance_valid(player_ui):
		player_ui.turn_start_update(new_bet, new_bet + raise_amount)

		player_ui.enable_fold_button()

		if cash > 0 and current_bet > 0:
			player_ui.enable_call_button()

		if !already_raised:
			player_ui.enable_raise_button()

		if remaining_fishes > 0 and selected_fish_index != -1:
			player_ui.enable_go_fish_button()

func end_player_turn() -> void:
	is_turn_active = false
	if is_instance_valid(player_ui):
		player_ui.end_turn_update()

		player_ui.disable_call_button()
		player_ui.disable_fold_button()
		player_ui.disable_raise_button()
		player_ui.disable_go_fish_button()

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
	if is_instance_valid(player_ui):
		player_ui.update_cards_display(player_hand)

func _on_quit_button_pressed() -> void:
	print("Quit button pressed.")
	Preloads.Instance.reset_game_data()
	get_tree().change_scene_to_packed(Preloads.menu_scene)

func _on_call_button_pressed() -> void:
	submit_player_decision.emit(player_id, PokerGameStateManager.PlayerAction.CHECK, new_bet)
	cash -= new_bet
	already_raised = false
	end_player_turn()

func _on_fish_selected(fish_index: int, selected: bool) -> void:
	selected_fish_index = fish_index if selected else -1

func _on_fold_button_pressed() -> void:
	submit_player_decision.emit(player_id, PokerGameStateManager.PlayerAction.FOLD, 0)
	end_player_turn()

func _on_raise_button_pressed() -> void:
	submit_player_decision.emit(player_id, PokerGameStateManager.PlayerAction.RAISE, new_bet + raise_amount)
	cash -= (new_bet + raise_amount)
	already_raised = true
	end_player_turn()

func _on_go_fish_button_pressed() -> void:
	if selected_fish_index != -1 and remaining_fishes > 0:
		var discarded_card = player_hand.get(selected_fish_index)
		player_hand.remove_at(selected_fish_index)
		player_ui.update_cards_display(player_hand)

		remaining_fishes -= 1
		going_fishing.emit(discarded_card)

func _on_pot_value_changed(_old_pot: int, new_pot: int) -> void:
	if is_instance_valid(player_ui):
		player_ui.update_current_pot_display(new_pot)
	
