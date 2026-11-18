class_name CardpairDecision
extends Resource

@export var decision_table: Dictionary[String, Decision] 

func get_decision(card1: String, card2: String) -> Decision:
  var card1_suit = card1[1]
  var card1_key = card1[0]
  if card1_key == "0":
    card1_key = "T"

  var card2_suit = card2[1]
  var card2_key = card2[0]
  if card2_key == "0":
    card2_key = "T"
  
  var key = card1_key + card2_key
  var unsuitedDecision = decision_table.get(card1_key + card2_key, null)
  if unsuitedDecision != null:
    return unsuitedDecision

  if card1_suit == card2_suit:
    key += "s"
  else:
    key += "o"
  return decision_table.get(key, null)