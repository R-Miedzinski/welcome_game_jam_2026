class_name DecisionSchema
extends Resource

enum DecisionOutcome {
  FISH,
  FOLD,
  RAISE,
  CALL
}

@export var decision_table: Dictionary[int, CardpairDecision] # Dict[int (cards on table), decisiontable] CardpairDecision -> Dictionary[cardpair, Decision [canfish, cannotfish]]

func get_decision(cards_on_table: int, card1: String, card2: String) -> Decision:
  var cardpair_decision = decision_table.get(cards_on_table, null)
  if cardpair_decision:
    return cardpair_decision.get_decision(card1, card2)
  return null
