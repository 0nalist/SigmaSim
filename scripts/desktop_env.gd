extends Control

@onready var start_panel: StartPanelWindow = %StartPanel
@onready var taskbar: Control = %Taskbar
@onready var trash_window: Pane = %TrashWindow
@onready var background: TextureRect = %Background

@onready var blue_warp_shader_material: ShaderMaterial = $ShaderBackgroundsContainer/BlueWarpShader.material
@onready var comic_dots1_shader_material: ShaderMaterial = $ShaderBackgroundsContainer/ComicDotsBlueVert.material
@onready var comic_dots2_shader_material: ShaderMaterial = $ShaderBackgroundsContainer/ComicDotsBlueHor.material
@onready var waves_shader_material: ShaderMaterial = $ShaderBackgroundsContainer/WavesShader.material
@onready var electric_shader_material: ShaderMaterial = $ShaderBackgroundsContainer/ElectricShader.material



@export var background_texture: Texture = preload("res://assets/backgrounds/Bliss_(Windows_XP) (2).png")

func _ready() -> void:
	#SaveManager.save_to_slot(PlayerManager.get_slot_id())
	
	GameManager.in_game = true
	#hide_all_windows_and_panels()
	WindowManager.taskbar_container = taskbar
	WindowManager.start_panel = start_panel
	
	call_deferred("_deferred_load_save")
	launch_startup_apps()
	print("Active slot_id:", SaveManager.current_slot_id)

func launch_startup_apps() -> void:
	#WindowManager.launch_app_by_name("BrokeRage")
	pass


func _deferred_load_save():
	SaveManager.load_from_slot(SaveManager.current_slot_id)
	_apply_shader_settings()
	var path = PlayerManager.user_data.get("background_path", "")
	if path != "":
		var tex = load(path)
		if tex is Texture2D:
			background.texture = tex
		else:
			print("❌ Couldn't load texture from path: ", path)
	else:
			background.texture = background_texture  # fallback

func _apply_shader_settings() -> void:
		var defaults = PlayerManager.DEFAULT_BACKGROUND_SHADERS

		var waves_def = defaults["Waves"]
		var bottom = PlayerManager.get_shader_param("Waves", "bottom_color", PlayerManager.dict_to_color(waves_def["bottom_color"]))
		var top = PlayerManager.get_shader_param("Waves", "top_color", PlayerManager.dict_to_color(waves_def["top_color"]))
		var wave_amp = PlayerManager.get_shader_param("Waves", "wave_amp", waves_def["wave_amp"])
		var wave_size = PlayerManager.get_shader_param("Waves", "wave_size", waves_def["wave_size"])
		var wave_time_mul = PlayerManager.get_shader_param("Waves", "wave_time_mul", waves_def["wave_time_mul"])
		var total_phases = PlayerManager.get_shader_param("Waves", "total_phases", waves_def["total_phases"])
		waves_shader_material.set_shader_parameter("bottom_color", bottom)
		waves_shader_material.set_shader_parameter("top_color", top)
		waves_shader_material.set_shader_parameter("wave_amp", wave_amp)
		waves_shader_material.set_shader_parameter("wave_size", wave_size)
		waves_shader_material.set_shader_parameter("wave_time_mul", wave_time_mul)
		waves_shader_material.set_shader_parameter("total_phases", total_phases)

		var bw_def = defaults["BlueWarp"]
		blue_warp_shader_material.set_shader_parameter("stretch", PlayerManager.get_shader_param("BlueWarp", "stretch", bw_def["stretch"]))
		blue_warp_shader_material.set_shader_parameter("thing1", PlayerManager.get_shader_param("BlueWarp", "thing1", bw_def["thing1"]))
		blue_warp_shader_material.set_shader_parameter("thing2", PlayerManager.get_shader_param("BlueWarp", "thing2", bw_def["thing2"]))
		blue_warp_shader_material.set_shader_parameter("thing3", PlayerManager.get_shader_param("BlueWarp", "thing3", bw_def["thing3"]))
		blue_warp_shader_material.set_shader_parameter("speed", PlayerManager.get_shader_param("BlueWarp", "speed", bw_def["speed"]))

		var cd_def = defaults["ComicDots"]
		var cd_color = PlayerManager.get_shader_param("ComicDots", "circle_color", PlayerManager.dict_to_color(cd_def["circle_color"]))
		var cd_mult = PlayerManager.get_shader_param("ComicDots", "circle_multiplier", cd_def["circle_multiplier"])
		var cd_speed = PlayerManager.get_shader_param("ComicDots", "speed", cd_def["speed"])
		comic_dots1_shader_material.set_shader_parameter("circle_color", cd_color)
		comic_dots2_shader_material.set_shader_parameter("circle_color", cd_color)
		comic_dots1_shader_material.set_shader_parameter("circle_multiplier", cd_mult)
		comic_dots2_shader_material.set_shader_parameter("circle_multiplier", cd_mult)
		comic_dots1_shader_material.set_shader_parameter("speed", cd_speed)
		comic_dots2_shader_material.set_shader_parameter("speed", cd_speed)

		var e_def = defaults["Electric"]
		var bg_color = PlayerManager.get_shader_param("Electric", "background_color", PlayerManager.dict_to_color(e_def["background_color"]))
		var line_color = PlayerManager.get_shader_param("Electric", "line_color", PlayerManager.dict_to_color(e_def["line_color"]))
		var line_freq = PlayerManager.get_shader_param("Electric", "line_freq", e_def["line_freq"])
		var height = PlayerManager.get_shader_param("Electric", "height", e_def["height"])
		var speed = PlayerManager.get_shader_param("Electric", "speed", e_def["speed"])
		var scale_x = PlayerManager.get_shader_param("Electric", "scale_x", e_def["scale_x"])
		var scale_y = PlayerManager.get_shader_param("Electric", "scale_y", e_def["scale_y"])
		electric_shader_material.set_shader_parameter("background_color", bg_color)
		electric_shader_material.set_shader_parameter("line_color", line_color)
		electric_shader_material.set_shader_parameter("line_freq", line_freq)
		electric_shader_material.set_shader_parameter("height", height)
		electric_shader_material.set_shader_parameter("speed", speed)
		electric_shader_material.set_shader_parameter("scale", Vector2(scale_x, scale_y))


func hide_all_windows_and_panels() -> void:
	start_panel.hide()
	trash_window.hide()
	# All apps should now open dynamically via StartPanel

# ----------------------------- #
# Taskbar / Start Menu Buttons #
# ----------------------------- #

func _on_start_button_pressed() -> void:
	start_panel.toggle_start_panel()

func _on_trash_button_pressed() -> void:
	open_trash_folder()

func open_trash_folder() -> void:
	trash_window.show()
	trash_window.grab_focus()


func _on_save_button_pressed() -> void:
	SaveManager.save_to_slot(SaveManager.current_slot_id)


func _on_load_button_pressed() -> void:
	SaveManager.load_from_slot(SaveManager.current_slot_id)
