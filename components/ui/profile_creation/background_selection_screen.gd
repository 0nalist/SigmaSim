extends Control
signal step_valid(valid: bool)


@onready var dropout_button: Button = %DropoutButton
@onready var burnout_button: Button = %BurnoutButton
@onready var gamer_button: Button = %GamerButton
@onready var manager_button: Button = %ManagerButton
@onready var postgrad_button: Button = %PostgradButton
@onready var stoic_button: Button = %StoicButton

@onready var tooltip_popup: PanelContainer = %TooltipPopup
@onready var tooltip_label: Label = %TooltipLabel

var tooltip_tween: Tween = null

var selected_background_name: String = ""
var selected_background: String = ""

func _ready():
	for button in [
		dropout_button, burnout_button, gamer_button,
		manager_button, postgrad_button, stoic_button
	]:
		button.toggle_mode = true

func toggle_exclusive(button_to_keep_on: Button) -> void:
	for button in [
		dropout_button, burnout_button, gamer_button,
		manager_button, postgrad_button, stoic_button
	]:
		if button != button_to_keep_on:
			button.set_pressed_no_signal(false)


func _on_background_selected(button: Button) -> void:
	toggle_exclusive(button)
	show_tooltip_from_button(button)
	emit_signal("step_valid", true)

func save_data() -> void:
	var user_data = PlayerManager.user_data
	user_data["background_path"] = selected_background
	user_data["background"] = selected_background_name
	print("Selected background name: " + selected_background_name)
	print("Selected background path: " + selected_background)

	
func show_tooltip_from_button(button: Button) -> void:
	var tooltip_text = button.tooltip_text
	if tooltip_text == "":
		return

	tooltip_label.text = tooltip_text
	tooltip_popup.visible = true
	tooltip_popup.modulate.a = 1.0

	await get_tree().process_frame

	# Get button's global center point
	var button_global_rect = button.get_global_rect()
	var button_center_global = button_global_rect.position + button_global_rect.size / 2

	# Convert to local space relative to tooltip's parent
	var local_pos = tooltip_popup.get_parent().get_global_transform_with_canvas().affine_inverse() * button_center_global

	# Position 250px above button center, centered horizontally
	var tooltip_size = tooltip_popup.size
	tooltip_popup.position = local_pos - Vector2(tooltip_size.x / 2, tooltip_popup.size.y)

	# Kill existing tween if needed
	if tooltip_tween and tooltip_tween.is_valid():
		tooltip_tween.kill()

	# Animate up 
	tooltip_tween = get_tree().create_tween()
	tooltip_tween.tween_property(tooltip_popup, "position:y", tooltip_popup.position.y - 30, 0.4)






func _on_dropout_button_pressed() -> void:
	var panel = dropout_button.get_parent()
	selected_background = get_path_to_texture_of_panel(panel)
	selected_background_name = "The Dropout"
	_on_background_selected(dropout_button)


func _on_burnout_button_pressed() -> void:
	var panel = burnout_button.get_parent()
	selected_background = get_path_to_texture_of_panel(panel)
	print("selected bg: " + str(selected_background))
	selected_background_name = "The Burnout"
	_on_background_selected(burnout_button)

func _on_gamer_button_pressed() -> void:
	var panel = gamer_button.get_parent()
	selected_background = get_path_to_texture_of_panel(panel)
	selected_background_name = "The Gamer"
	_on_background_selected(gamer_button)

func _on_manager_button_pressed() -> void:
	var panel = manager_button.get_parent()
	selected_background = get_path_to_texture_of_panel(panel)
	selected_background_name = "The Manager"
	_on_background_selected(manager_button)

func _on_postgrad_button_pressed() -> void:
	var panel = postgrad_button.get_parent()
	selected_background = get_path_to_texture_of_panel(panel)
	selected_background_name = "The Postgrad"
	_on_background_selected(postgrad_button)

func _on_stoic_button_pressed() -> void:
	var panel = stoic_button.get_parent()
	selected_background = get_path_to_texture_of_panel(panel)
	selected_background_name = "The Stoic"
	_on_background_selected(stoic_button)

func get_path_to_texture_of_panel(tex_rect: TextureRect) -> String:
	return tex_rect.texture.resource_path if tex_rect.texture else ""
