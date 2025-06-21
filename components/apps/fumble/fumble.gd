class_name FumbleUI
extends Pane

@export var fumble_profile_scene: PackedScene

@onready var fumble_label: Label = %FumbleLabel
@onready var profile_container: Control = %ProfileContainer
@onready var swipe_left_button: Button = %SwipeLeftButton
@onready var swipe_right_button: Button = %SwipeRightButton
@onready var team_button: Button = %TeamButton
@onready var field_button: Button = %FieldButton
@onready var game_button: Button = %GameButton
@onready var team_tab: Control = %TeamTab
@onready var field_tab: Control = %FieldTab
@onready var chats_tab: Control = %ChatsTab

# Team tab UI
@onready var x_slider: HSlider = %XHSlider
@onready var y_slider: HSlider = %YHSlider
@onready var z_slider: HSlider = %ZHSlider

# Currently shown NPC index (to track which slot to mark as inactive)
var current_npc_idx: int = -1

func _ready():
	# Connect buttons to tab switch
	team_button.pressed.connect(show_team_tab)
	field_button.pressed.connect(show_field_tab)
	game_button.pressed.connect(show_chat_tab)

	x_slider.value_changed.connect(_on_gender_slider_changed)
	y_slider.value_changed.connect(_on_gender_slider_changed)
	z_slider.value_changed.connect(_on_gender_slider_changed)

	swipe_left_button.pressed.connect(swipe_left)
	swipe_right_button.pressed.connect(swipe_right)

	# Start on field tab by default
	show_field_tab()
	show_next_npc()
	cancel_pride()

func show_next_npc():
	var npc = NPCManager.encounter_new_npc_for_app("fumble")
	current_npc_idx = NPCManager.get_npc_index(npc)
	for child in profile_container.get_children():
		child.queue_free()
	var ui = fumble_profile_scene.instantiate() as FumbleProfileUI
	profile_container.add_child(ui)
	ui.load_npc(npc)

func swipe_left():
	if current_npc_idx != -1:
		NPCManager.mark_npc_inactive_in_app(current_npc_idx, "fumble")
	show_next_npc()

func swipe_right():
	if current_npc_idx != -1:
		NPCManager.set_relationship_status(current_npc_idx, "fumble", "liked")
		# Optionally promote to persistent if you want chat to be possible!
		# NPCManager.promote_to_persistent(current_npc_idx)
	show_next_npc()

func highlight_active(button: Button):
	team_button.modulate = Color.WHITE
	field_button.modulate = Color.WHITE
	game_button.modulate = Color.WHITE
	button.modulate = Color.YELLOW

func show_team_tab():
	team_tab.visible = true
	field_tab.visible = false
	chats_tab.visible = false
	highlight_active(team_button)

func show_field_tab():
	team_tab.visible = false
	field_tab.visible = true
	chats_tab.visible = false
	highlight_active(field_button)

func show_chat_tab():
	team_tab.visible = false
	field_tab.visible = false
	chats_tab.visible = true
	highlight_active(game_button)

var pride_material = preload("res://components/apps/fumble/fumble_label_pride_month_material.tres")

func _on_gender_slider_changed(value):
	if z_slider.value > 0 or (x_slider.value > 0 and y_slider.value > 0):
		yassify_fumble_label()
	else:
		cancel_pride()

func yassify_fumble_label() -> void:
	fumble_label.material = pride_material

func cancel_pride() -> void:
	fumble_label.material = null
