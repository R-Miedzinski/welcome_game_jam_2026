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
  if card_string not in deck:
    deck.append(card_string)
  else:
    push_warning("Card %s already in deck, skipping reshuffle to prevent duplicate" % card_string)
  deck.shuffle()

func serialize() -> Dictionary:
  _check_for_duplicates()
  return { "cards": ",".join(deck) }

func load_state(state: Dictionary) -> void:
  var deck_string = state.get("cards", "")
  if deck_string == "":
    _initialize_deck()
  else:
    deck = deck_string.split(",")
    _check_for_duplicates()

func _check_for_duplicates() -> void:
  var card_counts = {}
  for card in deck:
    card_counts[card] = card_counts.get(card, 0) + 1
  var duplicates = {}
  for card in card_counts.keys():
    if card_counts[card] > 1:
      duplicates[card] = card_counts[card]
  if duplicates.size() > 0:
    push_warning("Deck has duplicates: %s" % [duplicates])
    for card in duplicates.keys():
      while deck.count(card) > 1:
        deck.erase(card)