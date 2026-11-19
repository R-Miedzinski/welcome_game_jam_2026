class_name PlayerUI
extends Control

signal fish_selected(fish_index: int, selected: bool)

@onready var raise_button = %MenuButtonRaise
@onready var call_button = %MenuButtonCall
@onready var fold_button = %MenuButtonFold
@onready var go_fish_button = %MenuButtonGoFish

@onready var quit_button = %MenuButtonQuit
@onready var help_button = %MenuButtonHelp

@onready var fish1 = %Fish1
@onready var fish2 = %Fish2

@onready var table_fish1 = %TableFish1
@onready var table_fish2 = %TableFish2
@onready var table_fish3 = %TableFish3
@onready var table_fish4 = %TableFish4
@onready var table_fish5 = %TableFish5

@onready var cash_label = %PlayerMoney
@onready var current_pot_label = %CurrentPot

func _ready() -> void:
	fish1.card_string = ""
	fish1.visible = false
	fish1.pressed.connect(_on_card1_in_hand_pressed)

	fish2.card_string = ""
	fish2.visible = false
	fish2.pressed.connect(_on_card2_in_hand_pressed)

func turn_start_update(to_check: int, raise_bet: int) -> void:
	raise_button.text = tr("RAISE") + " " + str(raise_bet)
	call_button.text = tr("CALL") + " " + str(to_check)

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

func enable_quit_button():
	quit_button.disabled = false

func disable_quit_button():
	quit_button.disabled = true

func enable_help_button():
	help_button.disabled = false

func disable_help_button():
	help_button.disabled = true

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
	cash_label.text = tr("MONEY") + ": " + str(cash)

func update_current_pot_display(current_pot: int) -> void:
	current_pot_label.text = tr("POT") + ": " + str(current_pot)

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
