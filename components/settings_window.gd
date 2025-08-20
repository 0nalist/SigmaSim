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
@onready var electric_button: CheckButton = %ElectricButton
@onready var electric_bg_color_picker: ColorPickerButton = %ElectricBGColorPicker
@onready var electric_line_color_picker: ColorPickerButton = %ElectricLineColorPicker
@onready var electric_freq_slider: HSlider = %ElectricFreqSlider
@onready var electric_height_slider: HSlider = %ElectricHeightSlider
@onready var electric_speed_slider: HSlider = %ElectricSpeedSlider
@onready var electric_scale_x_slider: HSlider = %ElectricScaleXSlider
@onready var electric_scale_y_slider: HSlider = %ElectricScaleYSlider
@onready var waves_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/WavesShader").material
@onready var blue_warp_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/BlueWarpShader").material
@onready var comic_dots1_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/ComicDotsBlueVert").material
@onready var comic_dots2_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/ComicDotsBlueHor").material
@onready var electric_shader_material: ShaderMaterial = get_tree().root.get_node("Main/DesktopEnv/ShaderBackgroundsContainer/ElectricShader").material


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
		electric_button.button_pressed = Events.is_desktop_background_visible("Electric")
		electric_bg_color_picker.color = electric_shader_material.get_shader_parameter("background_color")
		electric_line_color_picker.color = electric_shader_material.get_shader_parameter("line_color")
		electric_freq_slider.value = electric_shader_material.get_shader_parameter("line_freq")
		electric_height_slider.value = electric_shader_material.get_shader_parameter("height")
		electric_speed_slider.value = electric_shader_material.get_shader_parameter("speed")
		var electric_scale: Vector2 = electric_shader_material.get_shader_parameter("scale")
		electric_scale_x_slider.value = electric_scale.x
		electric_scale_y_slider.value = electric_scale.y

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
        PlayerManager.set_shader_param("Waves", "bottom_color", color)

func _on_top_color_picker_color_changed(color: Color) -> void:
        waves_shader_material.set_shader_parameter("top_color", color)
        PlayerManager.set_shader_param("Waves", "top_color", color)

func _on_wave_amp_slider_value_changed(value: float) -> void:
                waves_shader_material.set_shader_parameter("wave_amp", value)
                PlayerManager.set_shader_param("Waves", "wave_amp", value)

func _on_wave_size_slider_value_changed(value: float) -> void:
                waves_shader_material.set_shader_parameter("wave_size", value)
                PlayerManager.set_shader_param("Waves", "wave_size", value)

func _on_wave_time_mul_slider_value_changed(value: float) -> void:
                waves_shader_material.set_shader_parameter("wave_time_mul", value)
                PlayerManager.set_shader_param("Waves", "wave_time_mul", value)

func _on_total_phases_slider_value_changed(value: float) -> void:
                waves_shader_material.set_shader_parameter("total_phases", value)
                PlayerManager.set_shader_param("Waves", "total_phases", value)

func _on_blue_warp_stretch_slider_value_changed(value: float) -> void:
                blue_warp_shader_material.set_shader_parameter("stretch", value)
                PlayerManager.set_shader_param("BlueWarp", "stretch", value)

func _on_blue_warp_thing1_slider_value_changed(value: float) -> void:
                blue_warp_shader_material.set_shader_parameter("thing1", value)
                PlayerManager.set_shader_param("BlueWarp", "thing1", value)

func _on_blue_warp_thing2_slider_value_changed(value: float) -> void:
                blue_warp_shader_material.set_shader_parameter("thing2", value)
                PlayerManager.set_shader_param("BlueWarp", "thing2", value)

func _on_blue_warp_thing3_slider_value_changed(value: float) -> void:
                blue_warp_shader_material.set_shader_parameter("thing3", value)
                PlayerManager.set_shader_param("BlueWarp", "thing3", value)

func _on_blue_warp_speed_slider_value_changed(value: float) -> void:
                blue_warp_shader_material.set_shader_parameter("speed", value)
                PlayerManager.set_shader_param("BlueWarp", "speed", value)

func _on_comic_dots_color_picker_color_changed(color: Color) -> void:
                comic_dots1_shader_material.set_shader_parameter("circle_color", color)
                comic_dots2_shader_material.set_shader_parameter("circle_color", color)
                PlayerManager.set_shader_param("ComicDots", "circle_color", color)

func _on_comic_dots_multiplier_slider_value_changed(value: float) -> void:
                comic_dots1_shader_material.set_shader_parameter("circle_multiplier", value)
                comic_dots2_shader_material.set_shader_parameter("circle_multiplier", value)
                PlayerManager.set_shader_param("ComicDots", "circle_multiplier", value)

func _on_comic_dots_speed_slider_value_changed(value: float) -> void:
                comic_dots1_shader_material.set_shader_parameter("speed", value)
                comic_dots2_shader_material.set_shader_parameter("speed", value)
                PlayerManager.set_shader_param("ComicDots", "speed", value)

func _on_electric_button_toggled(toggled_on: bool) -> void:
		Events.set_desktop_background_visible("Electric", toggled_on)

func _on_electric_bg_color_picker_color_changed(color: Color) -> void:
                electric_shader_material.set_shader_parameter("background_color", color)
                PlayerManager.set_shader_param("Electric", "background_color", color)

func _on_electric_line_color_picker_color_changed(color: Color) -> void:
                electric_shader_material.set_shader_parameter("line_color", color)
                PlayerManager.set_shader_param("Electric", "line_color", color)

func _on_electric_freq_slider_value_changed(value: float) -> void:
                electric_shader_material.set_shader_parameter("line_freq", value)
                PlayerManager.set_shader_param("Electric", "line_freq", value)

func _on_electric_height_slider_value_changed(value: float) -> void:
                electric_shader_material.set_shader_parameter("height", value)
                PlayerManager.set_shader_param("Electric", "height", value)

func _on_electric_speed_slider_value_changed(value: float) -> void:
                electric_shader_material.set_shader_parameter("speed", value)
                PlayerManager.set_shader_param("Electric", "speed", value)

func _on_electric_scale_x_slider_value_changed(value: float) -> void:
                var scale: Vector2 = electric_shader_material.get_shader_parameter("scale")
                scale.x = value
                electric_shader_material.set_shader_parameter("scale", scale)
                PlayerManager.set_shader_param("Electric", "scale_x", value)

func _on_electric_scale_y_slider_value_changed(value: float) -> void:
                var scale: Vector2 = electric_shader_material.get_shader_parameter("scale")
                scale.y = value
                electric_shader_material.set_shader_parameter("scale", scale)
                PlayerManager.set_shader_param("Electric", "scale_y", value)

func _on_waves_reset_button_pressed() -> void:
        PlayerManager.reset_shader("Waves")
        var d = PlayerManager.DEFAULT_BACKGROUND_SHADERS["Waves"]
        var bottom = PlayerManager.dict_to_color(d["bottom_color"])
        var top = PlayerManager.dict_to_color(d["top_color"])
        waves_shader_material.set_shader_parameter("bottom_color", bottom)
        waves_shader_material.set_shader_parameter("top_color", top)
        waves_shader_material.set_shader_parameter("wave_amp", d["wave_amp"])
        waves_shader_material.set_shader_parameter("wave_size", d["wave_size"])
        waves_shader_material.set_shader_parameter("wave_time_mul", d["wave_time_mul"])
        waves_shader_material.set_shader_parameter("total_phases", d["total_phases"])
        bottom_color_picker.color = bottom
        top_color_picker.color = top
        wave_amp_slider.value = d["wave_amp"]
        wave_size_slider.value = d["wave_size"]
        wave_time_mul_slider.value = d["wave_time_mul"]
        total_phases_slider.value = d["total_phases"]

func _on_blue_warp_reset_button_pressed() -> void:
        PlayerManager.reset_shader("BlueWarp")
        var d = PlayerManager.DEFAULT_BACKGROUND_SHADERS["BlueWarp"]
        blue_warp_shader_material.set_shader_parameter("stretch", d["stretch"])
        blue_warp_shader_material.set_shader_parameter("thing1", d["thing1"])
        blue_warp_shader_material.set_shader_parameter("thing2", d["thing2"])
        blue_warp_shader_material.set_shader_parameter("thing3", d["thing3"])
        blue_warp_shader_material.set_shader_parameter("speed", d["speed"])
        blue_warp_stretch_slider.value = d["stretch"]
        blue_warp_thing1_slider.value = d["thing1"]
        blue_warp_thing2_slider.value = d["thing2"]
        blue_warp_thing3_slider.value = d["thing3"]
        blue_warp_speed_slider.value = d["speed"]

func _on_comic_dots_reset_button_pressed() -> void:
        PlayerManager.reset_shader("ComicDots")
        var d = PlayerManager.DEFAULT_BACKGROUND_SHADERS["ComicDots"]
        var color = PlayerManager.dict_to_color(d["circle_color"])
        comic_dots1_shader_material.set_shader_parameter("circle_color", color)
        comic_dots2_shader_material.set_shader_parameter("circle_color", color)
        comic_dots1_shader_material.set_shader_parameter("circle_multiplier", d["circle_multiplier"])
        comic_dots2_shader_material.set_shader_parameter("circle_multiplier", d["circle_multiplier"])
        comic_dots1_shader_material.set_shader_parameter("speed", d["speed"])
        comic_dots2_shader_material.set_shader_parameter("speed", d["speed"])
        comic_dots_color_picker.color = color
        comic_dots_multiplier_slider.value = d["circle_multiplier"]
        comic_dots_speed_slider.value = d["speed"]

func _on_electric_reset_button_pressed() -> void:
        PlayerManager.reset_shader("Electric")
        var d = PlayerManager.DEFAULT_BACKGROUND_SHADERS["Electric"]
        var bg = PlayerManager.dict_to_color(d["background_color"])
        var line = PlayerManager.dict_to_color(d["line_color"])
        electric_shader_material.set_shader_parameter("background_color", bg)
        electric_shader_material.set_shader_parameter("line_color", line)
        electric_shader_material.set_shader_parameter("line_freq", d["line_freq"])
        electric_shader_material.set_shader_parameter("height", d["height"])
        electric_shader_material.set_shader_parameter("speed", d["speed"])
        electric_shader_material.set_shader_parameter("scale", Vector2(d["scale_x"], d["scale_y"]))
        electric_bg_color_picker.color = bg
        electric_line_color_picker.color = line
        electric_freq_slider.value = d["line_freq"]
        electric_height_slider.value = d["height"]
        electric_speed_slider.value = d["speed"]
        electric_scale_x_slider.value = d["scale_x"]
        electric_scale_y_slider.value = d["scale_y"]

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
