extends Control

@onready var start_panel: StartPanelWindow = %StartPanel
@onready var taskbar: Control = %Taskbar
@onready var trash_window: Pane = %TrashWindow
@onready var start_button: Button = $TaskbarLayer/TaskbarWrapper/MarginContainer/TaskbarRow/StartButton

@onready var icons_layer: Control = self
const APP_SHORTCUT_SCENE: PackedScene = preload("res://components/desktop/app_shortcut.tscn")
const FOLDER_SHORTCUT_SCENE: PackedScene = preload("res://components/desktop/folder_shortcut.tscn")

@onready var background: TextureRect = %Background

@onready var blue_warp_shader_material: ShaderMaterial = %BlueWarpShader.material
@onready var blue_warp_flat_color_rect: ColorRect = %BlueWarpFlatColor
@onready var comic_dots1_shader_material: ShaderMaterial = %ComicDotsBlueVert.material
@onready var comic_dots2_shader_material: ShaderMaterial = %ComicDotsBlueHor.material
@onready var waves_shader_material: ShaderMaterial = %WavesShader.material
@onready var electric_shader_material: ShaderMaterial = %ElectricShader.material
@onready var flat_color_shader_material: ShaderMaterial = %FlatColorBackground.material



@export var background_texture: Texture = preload("res://assets/backgrounds/Bliss_(Windows_XP) (2).png")
@export var create_or_update_apps_folder: bool = true

func _ready() -> void:
	#SaveManager.save_to_slot(PlayerManager.get_slot_id())
	
	GameManager.in_game = true
	#hide_all_windows_and_panels()
	WindowManager.taskbar_container = taskbar
	WindowManager.start_panel = start_panel
	DesktopLayoutManager.items_loaded.connect(_on_items_loaded)
	DesktopLayoutManager.item_created.connect(_on_item_created)
	DesktopLayoutManager.item_deleted.connect(_on_item_deleted)
	
	call_deferred("_deferred_load_save")
	launch_startup_apps()
	print("Active slot_id:", SaveManager.current_slot_id)

func launch_startup_apps() -> void:
	#WindowManager.launch_app_by_name("BrokeRage")
	pass


func _deferred_load_save():
	SaveManager.load_from_slot(SaveManager.current_slot_id)
	_apply_shader_settings()
	_sync_warp_shaders()
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
	blue_warp_shader_material.set_shader_parameter("color_low", PlayerManager.get_shader_param("BlueWarp", "color_low", PlayerManager.dict_to_color(bw_def["color_low"])))
	blue_warp_shader_material.set_shader_parameter("color_mid", PlayerManager.get_shader_param("BlueWarp", "color_mid", PlayerManager.dict_to_color(bw_def["color_mid"])))
	blue_warp_shader_material.set_shader_parameter("color_high", PlayerManager.get_shader_param("BlueWarp", "color_high", PlayerManager.dict_to_color(bw_def["color_high"])))
	var flat_color = PlayerManager.get_shader_param("BlueWarp", "flat_color", PlayerManager.dict_to_color(bw_def.get("flat_color", {"r": 0.0, "g": 0.0, "b": 0.2, "a": 1.0})))
	var flat_visible = PlayerManager.get_shader_param("BlueWarp", "flat_visible", bw_def.get("flat_visible", false))
	blue_warp_flat_color_rect.color = flat_color
	blue_warp_flat_color_rect.visible = flat_visible and Events.is_desktop_background_visible("BlueWarp")

	var cd1_def = defaults["ComicDots1"]
	var cd1_color = PlayerManager.get_shader_param("ComicDots1", "circle_color", PlayerManager.dict_to_color(cd1_def["circle_color"]))
	var cd1_mult = PlayerManager.get_shader_param("ComicDots1", "circle_multiplier", cd1_def["circle_multiplier"])
	var cd1_speed = PlayerManager.get_shader_param("ComicDots1", "speed", cd1_def["speed"])
	comic_dots1_shader_material.set_shader_parameter("circle_color", cd1_color)
	comic_dots1_shader_material.set_shader_parameter("circle_multiplier", cd1_mult)
	comic_dots1_shader_material.set_shader_parameter("speed", cd1_speed)

	var cd2_def = defaults["ComicDots2"]
	var cd2_color = PlayerManager.get_shader_param("ComicDots2", "circle_color", PlayerManager.dict_to_color(cd2_def["circle_color"]))
	var cd2_mult = PlayerManager.get_shader_param("ComicDots2", "circle_multiplier", cd2_def["circle_multiplier"])
	var cd2_speed = PlayerManager.get_shader_param("ComicDots2", "speed", cd2_def["speed"])
	comic_dots2_shader_material.set_shader_parameter("circle_color", cd2_color)
	comic_dots2_shader_material.set_shader_parameter("circle_multiplier", cd2_mult)
	comic_dots2_shader_material.set_shader_parameter("speed", cd2_speed)

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

	var flat_def = defaults["FlatColor"]
	var flat_col = PlayerManager.get_shader_param("FlatColor", "color", PlayerManager.dict_to_color(flat_def["color"]))
	flat_color_shader_material.set_shader_parameter("color", flat_col)


func hide_all_windows_and_panels() -> void:
	start_panel.hide()
	trash_window.hide()
	# All apps should now open dynamically via StartPanel

# ----------------------------- #
# Taskbar / Start Menu Buttons #
# ----------------------------- #

func _on_start_button_pressed() -> void:
		var button_pos: Vector2 = start_button.global_position
		var panel_height: float = start_panel.size.y * start_panel.scale.y
		start_panel.global_position = button_pos - Vector2(0, panel_height)
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

func _on_items_loaded() -> void:
	for child in icons_layer.get_children():
		if child is AppShortcut or child is FolderShortcut:
			child.queue_free()

	var items: Array = DesktopLayoutManager.get_children_of(0)

	for entry in items:
		_spawn_item(entry)

	if create_or_update_apps_folder:
		_create_or_update_apps_folder()


func _on_item_created(item_id: int, data: Dictionary) -> void:
	if int(data.get("parent_id", 0)) != 0:
		return
	_spawn_item(data)


func _on_item_deleted(item_id: int) -> void:
	for child in icons_layer.get_children():
		if (child is AppShortcut or child is FolderShortcut) and child.item_id == item_id:
			child.queue_free()
			break


func _spawn_item(data: Dictionary) -> void:
	var scene: PackedScene
	if data.get("type", "") == "app":
		scene = APP_SHORTCUT_SCENE
	else:
		scene = FOLDER_SHORTCUT_SCENE

	var node: Control = scene.instantiate()
	node.item_id = data.get("id", 0)
	node.title = data.get("title", "")

	if data.get("type", "") == "app" and data.has("app_name"):
		(node as AppShortcut).app_name = data.get("app_name", "")

	var icon_path: String = data.get("icon_path", "")
	if icon_path != "":
		var tex: Resource = load(icon_path)
		if tex is Texture2D:
			node.icon = tex

	icons_layer.add_child(node)

	var pos: Vector2 = data.get("desktop_position", Vector2.ZERO)
	node.global_position = pos



func _create_or_update_apps_folder() -> void:
	print("creating desktop apps folder")
	var center: Vector2 = get_viewport_rect().size / 2
	var folder_id: int = 0
	var root_items: Array = DesktopLayoutManager.get_children_of(0)
	for entry in root_items:
			if entry.get("type", "") == "folder" and entry.get("title", "") == "Apps":
					folder_id = int(entry.get("id", 0))
					DesktopLayoutManager.move_item(folder_id, center)
					# Update visible icon position if it was already spawned
					for node in icons_layer.get_children():
							if node is FolderShortcut and node.item_id == folder_id:
									node.global_position = center
									break
					break
	if folder_id == 0:
			folder_id = DesktopLayoutManager.create_folder("Apps", "res://assets/logos/folder.png", center)
	var existing: Dictionary = {}
	for entry in DesktopLayoutManager.get_children_of(folder_id):
		if entry.get("type", "") == "app":
			existing[entry.get("app_name", "")] = true
	for app_name in WindowManager.app_registry.keys():
		if existing.has(app_name):
			continue
		var meta: Dictionary = _get_app_meta(app_name)
		DesktopLayoutManager.create_app_shortcut(app_name, meta.get("title", app_name), meta.get("icon_path", ""), Vector2.ZERO, folder_id)

func _get_app_meta(app_name: String) -> Dictionary:
	var scene: PackedScene = WindowManager.app_registry.get(app_name)
	var title: String = app_name
	var icon_path: String = ""
	if scene:
		var preview = scene.instantiate()
		if preview is Pane:
			title = preview.window_title
			if preview.window_icon:
				icon_path = preview.window_icon.resource_path
		preview.queue_free()
	return {"title": title, "icon_path": icon_path}

'''
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var ev: InputEventKey = event as InputEventKey
		if ev.keycode == KEY_SPACE:
			TraumaManager.hit_global(0.6)
		if ev.keycode == KEY_S and target_control != null:
			TraumaManager.hit_pane(target_control, 0.6)
			'''

func _sync_warp_shaders() -> void:
	_apply_warp_shader_params(get_tree().root)
	get_tree().node_added.connect(_on_warp_shader_node_added)

func _on_warp_shader_node_added(n: Node) -> void:
	_apply_warp_shader_params(n)

func _apply_warp_shader_params(n: Node) -> void:
	if n is CanvasItem:
		var mat = n.material
		if mat is ShaderMaterial and mat.shader:
			var path = mat.shader.resource_path
			if path.ends_with("warp_shader.gdshader") or path.ends_with("pink_warp.gdshader"):
				var stretch = blue_warp_shader_material.get_shader_parameter("stretch")
				var thing1 = blue_warp_shader_material.get_shader_parameter("thing1")
				var thing2 = blue_warp_shader_material.get_shader_parameter("thing2")
				var thing3 = blue_warp_shader_material.get_shader_parameter("thing3")
				var speed = blue_warp_shader_material.get_shader_parameter("speed")
				var scale = blue_warp_shader_material.get_shader_parameter("scale")
				mat.set_shader_parameter("stretch", stretch)
				mat.set_shader_parameter("thing1", thing1)
				mat.set_shader_parameter("thing2", thing2)
				mat.set_shader_parameter("thing3", thing3)
				mat.set_shader_parameter("speed", speed)
				mat.set_shader_parameter("scale", scale)
	for c in n.get_children():
		_apply_warp_shader_params(c)
