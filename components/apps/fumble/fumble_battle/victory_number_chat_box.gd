extends FumbleChatBox
class_name VictoryNumberChatBox

signal victory_number_clicked

#var is_npc_message = true

#@onready var text_label: RichTextLabel = %TextLabel

func _ready():
	super._ready()
	text_label.bbcode_enabled = true
	text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	#text_label.connect("meta_clicked", _on_meta_clicked)
	# Optional: Change cursor shape on hover for links

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("victory_number_clicked")
