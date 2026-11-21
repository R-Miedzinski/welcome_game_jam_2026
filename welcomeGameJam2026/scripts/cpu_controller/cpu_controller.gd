class_name CPUController
extends Node

signal submit_player_decision(player_id: String, decision: PokerGameStateManager.PlayerAction, new_bet: int)

@export var player_id: String

@export var decision_schema: DecisionSchema
@export var deck: DeckManager

@export var avatar: Texture2D
@export var npc_model: NPC

var starting_cash: int = 0:
	set(value):
		starting_cash = value
		cash = starting_cash
var max_fishes: int = 0:
	set(value):
		max_fishes = value
		remaining_fishes = max_fishes
var raise_amount: int = 0
var blind_bet: int = 0

var cash: int = 0
var remaining_fishes: int = 0

var player_hand: PackedStringArray = []

var already_raised: bool = false
var entered_blind: bool = false

var idle_animation_names: PackedStringArray = ["idle", "idle_out"]
var current_idle_animation: String = "idle":
	set(value):
		current_idle_animation = value if value in idle_animation_names else idle_animation_names[0]

var animation_finished_bindings: Dictionary[String, Callable] = {}

func _ready() -> void:
	if is_instance_valid(npc_model):
		npc_model.animation_finished.connect(_on_animation_finished)
	else:
		push_error("NPC model for %s is not valid." % player_id)

	cash = starting_cash
	remaining_fishes = max_fishes

func post_blind() -> int:
	var blind_amount = min(blind_bet, cash)
	cash -= blind_amount
	entered_blind = true
	return blind_amount

func make_decision(table_cards: Array, current_bet: int, player_bet: int) -> void:
	var schema_decision = decision_schema.get_decision(table_cards.size(), player_hand[1], player_hand[0])
	var decision_outcome = null
	if schema_decision != null:
		decision_outcome = schema_decision.decision_can_fish if _can_fish() else schema_decision.decision_cannot_fish

	var desired_decision = null

	# Decision pre-flop: if no table cards
	if table_cards.size() == 0:
		if decision_outcome == DecisionSchema.DecisionOutcome.FISH:
			animation_finished_bindings["fish"] = func () -> void:
				_fish()
				make_decision(table_cards, current_bet, player_bet)
			
			npc_model.play_animation("fish")
			return
		else:
			desired_decision = _map_decision_to_action(decision_outcome)
			if desired_decision == -1:
				desired_decision = DecisionSchema.DecisionOutcome.FOLD

	elif table_cards.size() > 0:
		var evaluation = evaluate_hand(table_cards)
		var hand_score = evaluation.get("hand_score", 0)

		if hand_score >= Preloads.Poker.SCORING_THRESHOLDS.get(Preloads.Poker.Combination.STRAIGHT):
			desired_decision = _map_decision_to_action(DecisionSchema.DecisionOutcome.RAISE)
		elif hand_score >= Preloads.Poker.SCORING_THRESHOLDS.get(Preloads.Poker.Combination.ONE_PAIR):
			desired_decision = _map_decision_to_action(DecisionSchema.DecisionOutcome.CALL)
		else:
			if decision_outcome == DecisionSchema.DecisionOutcome.FISH:
				# _fish()
				# return make_decision(table_cards, current_bet, player_bet)
				animation_finished_bindings["fish"] = func () -> void:
					_fish()
					make_decision(table_cards, current_bet, player_bet)
				
				npc_model.play_animation("fish")
				return		
			else:
				desired_decision = _map_decision_to_action(decision_outcome)
				if desired_decision == -1:
					desired_decision = DecisionSchema.DecisionOutcome.FOLD

	var action_with_bet = _make_bet(desired_decision, current_bet, player_bet)
	var animation: String = _map_action_to_animation(action_with_bet[0])

	if animation != "":
		animation_finished_bindings[animation] = func () -> void:
			cash -= action_with_bet[1]
			submit_player_decision.emit(player_id, action_with_bet[0], action_with_bet[1])

		npc_model.play_animation(animation)

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
		"already_raised": already_raised,
		"raise_amount": raise_amount,
		"blind_bet": blind_bet,
		"entered_blind": entered_blind
	}

func load_state(state: Dictionary) -> void:
	starting_cash = state.get("starting_cash", 0)
	max_fishes = state.get("max_fishes", 0)
	player_id = state.get("player_id", "")
	cash = state.get("cash", 0)
	remaining_fishes = state.get("remaining_fishes", 0)
	player_hand = state.get("player_hand", [])
	already_raised = state.get("already_raised", false)
	raise_amount = state.get("raise_amount", Preloads.Instance.game_options.get("raise_amount", 0))
	blind_bet = state.get("blind_bet", Preloads.Instance.game_options.get("blind_bet", 0))
	entered_blind = state.get("entered_blind", false)

func _can_fish() -> bool:
	return remaining_fishes > 0

func _fish() -> void:
	print("CPU player %s attempting to fish. Remaining fishes: %d" % [player_id, remaining_fishes])
	if not _can_fish():
		push_error("CPU player %s cannot fish." % player_id)
		return
	remaining_fishes -= 1

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
	if not entered_blind and to_call == 0:
		to_call = blind_bet
		entered_blind = true

	var can_raise = cash > to_call + raise_amount and not already_raised

	match desired_decision:
		PokerGameStateManager.PlayerAction.FOLD:
			bet_amount = 0
		PokerGameStateManager.PlayerAction.CHECK:
			bet_amount = min(cash, to_call)
			if current_bet == 0:
				bet_amount = min(cash, to_call + raise_amount)
				final_action = PokerGameStateManager.PlayerAction.RAISE
			
			if bet_amount == cash:
				final_action = PokerGameStateManager.PlayerAction.ALL_IN
		PokerGameStateManager.PlayerAction.RAISE:
			if can_raise:
				bet_amount = to_call + raise_amount
				already_raised = true
			else:
				bet_amount = min(cash, to_call)
				final_action = PokerGameStateManager.PlayerAction.ALL_IN if bet_amount >= cash else PokerGameStateManager.PlayerAction.CHECK
		_:
			final_action = PokerGameStateManager.PlayerAction.FOLD
			bet_amount = 0

	return [final_action, bet_amount]

func _map_action_to_animation(action: PokerGameStateManager.PlayerAction) -> String:
	match action:
		PokerGameStateManager.PlayerAction.FOLD:
			return "fold"
		PokerGameStateManager.PlayerAction.CHECK:
			return "call"
		PokerGameStateManager.PlayerAction.RAISE:
			return "raise"
		PokerGameStateManager.PlayerAction.ALL_IN:
			return "raise"
		_:
			return current_idle_animation

func _on_animation_finished(anim_name: String) -> void:
	print("Animation finished: %s" % anim_name)
	if animation_finished_bindings.has(anim_name):
		print("Calling animation finished binding for: %s" % anim_name)
		animation_finished_bindings[anim_name].call()
		animation_finished_bindings.erase(anim_name)

	if not anim_name in idle_animation_names and not npc_model.animation_player.is_playing():
		print("Animation %s is not an idle animation, switching to %s after finishing." % [anim_name, current_idle_animation])
		npc_model.play_animation(current_idle_animation)
