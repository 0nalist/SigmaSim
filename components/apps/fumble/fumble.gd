class_name FumbleUI
extends Pane

signal request_resize_x_to(pixels)

@onready var fumble_label: Label = %FumbleLabel
@onready var profile_container: Control = %ProfileContainer
@onready var swipe_left_button: Button = %SwipeLeftButton
@onready var swipe_right_button: Button = %SwipeRightButton


@onready var self_button: Button = %SelfButton
@onready var swipes_button: Button = %SwipesButton
@onready var chats_button: Button = %ChatsButton

@onready var self_tab: Control = %SelfTab
@onready var swipes_tab: Control = %SwipesTab
@onready var chats_tab: ChatsTab = %ChatsTab


@onready var confidence_progress_bar: StatProgressBar = %ConfidenceProgressBar




# Team tab UI
# Gender sliders
@onready var x_slider: HSlider = %XHSlider
@onready var y_slider: HSlider = %YHSlider
@onready var z_slider: HSlider = %ZHSlider
@onready var curiosity_slider: HSlider = %CuriosityHSlider


var preferred_gender: Vector3 = Vector3(0,0,0) # Should be moved to player data TODO
var curiosity: float = .85

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

	chats_tab.request_resize_x_to.connect(_on_resize_x_requested)

	# Connect swipe button signals to the stack's methods
	swipe_left_button.pressed.connect(card_stack.swipe_left)
	swipe_right_button.pressed.connect(card_stack.swipe_right)

	# Optionally, connect to the stack's signals for further custom logic
	card_stack.card_swiped_left.connect(_on_card_swiped_left)
	card_stack.card_swiped_right.connect(_on_card_swiped_right)

	# Connect tab and slider events
	self_button.pressed.connect(show_self_tab)
	swipes_button.pressed.connect(show_swipes_tab)
	chats_button.pressed.connect(show_chat_tab)
	
	x_slider.value_changed.connect(_on_gender_slider_changed)
	y_slider.value_changed.connect(_on_gender_slider_changed)
	z_slider.value_changed.connect(_on_gender_slider_changed)
	
	x_slider.drag_ended.connect(_on_gender_slider_drag_ended)
	y_slider.drag_ended.connect(_on_gender_slider_drag_ended)
	z_slider.drag_ended.connect(_on_gender_slider_drag_ended)
	# Start on field tab by default
	show_swipes_tab()
	cancel_pride()




func _on_card_swiped_left(npc_idx):
	NPCManager.mark_npc_inactive_in_app(npc_idx, "fumble")
	# Add further logic if desired

func _on_card_swiped_right(npc_idx):
	NPCManager.set_relationship_status(npc_idx, "fumble", "liked")
	PlayerManager.adjust_stat("confidence", 1)


func highlight_active(button: Button):
	self_button.modulate = Color.WHITE
	swipes_button.modulate = Color.WHITE
	chats_button.modulate = Color.WHITE
	button.modulate = Color.YELLOW

func show_self_tab():
	self_tab.visible = true
	swipes_tab.visible = false
	chats_tab.visible = false
	highlight_active(self_button)

func show_swipes_tab():
	self_tab.visible = false
	swipes_tab.visible = true
	chats_tab.visible = false
	highlight_active(swipes_button)

func show_chat_tab():
	self_tab.visible = false
	swipes_tab.visible = false
	chats_tab.visible = true
	highlight_active(chats_button)
	chats_tab.refresh_matches()
	chats_tab.refresh_battles()

var pride_material = preload("res://components/apps/fumble/fumble_label_pride_month_material.tres")

func _on_gender_slider_changed(value):
	# Convert sliders (0-100) to 0.0-1.0 floats
	preferred_gender = Vector3(
		x_slider.value / x_slider.max_value,
		y_slider.value / y_slider.max_value,
		z_slider.value / z_slider.max_value
	)
	#print("Sliders (scaled): X:", preferred_gender.x, "Y:", preferred_gender.y, "Z:", preferred_gender.z)
	
	#print("preferred gender: " + str(preferred_gender))
	# Pride label logic
	if preferred_gender.z > 0 or (preferred_gender.x > 0 and preferred_gender.y > 0):
		yassify_fumble_label()
	else:
		cancel_pride()

func _on_gender_slider_drag_ended(_changed):
	# (Redundant to clamp now, as values are already scaled)
	if card_stack:
		card_stack.refresh_pool_under_top_with_gender(preferred_gender)


func yassify_fumble_label() -> void:
	fumble_label.material = pride_material

func cancel_pride() -> void:
	fumble_label.material = null





func _on_curiosity_h_slider_value_changed(value: float) -> void:
	# If your slider goes 0-100, normalize to 0-1:
	var t = value
	if curiosity_slider.max_value > 1.01:
		t = value / curiosity_slider.max_value
	# Interpolate from 0.85 down to 0.01
	curiosity = lerp(0.85, 0.01, t)
	# Optionally print/debug
	#print("Curiosity %.2f  threshold: %.3f" % [t, curiosity])
	if card_stack:
		card_stack.set_curiosity(curiosity)
		card_stack.refresh_pool_under_top_with_gender(preferred_gender, curiosity)


func _on_resize_x_requested(pixels):
	# Bubble up to the window frame
	var window_frame = get_parent().get_parent().get_parent()
	if window_frame.size.x < 800:
		request_resize_x_to.emit(pixels)
