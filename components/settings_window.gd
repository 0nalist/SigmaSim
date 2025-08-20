#settings_window.gd
extends Pane

@onready var fullscreen_check_box: CheckBox = %FullscreenCheckBox
@onready var windowed_check_box: CheckBox = %WindowedCheckBox
@onready var autosave_check_box: CheckBox = %AutosaveCheckBox
@onready var autosave_timer_label: Label = %AutosaveTimerLabel

@onready var blue_warp_button: CheckButton = %BlueWarpButton
@onready var comic_dots1_button: CheckButton = %ComicDots1Button
@onready var comic_dots2_button: CheckButton = %ComicDots2Button
@onready var waves_button: CheckButton = %WavesButton
@onready var bottom_color_picker: ColorPickerButton = %BottomColorPicker
@onready var top_color_picker: ColorPickerButton = %TopColorPicker
@onready var wave_amp_slider: HSlider = %WaveAmpSlider
@onready var wave_size_slider: HSlider = %WaveSizeSlider
@onready var wave_time_mul_slider: HSlider = %WaveTimeMulSlider
@onready var total_phases_slider: HSlider = %TotalPhasesSlider
@onready var blue_warp_stretch_slider: HSlider = %BlueWarpStretchSlider
@onready var blue_warp_thing1_slider: HSlider = %BlueWarpThing1Slider
@onready var blue_warp_thing2_slider: HSlider = %BlueWarpThing2Slider
@onready var blue_warp_thing3_slider: HSlider = %BlueWarpThing3Slider
@onready var blue_warp_speed_slider: HSlider = %BlueWarpSpeedSlider
@onready var comic_dots_color_picker: ColorPickerButton = %ComicDotsColorPicker
@onready var comic_dots_multiplier_slider: HSlider = %ComicDotsMultiplierSlider
@onready var comic_dots_speed_slider: HSlider = %ComicDotsSpeedSlider
@onready var waves_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/WavesShader").material
@onready var blue_warp_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/BlueWarpShader").material
@onready var comic_dots1_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/ComicDotsBlueVert").material
@onready var comic_dots2_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/ComicDotsBlueHor").material


func _ready() -> void:
	update_checked_mode()
	#app_title = "Settings"
	#emit_signal("title_updated", app_title)
	# Disable fullscreen if running in embedded mode
	if OS.has_feature("editor") or DisplayServer.get_name() == "headless":
		fullscreen_check_box.disabled = true
	#%SiggyButton.toggled_on = Siggy.toggled_on
		autosave_check_box.button_pressed = TimeManager.autosave_enabled
		_update_autosave_timer_label()
		TimeManager.minute_passed.connect(_on_minute_passed)
		blue_warp_button.button_pressed = Events.is_desktop_background_visible("BlueWarp")
		comic_dots1_button.button_pressed = Events.is_desktop_background_visible("ComicDots1")
		comic_dots2_button.button_pressed = Events.is_desktop_background_visible("ComicDots2")
		waves_button.button_pressed = Events.is_desktop_background_visible("Waves")
                bottom_color_picker.color = waves_shader_material.get_shader_parameter("bottom_color")
                top_color_picker.color = waves_shader_material.get_shader_parameter("top_color")
                wave_amp_slider.value = waves_shader_material.get_shader_parameter("wave_amp")
                wave_size_slider.value = waves_shader_material.get_shader_parameter("wave_size")
                wave_time_mul_slider.value = waves_shader_material.get_shader_parameter("wave_time_mul")
                total_phases_slider.value = waves_shader_material.get_shader_parameter("total_phases")
                blue_warp_stretch_slider.value = blue_warp_shader_material.get_shader_parameter("stretch")
                blue_warp_thing1_slider.value = blue_warp_shader_material.get_shader_parameter("thing1")
                blue_warp_thing2_slider.value = blue_warp_shader_material.get_shader_parameter("thing2")
                blue_warp_thing3_slider.value = blue_warp_shader_material.get_shader_parameter("thing3")
                blue_warp_speed_slider.value = blue_warp_shader_material.get_shader_parameter("speed")
                comic_dots_color_picker.color = comic_dots1_shader_material.get_shader_parameter("circle_color")
                comic_dots_multiplier_slider.value = comic_dots1_shader_material.get_shader_parameter("circle_multiplier")
                comic_dots_speed_slider.value = comic_dots1_shader_material.get_shader_parameter("speed")

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
		_update_autosave_timer_label()

func _on_blue_warp_button_toggled(toggled_on: bool) -> void:
	Events.set_desktop_background_visible("BlueWarp", toggled_on)

func _on_comic_dots_1_button_toggled(toggled_on: bool) -> void:
	Events.set_desktop_background_visible("ComicDots1", toggled_on)

func _on_comic_dots_2_button_toggled(toggled_on: bool) -> void:
	Events.set_desktop_background_visible("ComicDots2", toggled_on)

func _on_waves_button_toggled(toggled_on: bool) -> void:
	Events.set_desktop_background_visible("Waves", toggled_on)

func _on_bottom_color_picker_color_changed(color: Color) -> void:
	waves_shader_material.set_shader_parameter("bottom_color", color)

func _on_top_color_picker_color_changed(color: Color) -> void:
        waves_shader_material.set_shader_parameter("top_color", color)

func _on_wave_amp_slider_value_changed(value: float) -> void:
        waves_shader_material.set_shader_parameter("wave_amp", value)

func _on_wave_size_slider_value_changed(value: float) -> void:
        waves_shader_material.set_shader_parameter("wave_size", value)

func _on_wave_time_mul_slider_value_changed(value: float) -> void:
        waves_shader_material.set_shader_parameter("wave_time_mul", value)

func _on_total_phases_slider_value_changed(value: float) -> void:
        waves_shader_material.set_shader_parameter("total_phases", value)

func _on_blue_warp_stretch_slider_value_changed(value: float) -> void:
        blue_warp_shader_material.set_shader_parameter("stretch", value)

func _on_blue_warp_thing1_slider_value_changed(value: float) -> void:
        blue_warp_shader_material.set_shader_parameter("thing1", value)

func _on_blue_warp_thing2_slider_value_changed(value: float) -> void:
        blue_warp_shader_material.set_shader_parameter("thing2", value)

func _on_blue_warp_thing3_slider_value_changed(value: float) -> void:
        blue_warp_shader_material.set_shader_parameter("thing3", value)

func _on_blue_warp_speed_slider_value_changed(value: float) -> void:
        blue_warp_shader_material.set_shader_parameter("speed", value)

func _on_comic_dots_color_picker_color_changed(color: Color) -> void:
        comic_dots1_shader_material.set_shader_parameter("circle_color", color)
        comic_dots2_shader_material.set_shader_parameter("circle_color", color)

func _on_comic_dots_multiplier_slider_value_changed(value: float) -> void:
        comic_dots1_shader_material.set_shader_parameter("circle_multiplier", value)
        comic_dots2_shader_material.set_shader_parameter("circle_multiplier", value)

func _on_comic_dots_speed_slider_value_changed(value: float) -> void:
        comic_dots1_shader_material.set_shader_parameter("speed", value)
        comic_dots2_shader_material.set_shader_parameter("speed", value)

func _on_minute_passed(_total_minutes: int) -> void:
		_update_autosave_timer_label()

func _update_autosave_timer_label() -> void:
	if not TimeManager.autosave_enabled:
		autosave_timer_label.text = "Autosave disabled"
		return
	if not is_instance_valid(SaveManager) or SaveManager.current_slot_id <= 0:
		autosave_timer_label.text = "No save loaded"
		return
	var total_minutes_left = TimeManager.autosave_interval * 60 - (TimeManager.autosave_hour_counter * 60 + TimeManager.current_minute)
	total_minutes_left = max(total_minutes_left, 0)
	var hours = total_minutes_left / 60
	var minutes = total_minutes_left % 60
	autosave_timer_label.text = "%d:%02d" % [hours, minutes]
