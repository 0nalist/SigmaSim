extends PanelContainer

signal profile_list_updated

@onready var profile_selector: OptionButton = %ProfileSelector
@onready var delete_button: Button = %DeleteButton
@onready var reset_button: Button = %ResetButton
@onready var close_button: Button = %CloseButton

var slot_metadata := {}

func _ready():
	slot_metadata = SaveManager.load_slot_metadata()
	
	await  get_tree().process_frame
	delete_button.pressed.connect(_on_delete_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(queue_free)
	
	
	_update_selector()

func _update_selector():
	profile_selector.clear()
	for key in slot_metadata.keys():
		var slot_id = int(key.trim_prefix("slot_"))
		var name = slot_metadata[key].get("name", "Unnamed")
		profile_selector.add_item("Slot %d: %s" % [slot_id, name], slot_id)

func _on_delete_pressed():
	var slot_id = profile_selector.get_selected_id()
	SaveManager.delete_save(slot_id)
	_update_selector()
	emit_signal("profile_list_updated")

func _on_reset_pressed():
	var slot_id = profile_selector.get_selected_id()
	var metadata = slot_metadata.get("slot_%d" % slot_id, {})
	var username = metadata.get("username", "user")
	SaveManager.initialize_new_profile(slot_id, {
		"name": metadata.get("name", "Unnamed"),
		"username": username,
		"profile_picture_path": metadata.get("profile_picture_path", ""),
		"background": metadata.get("background_path", ""),
	})
	_update_selector()
	emit_signal("profile_list_updated")
