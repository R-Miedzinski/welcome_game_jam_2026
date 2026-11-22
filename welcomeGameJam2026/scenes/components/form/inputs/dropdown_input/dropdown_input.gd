class_name DropdownInput
extends FormInput

@onready var option_button: OptionButton = $Content/OptionButton

var options: Dictionary[String, Variant] = {}

func _ready() -> void:
	super()
	option_button.item_selected.connect(_on_item_selected)

func setup(form_input_data: FormInputData, form_label: String) -> void:
	options = form_input_data.options.duplicate()
	value = form_input_data.initial_value
	super(form_input_data, form_label)

func refresh() -> void:
	super()
	option_button.clear()
	for option_label in options:
		option_button.add_item(option_label)
		option_button.set_item_metadata(option_button.item_count - 1, options[option_label])
	option_button.select(options.values().find(value))

func set_value(new_value: Variant) -> bool:
	if not options.values().has(new_value):
		push_error("Dropdown input '%s' has no option for value: %s." % [label, new_value])
		return false
	if is_node_ready():
		option_button.select(options.values().find(new_value))
	_set_value(new_value)
	return true

func _on_item_selected(index: int) -> void:
	_set_value(option_button.get_item_metadata(index))
