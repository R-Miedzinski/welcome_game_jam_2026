class_name SliderInput
extends FormInput

@onready var slider: HSlider = $Content/Row/HSlider
@onready var value_label: Label = $Content/Row/ValueLabel

var min_value: float = 0.0
var max_value: float = 100.0
var step: float = 1.0
var is_integer: bool = false

func _ready() -> void:
	if value == null:
		value = 0.0
	super()
	slider.value_changed.connect(_on_value_changed)

func setup(form_input_data: FormInputData, form_label: String) -> void:
	is_integer = form_input_data.value_type == FormInputData.ValueType.INTEGER_RANGE
	if is_integer:
		value = int(form_input_data.initial_value)
	else:
		value = float(form_input_data.initial_value)
	min_value = form_input_data.min_value
	max_value = form_input_data.max_value
	step = form_input_data.step
	super(form_input_data, form_label)

func refresh() -> void:
	super()
	var was_blocking_signals := slider.is_blocking_signals()
	slider.set_block_signals(true)
	slider.min_value = minf(min_value, slider.min_value)
	slider.max_value = maxf(max_value, slider.max_value)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.rounded = is_integer
	slider.set_value_no_signal(value)
	if is_integer:
		value = int(slider.value)
	else:
		value = slider.value
	value_label.text = str(value)
	slider.set_block_signals(was_blocking_signals)

func set_value(new_value: Variant) -> bool:
	if typeof(new_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(new_value)):
		push_error("Slider input '%s' requires a finite numeric value." % label)
		return false
	if is_integer and (typeof(new_value) != TYPE_INT and float(new_value) != floor(float(new_value))):
		push_error("Slider input '%s' requires an integer value." % label)
		return false
	slider.set_value_no_signal(new_value)
	if not is_equal_approx(slider.value, float(new_value)):
		slider.set_value_no_signal(value)
		push_error("Slider input '%s' cannot represent value: %s." % [label, new_value])
		return false
	_on_value_changed(slider.value)
	return true

func _on_value_changed(new_value: float) -> void:
	var new_typed_value: Variant = new_value
	if is_integer:
		new_typed_value = int(new_value)
	value_label.text = str(new_typed_value)
	_set_value(new_typed_value)
