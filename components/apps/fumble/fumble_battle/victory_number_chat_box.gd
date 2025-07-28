extends MarginContainer
class_name VictoryNumberChatBox

signal victory_number_clicked

var is_npc_message = true

@onready var text_label: RichTextLabel = %TextLabel

func _ready():
	text_label.bbcode_enabled = true
	text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	text_label.connect("meta_clicked", _on_meta_clicked)
	# Optional: Change cursor shape on hover for links

func _on_meta_clicked(meta):
	emit_signal("victory_number_clicked")
