class_name Form
extends Control

# const IntegerInputClass = preload("res://scenes/components/form/inputs/integer_input/integer_input.gd")
# const StringInputClass = preload("res://scenes/components/form/inputs/text_input/string_input.gd")
# const SliderInputClass = preload("res://scenes/components/form/inputs/slider_input/slider_input.gd")
# const DropdownInputClass = preload("res://scenes/components/form/inputs/dropdown_input/dropdown_input.gd")

signal form_submitted(form_name: String, form_data: Dictionary)

@export var form_name: String
@export var form_schema: Dictionary[String, FormInputData] = {}
@export var field_order: Array[String] = []
var form_data: Dictionary = {}
var form_controls: Dictionary[String, FormInput] = {}
var _build_valid: bool = true
var _data_valid: bool = true

@onready var input_container: BoxContainer = %InputContainer

func _ready() -> void:
	build_form()

func build_form() -> void:
	for child in input_container.get_children():
		input_container.remove_child(child)
		child.queue_free()
	form_data.clear()
	form_controls.clear()
	_build_valid = true
	_data_valid = true

	var ordered_fields: Dictionary[String, bool] = {}
	for field_name in field_order:
		if not form_schema.has(field_name):
			_build_valid = false
			push_error("Form '%s' has an unknown field '%s' in field_order." % [form_name, field_name])
		elif ordered_fields.has(field_name):
			_build_valid = false
			push_error("Form '%s' has a duplicate field '%s' in field_order." % [form_name, field_name])
		else:
			ordered_fields[field_name] = true
	if not _build_valid:
		return

	for field_name in field_order:
		_add_field_to_form(field_name, form_schema[field_name])
	for field_name in form_schema:
		if not ordered_fields.has(field_name):
			_add_field_to_form(field_name, form_schema[field_name])

func get_form_data() -> Dictionary:
	return form_data.duplicate()

func setup_form_data(new_form_data: Dictionary) -> bool:
	_data_valid = _build_valid
	for field_name in form_schema:
		if not new_form_data.has(field_name):
			push_error("Form '%s' is missing data for field '%s'." % [form_name, field_name])
			_data_valid = false
		elif form_controls.has(field_name) and not form_controls[field_name].set_value(new_form_data[field_name]):
			_data_valid = false
	for field_name in new_form_data:
		if not form_schema.has(field_name):
			push_error("Form '%s' has no field for data key '%s'." % [form_name, field_name])
			_data_valid = false
	return _data_valid

func is_valid() -> bool:
	return _build_valid and _data_valid

func submit() -> void:
	if not is_valid():
		push_error("Form submission failed due to invalid form build or data.")
		return
	form_submitted.emit(form_name, get_form_data())

func reset() -> void:
	build_form()

func _add_field_to_form(field_name: String, field_data: FormInputData) -> void:
	if field_data == null:
		_build_valid = false
		push_error("Form field '%s' has no input definition." % field_name)
		return
	match field_data.value_type:
		FormInputData.ValueType.INTEGER, FormInputData.ValueType.STRING:
			pass
		FormInputData.ValueType.INTEGER_RANGE, FormInputData.ValueType.FLOAT_RANGE:
			if not _validate_range(field_name, field_data):
				_build_valid = false
				return

		FormInputData.ValueType.DROPDOWN:
			if not _validate_dropdown(field_name, field_data):
				_build_valid = false
				return
		_:
			_build_valid = false
			push_error("Form field '%s' has an unsupported input type: %s." % [field_name, field_data.value_type])
			return

	if field_data.component == null:
		_build_valid = false
		push_error("Form field '%s' has no input scene." % field_name)
		return

	var input_node := field_data.component.instantiate()
	if not input_node is FormInput:
		_build_valid = false
		push_error("Form field '%s' must use a FormInput scene." % field_name)
		input_node.free()
		return

	if (field_data.value_type == FormInputData.ValueType.INTEGER and not input_node is IntegerInput
			or field_data.value_type == FormInputData.ValueType.STRING and not input_node is StringInput
			or field_data.value_type in [FormInputData.ValueType.INTEGER_RANGE, FormInputData.ValueType.FLOAT_RANGE] and not input_node is SliderInput
			or field_data.value_type == FormInputData.ValueType.DROPDOWN and not input_node is DropdownInput):
		_build_valid = false
		push_error("Form field '%s' has an input scene that does not match its type." % field_name)
		input_node.free()
		return

	var form_input: FormInput = input_node
	form_input.input_changed.connect(_on_input_changed.bind(field_name))
	form_input.setup(field_data, field_name)
	form_controls[field_name] = form_input
	input_container.add_child(form_input)
	form_data[field_name] = form_input.value

func _validate_dropdown(field_name: String, field_data: FormInputData) -> bool:
	var values := field_data.options.values()
	if values.is_empty() or not values.has(field_data.initial_value):
		push_error("Form field '%s' needs options containing its initial value." % field_name)
		return false
	for index in values.size():
		if values.find(values[index]) != index:
			push_error("Form field '%s' has duplicate dropdown values." % field_name)
			return false
	return true

func _validate_range(field_name: String, field_data: FormInputData) -> bool:
	var minimum := field_data.min_value
	var maximum := field_data.max_value
	var step := field_data.step
	if typeof(field_data.initial_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(field_data.initial_value)):
		push_error("Form field '%s' requires a finite numeric initial value." % field_name)
		return false
	if not is_finite(minimum) or not is_finite(maximum) or not is_finite(step) or minimum > maximum or step < 0:
		push_error("Form field '%s' has invalid range bounds or step." % field_name)
		return false
	if field_data.value_type == FormInputData.ValueType.INTEGER_RANGE:
		if minimum != floor(minimum) or maximum != floor(maximum) or step < 1 or step != floor(step) or float(field_data.initial_value) != floor(float(field_data.initial_value)):
			push_error("Form field '%s' requires an integer initial value, integer range bounds and a positive integer step." % field_name)
			return false
	return true

func _on_input_changed(new_value: Variant, field_name: String) -> void:
	form_data[field_name] = new_value
