# Poker hand evaluation

`poker_engine.gd` contains `Card` and `PokerEngine`. Preload the script, build
two private cards and optionally supply zero to five community cards:

```gdscript
const Poker = preload("res://scripts/poker_engine.gd")

var hand: Array[Poker.Card] = [Poker.Card.new("AS"), Poker.Card.new("KD")]
var board: Array[Poker.Card] = [
	Poker.Card.new("AH"), Poker.Card.new("7S"), Poker.Card.new("2C")
]
var result := Poker.PokerEngine.evaluate_hand(hand, board)
```

Ranks are `2`-`9`, `0` (ten), `J`, `Q`, `K`, `A`; suits are `D`, `C`, `H`,
`S`. `10` is also accepted as a ten, but `get_card_string()` returns `0` to
preserve the existing notation. Invalid cards, duplicate cards, an incorrect
private hand size or more than five board cards produce an error and an empty
evaluation result.

The result contains:

- `combination`: a `Poker.Combination` value. A royal flush is a separate
  category above a straight flush.
- `hand_score`: an integer including the combination and all relevant
  tiebreakers. The higher score wins; equal scores tie. Compare results with
  the same number of known cards. A partial-hand score is not a win probability.
- `tiebreakers`: ranks in comparison order, using 2 through 14 for two through
  ace. An ace-low straight has a single tiebreaker of 5.
- `highest_cards`: the selected best five cards, sorted by descending rank.
  With fewer than five known cards, it contains all known cards. For an
  ace-low straight, the ace still appears first in this display order.
- `combination_cards`: cards forming the selected combination, excluding
  kickers. For high card this is empty. Suits do not break ties; if several
  equivalent selections exist, one of them is returned.
- `weakest_card`: the lowest-ranked private card outside `combination_cards`,
  or `null` if neither qualifies. Equal-ranked candidates use hand order.
  This simple heuristic does not consider draws or exchange probabilities.
- `is_complete`: whether at least five cards are known.

With fewer than five cards, the engine evaluates combinations already present,
such as a pocket pair; it does not predict future cards. With five to seven
cards it selects the best five, including board-only hands.

Run the focused tests with a Godot 4 executable from the project directory:

```text
godot --headless --path . --script res://tests/poker_engine_test.gd
godot --headless --path . --script res://tests/poker_engine_invalid_test.gd
```

The second command intentionally prints error messages while checking invalid
input handling.
