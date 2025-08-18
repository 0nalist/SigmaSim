#settings_window.gd
extends Pane

@onready var fullscreen_check_box: CheckBox = %FullscreenCheckBox
@onready var windowed_check_box: CheckBox = %WindowedCheckBox
@onready var autosave_check_box: CheckBox = %AutosaveCheckBox

@onready var blue_warp_button: CheckButton = %BlueWarpButton
@onready var comic_dots1_button: CheckButton = %ComicDots1Button
@onready var comic_dots2_button: CheckButton = %ComicDots2Button
@onready var blue_warp: Node = get_node_or_null("%BlueWarp")
@onready var comic_dots1: Node = get_node_or_null("%ComicDots1")
@onready var comic_dots2: Node = get_node_or_null("%ComicDots2")

func _ready() -> void:
	update_checked_mode()
	#app_title = "Settings"
	#emit_signal("title_updated", app_title)
	# Disable fullscreen if running in embedded mode
	if OS.has_feature("editor") or DisplayServer.get_name() == "headless":
		fullscreen_check_box.disabled = true
	#%SiggyButton.toggled_on = Siggy.toggled_on
	autosave_check_box.button_pressed = TimeManager.autosave_enabled
	if blue_warp:
		blue_warp_button.button_pressed = blue_warp.visible
	if comic_dots1:
		comic_dots1_button.button_pressed = comic_dots1.visible
	if comic_dots2:
		comic_dots2_button.button_pressed = comic_dots2.visible

func update_checked_mode() -> void:
	var mode = DisplayServer.window_get_mode()
	match mode:
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			fullscreen_check_box.button_pressed = true
			windowed_check_box.button_pressed = false
		DisplayServer.WINDOW_MODE_WINDOWED:
			fullscreen_check_box.button_pressed = false
			windowed_check_box.button_pressed = true
		_:
			# Handle other modes if needed
			fullscreen_check_box.button_pressed = false
			windowed_check_box.button_pressed = true

func _on_fullscreen_check_box_pressed() -> void:
	if fullscreen_check_box.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		windowed_check_box.button_pressed = false

func _on_windowed_check_box_pressed() -> void:
	if windowed_check_box.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		fullscreen_check_box.button_pressed = false

func _on_check_button_toggled(toggled_on: bool) -> void:
	print("toggled_on" + str(toggled_on))

func _on_siggy_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%SiggyButton.text = "Never ever show me Siggy ever again"
	else:
		%SiggyButton.text = "Siggy. Please come back. I miss you"

func _on_autosave_check_box_toggled(toggled_on: bool) -> void:
	TimeManager.autosave_enabled = toggled_on

func _on_blue_warp_button_toggled(toggled_on: bool) -> void:
	if blue_warp:
		blue_warp.visible = toggled_on

func _on_comic_dots_1_button_toggled(toggled_on: bool) -> void:
	if comic_dots1:
		comic_dots1.visible = toggled_on

func _on_comic_dots_2_button_toggled(toggled_on: bool) -> void:
	if comic_dots2:
		comic_dots2.visible = toggled_on
