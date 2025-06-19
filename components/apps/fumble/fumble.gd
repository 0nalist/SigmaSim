class_name FumbleUI
extends Pane

@export var fumble_profile_scene: PackedScene


@onready var profile_container: Control = %ProfileContainer

@onready var swipe_left_button: Button = %SwipeLeftButton
@onready var swipe_right_button: Button = %SwipeRightButton

@onready var team_button: Button = %TeamButton
@onready var field_button: Button = %FieldButton
@onready var game_button: Button = %GameButton

@onready var team_tab: Control = %TeamTab
@onready var field_tab: Control = %FieldTab
@onready var chats_tab: Control = %ChatsTab

func _ready():
	# Connect buttons to tab switch
	team_button.pressed.connect(show_team_tab)
	field_button.pressed.connect(show_field_tab)
	game_button.pressed.connect(show_chat_tab)

	swipe_left_button.pressed.connect(swipe_left)
	swipe_right_button.pressed.connect(swipe_right)

	# Start on field tab by default
	show_field_tab()
	show_next_npc()

func show_next_npc():
	var npc = NPCManager.encounter_new_npc()
	#var npc = NPCManager.get_npc_by_index(idx)
	# clear old
	for child in profile_container.get_children():
		child.queue_free()
	# instance new
	var ui = fumble_profile_scene.instantiate() as FumbleProfileUI
	
	profile_container.add_child(ui)
	ui.load_npc(npc)

func swipe_left():
	show_next_npc() # of selected gender preference

func swipe_right():
	show_next_npc() # of selected gender preference


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
