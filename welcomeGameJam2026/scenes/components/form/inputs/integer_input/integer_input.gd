class_name IntegerInput
extends FormInput

@onready var spin_box: SpinBox = $Content/SpinBox

var step: int = 1
var min_value: int = 0
var max_value: int = 100

func _ready() -> void:
	spin_box.value_changed.connect(_on_value_changed)
	super()

func setup(form_input_data: FormInputData, form_label: String) -> void:
	value = int(form_input_data.initial_value)
	min_value = int(form_input_data.min_value)
	max_value = int(form_input_data.max_value)
	step = int(form_input_data.step)
	super(form_input_data, form_label)

func refresh() -> void:
	super()
	var was_blocking_signals := spin_box.is_blocking_signals()
	spin_box.set_block_signals(true)
	spin_box.min_value = minf(min_value, spin_box.min_value)
	spin_box.max_value = maxf(max_value, spin_box.max_value)
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = step
	spin_box.set_value_no_signal(value)
	value = int(spin_box.value)
	spin_box.set_block_signals(was_blocking_signals)

func set_value(new_value: Variant) -> bool:
	if typeof(new_value) != TYPE_INT:
		push_error("Integer input '%s' requires an integer value." % label)
		return false
	spin_box.set_value_no_signal(new_value)
	if spin_box.value != new_value:
		spin_box.set_value_no_signal(value)
		push_error("Integer input '%s' cannot represent value: %s." % [label, new_value])
		return false
	_set_value(new_value)
	return true

func _on_value_changed(new_value: float) -> void:
	_set_value(int(new_value))
