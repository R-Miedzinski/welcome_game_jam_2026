class_name MessageFeed
extends TextureRect

@export var max_messages: int = 100

@onready var message_container: VBoxContainer = %MessageContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer

func add_message(message: String) -> void:
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD
	message_container.add_child(label)
	message_container.move_child(label, message_container.get_child_count() - 1)

	# remove excess messages
	while message_container.get_child_count() > max_messages:
		var excess_label = message_container.get_child(0)
		if is_instance_valid(excess_label):
			excess_label.queue_free()

	call_deferred("_scroll_to_bottom")

func serialize_messages() -> Array[String]:
	var messages: Array[String] = []
	for child in message_container.get_children():
		if child is Label:
			messages.append(child.text)
	return messages

func deserialize_messages(messages: Array[String]) -> void:
	for message in messages:
		add_message(message)

func _scroll_to_bottom() -> void:
	var scroll_value = scroll_container.get_v_scroll_bar().max_value
	if scroll_value != scroll_container.get_v_scroll_bar().value:
		scroll_container.set_deferred("scroll_vertical", scroll_value)