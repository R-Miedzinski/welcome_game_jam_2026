class_name StringInput
extends FormInput

@onready var line_edit: LineEdit = $Content/LineEdit

func _ready() -> void:
	line_edit.text_changed.connect(_on_text_changed)
	super()
	
func setup(form_input_data: FormInputData, form_label: String) -> void:
	value = str(form_input_data.initial_value)
	super(form_input_data, form_label)

func refresh() -> void:
	super()
	line_edit.text = value

func set_value(new_value: Variant) -> bool:
	if typeof(new_value) != TYPE_STRING:
		push_error("String input '%s' requires a string value." % label)
		return false
	line_edit.text = new_value
	_set_value(new_value)
	return true

func _on_text_changed(new_value: String) -> void:
	_set_value(new_value)
