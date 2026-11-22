class_name FormInputData
extends Resource

enum ValueType {
	INTEGER,
	FLOAT,
	INTEGER_RANGE,
	FLOAT_RANGE,
	STRING,
	BOOLEAN,
	DROPDOWN
}

@export var name: String
@export var value_type: ValueType
@export var min_value: float
@export var max_value: float
@export var step: float = 1.0

@export var component: PackedScene
@export var initial_value: Variant
@export var options: Dictionary[String, Variant] = {}
