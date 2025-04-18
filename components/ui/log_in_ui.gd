extends Control

@export var profile_creation_scene: PackedScene

@onready var logging_in_panel: Panel = %LoggingInPanel
@onready var logging_in_label: Label = %LoggingInLabel

@onready var profile_v_box_container: VBoxContainer = %ProfilesContainer
@onready var profile_row: HBoxContainer = %ProfileRow


var profile_panel_scene := preload("res://components/ui/profile_panel.tscn")


func _ready() -> void:
	logging_in_panel.hide()
	profile_v_box_container.show()

	# Load and display all saved profiles
	var metadata = SaveManager.load_slot_metadata()

	for key in metadata.keys():
		var slot_id := int(key.trim_prefix("slot_"))
		var panel = profile_panel_scene.instantiate()
		profile_row.add_child(panel)
		await get_tree().process_frame
		panel.login_requested.connect(_on_profile_login_requested)
		panel.set_profile_data(metadata[key], slot_id)
		
		

var dot_time = .5

func _on_profile_login_requested(slot_id: int) -> void:
	print("login requested")
	await get_tree().create_timer(0.2).timeout
	profile_v_box_container.hide()
	logging_in_panel.show()

	await get_tree().create_timer(dot_time).timeout
	logging_in_label.text = "Locking in."
	await get_tree().create_timer(dot_time).timeout
	logging_in_label.text = "Locking in.."
	await get_tree().create_timer(dot_time).timeout
	logging_in_label.text = "Locking in..."
	await get_tree().create_timer(dot_time).timeout
	# Launch desktop environment
	var desktop_scene = preload("res://desktop_env.tscn")
	var desktop = desktop_scene.instantiate()
	get_parent().add_child(desktop)
	SaveManager.load_from_slot(slot_id)
	queue_free()


func _on_new_profile_button_pressed() -> void:
	pass # Replace with function body.
