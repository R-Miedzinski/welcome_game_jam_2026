class_name PlayerUI
extends Control

signal fish_selected(fish_index: int, selected: bool)

@onready var raise_button: Button = %MenuButtonRaise
@onready var call_button: Button = %MenuButtonCall
@onready var fold_button: Button = %MenuButtonFold
@onready var go_fish_button: Button = %MenuButtonGoFish
@onready var next_play_button: Button = %MenuButtonNextPlay

@onready var main_menu_button: Button = %MenuButtonMainMenu
@onready var quit_game_button: Button = %MenuButtonQuit
@onready var help_button: Button = %MenuButtonHelp

@onready var fish1: Fish = %Fish1
@onready var fish2: Fish = %Fish2

@onready var table_fish1: Fish = %TableFish1
@onready var table_fish2: Fish = %TableFish2
@onready var table_fish3: Fish = %TableFish3
@onready var table_fish4: Fish = %TableFish4
@onready var table_fish5: Fish = %TableFish5

@onready var cpu1_display: PlayerDisplay = %CPU1Display
@onready var cpu2_display: PlayerDisplay = %CPU2Display
@onready var cpu3_display: PlayerDisplay = %CPU3Display
var cpu_display_connections: Dictionary = {}

@onready var cash_label: Label = %PlayerMoney
@onready var current_pot_label: Label = %CurrentPot
@onready var message_feed: MessageFeed = %MessageFeed

func _ready() -> void:
	fish1.card_string = ""
	fish1.visible = false
	fish1.pressed.connect(_on_card1_in_hand_pressed)

	fish2.card_string = ""
	fish2.visible = false
	fish2.pressed.connect(_on_card2_in_hand_pressed)

func turn_start_update(to_check: int, raise_bet: int, remaining_fishes: int) -> void:
	raise_button.text = tr("RAISE") + " " + str(raise_bet)
	call_button.text = tr("CALL") + " " + str(to_check)
	go_fish_button.text = tr("FISH") + " " + str(remaining_fishes) +\
		"/" + str(Preloads.Instance.game_options.get("max_fishes", 0))

func end_turn_update() -> void:
	raise_button.text = tr("RAISE")
	call_button.text = tr("CALL")

func enable_raise_button():
	raise_button.disabled = false

func disable_raise_button():
	raise_button.disabled = true

func enable_call_button():
	call_button.disabled = false

func disable_call_button():
	call_button.disabled = true

func enable_fold_button():
	fold_button.disabled = false

func disable_fold_button():
	fold_button.disabled = true

func enable_go_fish_button():
	go_fish_button.disabled = false

func disable_go_fish_button():
	go_fish_button.disabled = true

func enable_main_menu_button():
	main_menu_button.disabled = false

func disable_main_menu_button():
	main_menu_button.disabled = true

func enable_quit_game_button():
	quit_game_button.disabled = false

func disable_quit_game_button():
	quit_game_button.disabled = true

func enable_help_button():
	help_button.disabled = false

func disable_help_button():
	help_button.disabled = true

func enable_next_play_button():
	next_play_button.disabled = false
	next_play_button.visible = true

func disable_next_play_button():
	next_play_button.disabled = true
	next_play_button.visible = false

func update_cards_display(cards: PackedStringArray) -> void:
	if cards.size() > 0:
		fish1.card_string = cards[0]
		fish1.visible = true
	else:
		fish1.card_string = ""
		fish1.visible = false

	if cards.size() > 1:
		fish2.card_string = cards[1]
		fish2.visible = true
	else:
		fish2.card_string = ""
		fish2.visible = false

func update_table_cards_display(cards: PackedStringArray) -> void:
	if cards.size() > 0:
		table_fish1.card_string = cards[0]
		table_fish1.visible = true
	else:
		table_fish1.card_string = ""
		table_fish1.visible = false

	if cards.size() > 1:
		table_fish2.card_string = cards[1]
		table_fish2.visible = true
	else:
		table_fish2.card_string = ""
		table_fish2.visible = false

	if cards.size() > 2:
		table_fish3.card_string = cards[2]
		table_fish3.visible = true
	else:
		table_fish3.card_string = ""
		table_fish3.visible = false

	if cards.size() > 3:
		table_fish4.card_string = cards[3]
		table_fish4.visible = true
	else:
		table_fish4.card_string = ""
		table_fish4.visible = false

	if cards.size() > 4:
		table_fish5.card_string = cards[4]
		table_fish5.visible = true
	else:
		table_fish5.card_string = ""
		table_fish5.visible = false

func update_cash_display(cash: int) -> void:
	cash_label.text = tr("MONEY") + ": " + str(cash) + " " + tr("$")

func update_current_pot_display(current_pot: int) -> void:
	current_pot_label.text = tr("POT") + ": " + str(current_pot) + " " + tr("$")

func connect_cpu_display(cpu_id: String) -> void:
	if cpu_id in cpu_display_connections:
		print("CPU display for %s already connected" % cpu_id)
		return
	else:
		var id = cpu_display_connections.size() + 1
		match id:
			1:
				cpu_display_connections[cpu_id] = cpu1_display
				cpu1_display.set_player_name(cpu_id)
			2:
				cpu_display_connections[cpu_id] = cpu2_display
				cpu2_display.set_player_name(cpu_id)
			3:
				cpu_display_connections[cpu_id] = cpu3_display
				cpu3_display.set_player_name(cpu_id)
			_:
				print("No available CPU display for %s" % cpu_id)

func set_cpu_avatar(cpu_id: String, avatar: Texture2D) -> void:
	if not cpu_display_connections.has(cpu_id):
		print("No CPU display connected for %s" % cpu_id)
		return

	var display = cpu_display_connections[cpu_id]
	display.set_player_avatar(avatar)
	display.hide_fish_1()
	display.hide_fish_2()

func update_cpu_display(cpu_id: String, cash: int, state: PokerGameStateManager.PlayerState) -> void:
	if not cpu_display_connections.has(cpu_id):
		print("No CPU display connected for %s" % cpu_id)
		return

	var display = cpu_display_connections[cpu_id]
	display.set_player_cash(str(cash))
	display.set_banner_texture_by_state(state)

func show_cpu_cards(cpu_id: String, cards: Array) -> void:
	if not cpu_display_connections.has(cpu_id):
		print("No CPU display connected for %s" % cpu_id)
		return

	var display = cpu_display_connections[cpu_id]
	if cards.size() > 0:
		display.set_fish_1(cards[0])
	else:
		display.hide_fish_1()

	if cards.size() > 1:
		display.set_fish_2(cards[1])
	else:
		display.hide_fish_2()

func hide_cpu_cards(cpu_id: String) -> void:
	if not cpu_display_connections.has(cpu_id):
		print("No CPU display connected for %s" % cpu_id)
		return

	var display = cpu_display_connections[cpu_id]
	display.hide_fish_1()
	display.hide_fish_2()

func _on_card1_in_hand_pressed():
	if not fish1.selectable:
		return

	fish1.selected = !fish1.selected
	fish2.selected = false
	fish_selected.emit(0, fish1.selected)

func _on_card2_in_hand_pressed():
	if not fish2.selectable:
		return

	fish2.selected = !fish2.selected
	fish1.selected = false
	fish_selected.emit(1, fish2.selected)
