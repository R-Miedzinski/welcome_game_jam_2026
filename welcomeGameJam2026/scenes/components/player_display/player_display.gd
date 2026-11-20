class_name PlayerDisplay
extends VBoxContainer

@export var avatar: Texture2D
@export var folded_banner: Texture2D
@export var raised_banner: Texture2D
@export var called_banner: Texture2D
@export var eliminated_banner: Texture2D
@export var base_banner: Texture2D

@onready var player_name_label: Label = %NameLabel
@onready var player_cash_label: Label = %CashLabel

@onready var profile_display: TextureRect = %ProfileDisplay
@onready var name_display: TextureRect = %NameDisplay

func _ready() -> void:
	set_player_cash("0")
	set_player_name("")

	if avatar:
		set_player_avatar(avatar)
	else:
		push_error("No avatar texture provided.")

	if avatar:
		set_player_avatar(avatar)
	else:
		push_error("No avatar texture provided.")


func set_player_name(player_name: String) -> void:
	player_name_label.text = player_name

func set_player_cash(cash: String) -> void:
	player_cash_label.text = cash  + " " + tr("$")

func set_player_avatar(avatar_texture: Texture2D) -> void:
	profile_display.texture = avatar_texture

func set_player_banner(banner_texture: Texture2D) -> void:
	name_display.texture = banner_texture

func set_banner_texture_by_state(player_state: PokerGameStateManager.PlayerState) -> void:
	match player_state:
		PokerGameStateManager.PlayerState.FOLDED:
			set_player_banner(folded_banner)
		PokerGameStateManager.PlayerState.RAISED, PokerGameStateManager.PlayerState.ALL_IN:
			set_player_banner(raised_banner)
		PokerGameStateManager.PlayerState.CHECKED:
			set_player_banner(called_banner)
		PokerGameStateManager.PlayerState.OUT:
			set_player_banner(eliminated_banner)
		PokerGameStateManager.PlayerState.ACTIVE, PokerGameStateManager.PlayerState.INIT:
			set_player_banner(base_banner)
		_:
			set_player_banner(base_banner)
