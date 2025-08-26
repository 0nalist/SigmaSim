
class_name FumbleUI
extends Pane

signal request_resize_x_to(pixels)
signal request_resize_y_to(pixels)

var preferred_gender: Vector3 = Vector3(0, 0, 0)
var curiosity: float = 0.85
var card_stack: ProfileCardStack = null
var pride_material = preload("res://components/apps/fumble/fumble_label_pride_month_material.tres")

@onready var fumble_label = %FumbleLabel
@onready var profile_container: Control = %ProfileContainer
@onready var swipe_left_button: Button = %SwipeLeftButton
@onready var swipe_right_button: Button = %SwipeRightButton
@onready var money_swipe_button: Button = %MoneySwipeButton

@onready var self_button: Button = %SelfButton
@onready var swipes_button: Button = %SwipesButton
@onready var chats_button: Button = %ChatsButton

@onready var self_tab: Control = %SelfTab
@onready var swipes_tab: Control = %SwipesTab
@onready var chats_tab: ChatsTab = %ChatsTab

@onready var bio_text_edit: TextEdit = %BioTextEdit

@onready var tag_option_button1: OptionButton = %TagOption1
@onready var tag_option_button2: OptionButton = %TagOption2
@onready var tag_option_button3: OptionButton = %TagOption3
var tag_option_buttons: Array[OptionButton] = []

@onready var confidence_progress_bar: StatProgressBar = %ConfidenceProgressBar
@onready var ex_progress_bar: StatProgressBar = %ExProgressBar

# Team tab UI
@onready var x_slider: HSlider = %XHSlider
@onready var y_slider: HSlider = %YHSlider
@onready var z_slider: HSlider = %ZHSlider
@onready var curiosity_slider: HSlider = %CuriosityHSlider
@onready var fugly_container: HBoxContainer = %FuglyFilterContainer
@onready var fugly_slider: HSlider = %FuglyFilterSlider


func _ready():
	tag_option_buttons = [tag_option_button1, tag_option_button2, tag_option_button3]
	_setup_over_frames()


func _setup_over_frames() -> void:
	await get_tree().process_frame

	for child in profile_container.get_children():
		if child is ProfileCardStack:
			card_stack = child
			break
	if not card_stack:
		push_error("ProfileCardStack not found in profile_container!")
		return
	chats_tab.request_resize_x_to.connect(_on_resize_x_requested)
	chats_tab.request_resize_y_to.connect(_on_resize_y_requested)

	swipe_left_button.pressed.connect(card_stack.swipe_left)
	swipe_right_button.pressed.connect(card_stack.swipe_right)

	card_stack.card_swiped_left.connect(_on_card_swiped_left)
	card_stack.card_swiped_right.connect(_on_card_swiped_right)

	StatManager.connect_to_stat("confidence", self, "_on_confidence_changed")

	self_button.pressed.connect(show_self_tab)
	swipes_button.pressed.connect(show_swipes_tab)
	chats_button.pressed.connect(show_chat_tab)

	x_slider.value_changed.connect(_on_gender_slider_changed)
	y_slider.value_changed.connect(_on_gender_slider_changed)
	z_slider.value_changed.connect(_on_gender_slider_changed)

	x_slider.drag_ended.connect(_on_gender_slider_drag_ended)
	y_slider.drag_ended.connect(_on_gender_slider_drag_ended)
	z_slider.drag_ended.connect(_on_gender_slider_drag_ended)
	curiosity_slider.value_changed.connect(_on_curiosity_h_slider_value_changed)
	curiosity_slider.drag_ended.connect(_on_curiosity_h_slider_drag_ended)
	fugly_slider.drag_ended.connect(_on_fugly_slider_drag_ended)
	if Events.has_signal("fumble_fugly_filter_purchased"):
		Events.connect("fumble_fugly_filter_purchased", _on_fugly_filter_purchased)

	for i in range(tag_option_buttons.size()):
		tag_option_buttons[i].item_selected.connect(_on_tag_option_selected.bind(i))

		await get_tree().process_frame

	_populate_tag_dropdowns()
	_load_preferences()
	bio_text_edit.text = PlayerManager.get_var("bio", "")
	bio_text_edit.text_changed.connect(_on_bio_text_edit_text_changed)

	_update_fugly_filter_ui()

	confidence_progress_bar.update_value(StatManager.get_stat("confidence"))
	ex_progress_bar.update_value(StatManager.get_stat("ex"))

	_on_gender_slider_changed(0)
	_on_curiosity_h_slider_value_changed(curiosity_slider.value)

	await get_tree().process_frame

	await card_stack.refresh_swipe_pool_with_gender(preferred_gender, curiosity)

	visibility_changed.connect(_on_visibility_changed)
	cancel_pride()


func _on_card_swiped_left(npc_idx):
	NPCManager.mark_npc_inactive_in_app(npc_idx, "fumble")
	# Add further logic if needed


func _on_card_swiped_right(npc_idx):
	NPCManager.promote_to_persistent(npc_idx)
	NPCManager.set_relationship_status(npc_idx, "fumble", FumbleManager.FumbleStatus.LIKED)
	var new_confidence = clamp(StatManager.get_stat("confidence") + 1.0, 0.0, 100.0)
	StatManager.set_base_stat("confidence", new_confidence)
	chats_tab.call_deferred("refresh_matches")


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


func _on_gender_slider_changed(value):
	preferred_gender = Vector3(
		x_slider.value / x_slider.max_value,
		y_slider.value / y_slider.max_value,
		z_slider.value / z_slider.max_value
	)
	if preferred_gender.z > 0 or (preferred_gender.x > 0 and preferred_gender.y > 0):
		yassify_fumble_label()
	else:
		cancel_pride()


func _on_gender_slider_drag_ended(_changed):
	if card_stack:
		await card_stack.apply_gender_filter(preferred_gender)
	PlayerManager.set_var("fumble_pref_x", x_slider.value)
	PlayerManager.set_var("fumble_pref_y", y_slider.value)
	PlayerManager.set_var("fumble_pref_z", z_slider.value)


func yassify_fumble_label() -> void:
	fumble_label.material = pride_material


func cancel_pride() -> void:
	fumble_label.material = null


func _on_curiosity_h_slider_value_changed(value: float) -> void:
	var t = value
	if curiosity_slider.max_value > 1.01:
		t = value / curiosity_slider.max_value
	curiosity = lerp(0.85, 0.01, t)


func _on_curiosity_h_slider_drag_ended(_changed) -> void:
	if card_stack:
		await card_stack.apply_gender_filter(preferred_gender, curiosity)
	PlayerManager.set_var("fumble_curiosity", curiosity_slider.value)


func _on_fugly_slider_drag_ended(_changed) -> void:
	PlayerManager.set_var("fumble_fugly_filter_threshold", fugly_slider.value)
	if card_stack:
									await card_stack.apply_fugly_filter()
	chats_tab.refresh_matches()


func _on_fugly_filter_purchased(_level: int) -> void:
	_update_fugly_filter_ui()
	if card_stack:
									await card_stack.apply_fugly_filter()
	chats_tab.refresh_matches()


func _update_fugly_filter_ui() -> void:
	var level := UpgradeManager.get_level("fumble_fugly_filter")
	fugly_container.visible = level > 0
	fugly_slider.max_value = level
	var current = PlayerManager.get_var("fumble_fugly_filter_threshold", fugly_slider.value)
	fugly_slider.value = clamp(current, 0, fugly_slider.max_value)


func _load_preferences() -> void:
		x_slider.value = PlayerManager.get_var("fumble_pref_x", x_slider.value)
		y_slider.value = PlayerManager.get_var("fumble_pref_y", y_slider.value)
		z_slider.value = PlayerManager.get_var("fumble_pref_z", z_slider.value)
		curiosity_slider.value = PlayerManager.get_var("fumble_curiosity", curiosity_slider.value)
		fugly_slider.value = PlayerManager.get_var("fumble_fugly_filter_threshold", fugly_slider.value)

		var saved_prefs = [
						PlayerManager.get_var("fumble_type", ""),
						PlayerManager.get_var("fumble_like", ""),
						PlayerManager.get_var("fumble_dislike", ""),
		]

		for i in range(tag_option_buttons.size()):
						var ob = tag_option_buttons[i]
						var pref = saved_prefs[i]
						var selected_idx = 0
						if pref != "":
										for j in range(ob.get_item_count()):
														if ob.get_item_text(j) == pref:
																		selected_idx = j
																		break
						ob.select(selected_idx)

func _populate_tag_dropdowns() -> void:
	var battle_types: Array = []
	var file := FileAccess.open("res://data/npc_data/battle/npc_battle_types.json", FileAccess.READ)
	if file:
		var arr = JSON.parse_string(file.get_as_text())
		if arr is Array:
			for entry in arr:
				var t = str(entry.get("Type", ""))
				if t != "":
					battle_types.append(t)
	battle_types.sort()
	tag_option_button1.clear()
	tag_option_button1.add_item("--")
	for t in battle_types:
		tag_option_button1.add_item(t)
	tag_option_button1.select(0)

	var likes: Array = NPCFactory.LIKE_DATA.keys()
	likes.sort()
	for ob in [tag_option_button2, tag_option_button3]:
		ob.clear()
		ob.add_item("--")
		for like in likes:
			ob.add_item(like)
		ob.select(0)
func _on_tag_option_selected(index: int, which: int) -> void:
		var ob = tag_option_buttons[which]
		var text = ob.get_item_text(index)
		if text == "--":
				text = ""
		match which:
				0:
						PlayerManager.set_var("fumble_type", text)
				1:
						PlayerManager.set_var("fumble_like", text)
				2:
						PlayerManager.set_var("fumble_dislike", text)

func _on_resize_x_requested(pixels):
		var window_frame = get_parent().get_parent().get_parent()
		if window_frame.size.x < 800:
				request_resize_x_to.emit(pixels)


func _on_resize_y_requested(pixels):
	var window_frame = get_parent().get_parent().get_parent()
	if window_frame.size.y < 666:
		request_resize_y_to.emit(pixels)


func _on_bio_text_edit_text_changed() -> void:
				PlayerManager.set_var("bio", bio_text_edit.text)


func _on_visibility_changed() -> void:
				if not visible:
								return
				_load_preferences()
				_update_fugly_filter_ui()
				_on_gender_slider_changed(0)
				_on_curiosity_h_slider_value_changed(curiosity_slider.value)
				if card_stack and card_stack.cards.is_empty():
								await card_stack.refresh_swipe_pool_with_gender(preferred_gender, curiosity)


func _on_confidence_changed(value: float) -> void:
		await _wait_for_reaction_animations()
		confidence_progress_bar.update_value(value)


func _wait_for_reaction_animations() -> void:
	while true:
		var animating := false
		if card_stack and card_stack.is_animating:
			animating = true
		if not animating and chats_tab:
			for child in chats_tab.get_children():
				if child.get("is_animating"):
					animating = true
					break
		if not animating:
			break
		await get_tree().process_frame


func _exit_tree() -> void:
		StatManager.disconnect_from_stat("confidence", self, "_on_confidence_changed")
