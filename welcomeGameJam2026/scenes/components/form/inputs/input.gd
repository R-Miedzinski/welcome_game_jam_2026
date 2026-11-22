@abstract class_name FormInput
extends MarginContainer

signal input_changed(new_value: Variant)

var label: String = ""
var value: Variant

@onready var label_node: Label = $Content/Label

func setup(form_input_data: FormInputData, form_label: String) -> void:
	label = form_input_data.name if not form_input_data.name.is_empty() else form_label
	
	if is_node_ready():
		refresh()

func _ready() -> void:
	refresh()

func refresh() -> void:
	label_node.text = label

@abstract func set_value(new_value: Variant) -> bool

func _set_value(new_value: Variant) -> void:
	if value == new_value:
		return
	value = new_value
	input_changed.emit(new_value)
