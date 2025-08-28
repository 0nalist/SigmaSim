extends Control

@export var profile_creation_scene: PackedScene
@export var settings_panel_scene: PackedScene
@export var show_quick_new_button: bool = true

@onready var logging_in_panel: Panel = %LoggingInPanel
@onready var logging_in_label: Label = %LoggingInLabel

@onready var profile_v_box_container: VBoxContainer = %ProfilesContainer
@onready var profile_row: HBoxContainer = %ProfileRow

@onready var settings_button: Button = %SettingsButton
@onready var quick_new_button: Button = $Panel/ProfilesContainer/ProfileRow/QuickNewButton


const UserLoginCardUI = preload("res://components/ui/user_login_card_ui.gd")
var user_login_card_scene := preload("res://components/ui/user_login_card_ui.tscn")
const PortraitFactory = preload("res://resources/portraits/portrait_factory.gd")


func _ready() -> void:
	TimeManager.stop_time()
	logging_in_panel.hide()
	profile_v_box_container.show()
	quick_new_button.visible = show_quick_new_button

	load_and_display_saved_profiles()


func load_and_display_saved_profiles():
        for child in %ProfileRow.get_children():
                if child is UserLoginCardUI:
                        child.queue_free()

	var metadata = SaveManager.load_slot_metadata()
	for key in metadata.keys():
		var slot_id := int(key.trim_prefix("slot_"))
		var data = metadata[key]

		if typeof(data) != TYPE_DICTIONARY or data.is_empty():
			print("⚠️ Skipping invalid profile slot:", slot_id)
			continue  # skip malformed or empty profiles

                var panel = user_login_card_scene.instantiate()
                profile_row.add_child(panel)
                panel.login_requested.connect(_on_profile_login_requested)
                panel.card_selected.connect(_on_card_selected)
                panel.set_profile_data(data, slot_id)



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

func _on_quick_new_button_pressed() -> void:
	SaveManager.reset_managers()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var name_data = NameManager.get_npc_name_by_index(rng.randi())
	var full_name: String = name_data.get("full_name", "Player")
	var user_data = PlayerManager.user_data
	user_data["name"] = full_name
	user_data["username"] = full_name.to_lower().replace(" ", "_")
	user_data["password"] = ""

	var gender_vec: Vector3 = name_data.get("gender_vector", Vector3.ONE)
	var total := gender_vec.x + gender_vec.y + gender_vec.z
	var roll := rng.randf() * total
	var pronouns := "they/them/theirs"
	if roll < gender_vec.x:
			pronouns = "she/her/hers"
	elif roll < gender_vec.x + gender_vec.y:
			pronouns = "he/him/his"
	user_data["pronouns"] = pronouns

	var attractions: Array[String] = []
	var x := 0.0
	var y := 0.0
	var z := 0.0
	if rng.randf() < 0.5:
			attractions.append("femmes")
			x = 100.0
	if rng.randf() < 0.5:
			attractions.append("mascs")
			y = 100.0
	if rng.randf() < 0.5:
			attractions.append("enbies")
			z = 100.0
	if attractions.is_empty():
			var choice = rng.randi_range(0, 2)
			match choice:
					0:
							attractions.append("femmes")
							x = 100.0
					1:
							attractions.append("mascs")
							y = 100.0
					2:
							attractions.append("enbies")
							z = 100.0
	user_data["attracted_to"] = attractions
	user_data["fumble_pref_x"] = x
	user_data["fumble_pref_y"] = y
	user_data["fumble_pref_z"] = z

	user_data["education_level"] = "Bachelor's Degree"
	user_data["starting_student_debt"] = 80000.0
	user_data["starting_credit_limit"] = 10000.0

	var backgrounds = [
			"The Dropout",
			"The Burnout",
			"The Gamer",
			"The Manager",
			"The Postgrad",
			"The Stoic",
			"Grandma's Favorite",
			"Pretty Privilege",
	]
	var background = backgrounds[rng.randi_range(0, backgrounds.size() - 1)]
	user_data["background"] = background
	user_data["background_path"] = ""

	var portrait_cfg = PortraitFactory.generate_config_for_name(full_name)
        user_data["portrait_config"] = portrait_cfg.to_dict()

	var slot_id = SaveManager.get_next_available_slot()
	SaveManager.initialize_new_profile(slot_id, user_data)
        await _on_profile_login_requested(slot_id)

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
        if selected_card and selected_card != card:
                selected_card.collapse()
        selected_card = card
        selected_card.expand()
