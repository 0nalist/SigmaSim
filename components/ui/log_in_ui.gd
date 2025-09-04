extends Control

@export var profile_creation_scene: PackedScene
@export var settings_panel_scene: PackedScene

@onready var logging_in_panel: Panel = %LoggingInPanel
@onready var logging_in_label: Label = %LoggingInLabel

@onready var profile_v_box_container: VBoxContainer = %ProfilesContainer
@onready var profile_row: HBoxContainer = %ProfileRow

@onready var settings_button: Button = %SettingsButton


const UserLoginCardUI = preload("res://components/ui/user_login_card_ui.gd")
var user_login_card_scene := preload("res://components/ui/user_login_card_ui.tscn")


func _ready() -> void:
	TimeManager.stop_time()
	logging_in_panel.hide()
	profile_v_box_container.show()

	load_and_display_saved_profiles()


func load_and_display_saved_profiles():
		for child in %ProfileRow.get_children():
				if child is UserLoginCardUI:
						child.queue_free()

		var metadata = SaveManager.load_slot_metadata()
		var entries: Array = []
		for key in metadata.keys():
				var slot_id := int(key.trim_prefix("slot_"))
				var data = metadata[key]

				if typeof(data) != TYPE_DICTIONARY or data.is_empty():
						print("⚠️ Skipping invalid profile slot:", slot_id)
						continue  # skip malformed or empty profiles

				var created_at := int(data.get("created_at", 0))
				var last_played_str: String = data.get("last_played", "")
				var last_played: int
				if last_played_str == "":
					last_played = 0
				else:
					last_played = Time.get_unix_time_from_datetime_string(last_played_str)

				var sort_time: int
				if created_at != 0:
					sort_time = created_at
				else:
					sort_time = last_played

				entries.append({"slot_id": slot_id, "data": data, "sort_time": sort_time})

		entries.sort_custom(func(a, b): return a.sort_time < b.sort_time)

		for entry in entries:
				var panel = user_login_card_scene.instantiate()
				profile_row.add_child(panel)
				panel.login_requested.connect(_on_profile_login_requested)
				panel.card_selected.connect(_on_card_selected)
				panel.set_profile_data(entry.data, entry.slot_id)



var dot_time = .1

var selected_card: UserLoginCardUI

func _on_profile_login_requested(slot_id: int) -> void:
	SaveManager.current_slot_id = slot_id
	print("login requested, slot_id:", slot_id)
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
	GameManager.load_desktop_env(slot_id)
	#SaveManager.save_to_slot(PlayerManager.get_slot_id())
	#queue_free()


func _on_new_profile_button_pressed() -> void:
	SaveManager.reset_managers()
	var profile_creator = profile_creation_scene.instantiate()
	add_child(profile_creator)
	profile_creator.connect("profile_created", _on_new_profile_created) #, save_slot)
	profile_creator.connect("new_profile_abandoned", _on_new_profile_abandoned)
	%AOLLogoHolder.hide()
	%ProfilesContainer.hide()

func _on_new_profile_created(slot_id):
	print("new profile created in slot " + str(slot_id))
	%AOLLogoHolder.show()
	%ProfilesContainer.show()
	load_and_display_saved_profiles()

func _on_new_profile_abandoned():
	load_and_display_saved_profiles()
	%AOLLogoHolder.show()
	%ProfilesContainer.show()


func _on_settings_button_pressed() -> void:
	var settings_panel = settings_panel_scene.instantiate()
	add_child(settings_panel)
	settings_panel.profile_list_updated.connect(load_and_display_saved_profiles)


func _on_power_button_pressed() -> void:
		get_tree().quit()

func _on_card_selected(card: UserLoginCardUI) -> void:
	# Collapse any other expanded login cards so only one is open at a time.
	for child in profile_row.get_children():
		if child is UserLoginCardUI and child != card:
			child.collapse()
	selected_card = card
	selected_card.expand()


func _on_credits_button_pressed() -> void:
	const CREDITS = preload("res://components/credits/credits.tscn")
	get_tree().add_child(CREDITS.instantiate())
