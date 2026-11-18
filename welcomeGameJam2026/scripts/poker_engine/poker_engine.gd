const HAND_SIZE = 2
const MAX_TABLE_SIZE = 5

enum Combination {
	HIGH_CARD, # 0
	ONE_PAIR, # 1
	TWO_PAIR, # 2
	THREE_OF_A_KIND, # 3
	STRAIGHT, # 4
	FLUSH, # 5
	FULL_HOUSE, # 6
	FOUR_OF_A_KIND, # 7
	STRAIGHT_FLUSH, # 8
	ROYAL_FLUSH # 9
}

const SCORING_THRESHOLDS = {
Combination.HIGH_CARD: 0,
Combination.ONE_PAIR: 1*15**5,
Combination.TWO_PAIR: 2*15**5,
Combination.THREE_OF_A_KIND: 3*15**5,
Combination.STRAIGHT: 4*15**5,
Combination.FLUSH: 5*15**5,
Combination.FULL_HOUSE: 6*15**5,
Combination.FOUR_OF_A_KIND: 7*15**5,
Combination.STRAIGHT_FLUSH: 8*15**5,
Combination.ROYAL_FLUSH: 9*15**5
}

enum Suit {
	DIAMONDS, # 0
	CLUBS, # 1
	HEARTS, # 2
	SPADES # 3
}

enum Rank {
	TWO, # 0
	THREE, # 1
	FOUR, # 2
	FIVE, # 3
	SIX, # 4
	SEVEN, # 5
	EIGHT, # 6
	NINE, # 7
	TEN, # 8
	JACK, # 9
	QUEEN, # 10
	KING, # 11
	ACE # 12
}

const string_to_suit = {
	"D": Suit.DIAMONDS,
	"C": Suit.CLUBS,
	"H": Suit.HEARTS,
	"S": Suit.SPADES
}

const string_to_rank = {
	"2": Rank.TWO,
	"3": Rank.THREE,
	"4": Rank.FOUR,
	"5": Rank.FIVE,
	"6": Rank.SIX,
	"7": Rank.SEVEN,
	"8": Rank.EIGHT,
	"9": Rank.NINE,
	"0": Rank.TEN,
	"J": Rank.JACK,
	"Q": Rank.QUEEN,
	"K": Rank.KING,
	"A": Rank.ACE
}

class Card:
	var suit: int = -1
	var rank: int = -1

	func _init(card_string: String) -> void:
		if card_string.length() < 2:
			push_error("Invalid card string: " + card_string)
			return

		var rank_string := card_string.substr(0, card_string.length() - 1)
		var suit_string := card_string.substr(card_string.length() - 1, 1)
		if rank_string == "10":
			rank_string = "0"
		if not string_to_rank.has(rank_string) or not string_to_suit.has(suit_string):
			push_error("Invalid card string: " + card_string)
			return
		rank = string_to_rank[rank_string]
		suit = string_to_suit[suit_string]

	func is_valid() -> bool:
		return rank >= Rank.TWO and rank <= Rank.ACE and suit >= Suit.DIAMONDS and suit <= Suit.SPADES

	func get_card_string() -> String:
		if not is_valid():
			push_error("Cannot represent an invalid card")
			return ""
		for rank_string in string_to_rank:
			if string_to_rank[rank_string] == rank:
				for suit_string in string_to_suit:
					if string_to_suit[suit_string] == suit:
						return rank_string + suit_string
		push_error("Cannot represent card with unknown rank or suit")
		return ""


class PokerEngine:
	# Tiebreakers use conventional ranks 2-14, with a five-high ace-low straight.
	# With fewer than five known cards, only combinations already present are scored.
	static func evaluate_hand(hand: Array[Card], table: Array[Card] = []) -> Dictionary:
		if hand.size() != HAND_SIZE:
			push_error("Invalid hand size: " + str(hand.size()))
			return {}
		if table.size() > MAX_TABLE_SIZE:
			push_error("Invalid table size: " + str(table.size()))
			return {}

		var cards: Array[Card] = hand.duplicate()
		cards.append_array(table)
		var seen := {}
		for card in cards:
			if card == null or not card.is_valid():
				push_error("Cannot evaluate an invalid card")
				return {}
			var key := Vector2i(card.rank, card.suit)
			if seen.has(key):
				push_error("Duplicate card: " + card.get_card_string())
				return {}
			seen[key] = true

		var best: Dictionary = {}
		if cards.size() < 5:
			best = _evaluate_selection(cards)
		else:
			# At most seven cards: enumerate all five-card selections.
			for a in range(cards.size() - 4):
				for b in range(a + 1, cards.size() - 3):
					for c in range(b + 1, cards.size() - 2):
						for d in range(c + 1, cards.size() - 1):
							for e in range(d + 1, cards.size()):
								var selection: Array[Card] = [cards[a], cards[b], cards[c], cards[d], cards[e]]
								var candidate := _evaluate_selection(selection)
								if best.is_empty() or candidate.hand_score > best.hand_score:
									best = candidate

		best["is_complete"] = cards.size() >= 5
		best["weakest_card"] = _weakest_card(hand, best.combination_cards)
		best["combination_cards"] = best["combination_cards"].map(func(card): return card.get_card_string()) # remove?
		return best

	static func _evaluate_selection(cards: Array[Card]) -> Dictionary:
		var sorted: Array[Card] = cards.duplicate()
		sorted.sort_custom(func(a: Card, b: Card) -> bool:
			if a.rank != b.rank:
				return a.rank > b.rank
			return a.suit > b.suit
		)

		var groups := {}
		for card in sorted:
			if not groups.has(card.rank):
				groups[card.rank] = []
			groups[card.rank].append(card)

		var pairs: PackedInt32Array = []
		var trips: PackedInt32Array = []
		var quads: PackedInt32Array = []
		var singles: PackedInt32Array = []
		# Sorted cards ensure each rank is considered in descending order.
		var visited := {}
		for card in sorted:
			if visited.has(card.rank):
				continue
			visited[card.rank] = true
			match groups[card.rank].size():
				1: singles.append(card.rank)
				2: pairs.append(card.rank)
				3: trips.append(card.rank)
				4: quads.append(card.rank)

		var straight_high := -1
		var is_flush := false
		if sorted.size() == 5:
			is_flush = true
			for card in sorted:
				if card.suit != sorted[0].suit:
					is_flush = false
					break
			if groups.size() == 5:
				if sorted[0].rank - sorted[4].rank == 4:
					straight_high = sorted[0].rank + 2
				elif sorted[0].rank == Rank.ACE and sorted[1].rank == Rank.FIVE \
						and sorted[2].rank == Rank.FOUR and sorted[3].rank == Rank.THREE \
						and sorted[4].rank == Rank.TWO:
					straight_high = 5

		var combination := Combination.HIGH_CARD
		var tiebreakers: PackedInt32Array = []
		var combination_cards: Array[Card] = []
		if straight_high > 0 and is_flush:
			combination = Combination.ROYAL_FLUSH if straight_high == 14 else Combination.STRAIGHT_FLUSH
			tiebreakers.append(straight_high)
			combination_cards.assign(sorted)
		elif not quads.is_empty():
			combination = Combination.FOUR_OF_A_KIND
			tiebreakers.append(quads[0] + 2)
			combination_cards.assign(groups[quads[0]])
			_append_ranks(tiebreakers, singles)
		elif not trips.is_empty() and not pairs.is_empty():
			combination = Combination.FULL_HOUSE
			tiebreakers.append(trips[0] + 2)
			tiebreakers.append(pairs[0] + 2)
			combination_cards.assign(groups[trips[0]])
			combination_cards.append_array(groups[pairs[0]])
		elif is_flush:
			combination = Combination.FLUSH
			_append_card_ranks(tiebreakers, sorted)
			combination_cards.assign(sorted)
		elif straight_high > 0:
			combination = Combination.STRAIGHT
			tiebreakers.append(straight_high)
			combination_cards.assign(sorted)
		elif not trips.is_empty():
			combination = Combination.THREE_OF_A_KIND
			tiebreakers.append(trips[0] + 2)
			combination_cards.assign(groups[trips[0]])
			_append_ranks(tiebreakers, singles)
		elif pairs.size() == 2:
			combination = Combination.TWO_PAIR
			_append_ranks(tiebreakers, pairs)
			_append_ranks(tiebreakers, singles)
			combination_cards.assign(groups[pairs[0]])
			combination_cards.append_array(groups[pairs[1]])
		elif pairs.size() == 1:
			combination = Combination.ONE_PAIR
			_append_ranks(tiebreakers, pairs)
			_append_ranks(tiebreakers, singles)
			combination_cards.assign(groups[pairs[0]])
		else:
			_append_card_ranks(tiebreakers, sorted)

		return {
			"combination": combination,
			"hand_score": _score(combination, tiebreakers),
			"highest_cards": sorted.map(func(card): return card.get_card_string()), # remove map?
			"combination_cards": combination_cards,
			"tiebreakers": tiebreakers
		}

	static func _append_ranks(target: PackedInt32Array, ranks: PackedInt32Array) -> void:
		for rank in ranks:
			target.append(rank + 2)

	static func _append_card_ranks(target: PackedInt32Array, cards: Array[Card]) -> void:
		for card in cards:
			target.append(card.rank + 2)

	# Five base-15 digits preserve all kickers and make scores directly comparable.
	static func _score(combination: Combination, tiebreakers: PackedInt32Array) -> int:
		var score: int = combination
		for i in range(5):
			score *= 15
			if i < tiebreakers.size():
				score += tiebreakers[i]
		return score

	static func _weakest_card(hand: Array[Card], combination_cards: Array[Card]) -> Card:
		var weakest: Card = null
		for card in hand:
			if combination_cards.has(card):
				continue
			if weakest == null or card.rank < weakest.rank:
				weakest = card
		return weakest
