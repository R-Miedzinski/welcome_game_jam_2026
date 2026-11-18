class_name DeckManager
extends Node

var deck: Array = []

# func _ready() -> void:
#   _initialize_deck()

func _initialize_deck() -> void:
  deck.clear()
  var suits = ["H", "D", "C", "S"]
  var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "0", "J", "Q", "K", "A"]
  for suit in suits:
    for rank in ranks:
      deck.append(rank + suit)
  deck.shuffle()

func shuffle() -> void:
  _initialize_deck()

func draw(count: int = 1) -> String:
  var drawn_cards: Array = []
  for i in range(count):
    if deck.size() > 0:
      drawn_cards.append(deck.pop_back())
    else:
      break
  return ",".join(drawn_cards)

func peek(count: int = 1) -> String:
  var peeked_cards: Array = []
  for i in range(count):
    if deck.size() > 0:
      peeked_cards.append(deck[deck.size() - 1 - i])
    else:
      break
  return ",".join(peeked_cards)

func peek_random(count: int = 1) -> String:
  var random_cards: Array = []
  for i in range(count):
    if deck.size() > 0:
      var index = randi() % deck.size()
      random_cards.append(deck[index])
    else:
      break
  return ",".join(random_cards)

func take_out(card_string: String) -> void:
  var cards_to_remove = card_string.split(",")
  for card in cards_to_remove:
    if card in deck:
      deck.erase(card)

func reshuffle(card_string: String) -> void:
  deck.append(card_string)
  deck.shuffle()

func serialize() -> String:
  return ",".join(deck)

func load_state(deck_string: String) -> void:
  if deck_string == "":
    _initialize_deck()
  else:
    deck = deck_string.split(",")
