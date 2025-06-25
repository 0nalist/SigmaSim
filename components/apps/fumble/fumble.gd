class_name FumbleUI
extends Pane

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

# Add a variable for the card stack
var card_stack: ProfileCardStack = null

func _ready():
	# Find the ProfileCardStack instance in profile_container
	for child in profile_container.get_children():
		if child is ProfileCardStack:
			card_stack = child
			break
	if not card_stack:
		push_error("ProfileCardStack not found in profile_container!")
		return

	# Connect swipe button signals to the stack's methods
	swipe_left_button.pressed.connect(card_stack.swipe_left)
	swipe_right_button.pressed.connect(card_stack.swipe_right)

	# Optionally, connect to the stack's signals for further custom logic
	card_stack.card_swiped_left.connect(_on_card_swiped_left)
	card_stack.card_swiped_right.connect(_on_card_swiped_right)

	# Connect tab and slider events
	team_button.pressed.connect(show_team_tab)
	field_button.pressed.connect(show_field_tab)
	game_button.pressed.connect(show_chat_tab)
	x_slider.value_changed.connect(_on_gender_slider_changed)
	y_slider.value_changed.connect(_on_gender_slider_changed)
	z_slider.value_changed.connect(_on_gender_slider_changed)

	# Start on field tab by default
	show_field_tab()
	cancel_pride()

# These can be used to update your logic/UI in response to swipes
func _on_card_swiped_left(npc_idx):
	NPCManager.mark_npc_inactive_in_app(npc_idx, "fumble")
	# Add further logic if desired

func _on_card_swiped_right(npc_idx):
	NPCManager.set_relationship_status(npc_idx, "fumble", "liked")
	# Optionally, NPCManager.promote_to_persistent(npc_idx)
	# Add further logic if desired

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
