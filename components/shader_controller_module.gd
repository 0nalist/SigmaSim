extends PanelContainer
class_name ShaderControllerModule

@export var shader_name: String
@export var shader_node_paths: Array[String] = []
@export var slider_nodes: Array[NodePath] = []
@export var slider_params: Array[StringName] = []
@export var color_picker_nodes: Array[NodePath] = []
@export var color_picker_params: Array[StringName] = []
@export var toggle_button_path: NodePath
@export var reset_button_path: NodePath
@export var collect_warp_shaders: bool = false
@export var flat_color_picker_path: NodePath
@export var flat_color_toggle_path: NodePath
@export var flat_color_rect_path: NodePath

var shader_materials: Array[ShaderMaterial] = []
var flat_color_rect: ColorRect

func _ready() -> void:
	if collect_warp_shaders:
		_refresh_warp_shader_materials()
		get_tree().node_added.connect(_on_node_added)
	else:
		for p in shader_node_paths:
			var n = get_tree().root.get_node_or_null(p)
			if n and n is CanvasItem:
				var mat = n.material
				if mat is ShaderMaterial:
					shader_materials.append(mat)
	for i in range(slider_nodes.size()):
		var node = get_node_or_null(slider_nodes[i])
		if node and node is HSlider:
			var param = slider_params[i]
			node.value = _get_param(param)
			var callable = _on_slider_changed.bind(param)
			if not node.value_changed.is_connected(callable):
				node.value_changed.connect(callable)
	for i in range(color_picker_nodes.size()):
		var node = get_node_or_null(color_picker_nodes[i])
		if node and node is ColorPickerButton:
			var param = color_picker_params[i]
			node.color = _get_param(param)
			var callable = _on_color_changed.bind(param)
			if not node.color_changed.is_connected(callable):
				node.color_changed.connect(callable)
		if flat_color_rect_path != NodePath():
				flat_color_rect = get_tree().root.get_node_or_null(flat_color_rect_path)
		if flat_color_picker_path != NodePath():
				var picker = get_node_or_null(flat_color_picker_path)
				if picker and picker is ColorPickerButton:
						var color = PlayerManager.get_shader_param(shader_name, "flat_color", Color(0, 0, 0.2))
						picker.color = color
						if flat_color_rect:
								flat_color_rect.color = color
						if not picker.color_changed.is_connected(_on_flat_color_changed):
								picker.color_changed.connect(_on_flat_color_changed)
		if flat_color_toggle_path != NodePath():
				var toggle = get_node_or_null(flat_color_toggle_path)
				if toggle and toggle is CheckButton:
						var visible = PlayerManager.get_shader_param(shader_name, "flat_visible", true)
						toggle.button_pressed = visible
						if flat_color_rect:
								flat_color_rect.visible = visible and Events.is_desktop_background_visible(shader_name)
						if not toggle.toggled.is_connected(_on_flat_toggled):
								toggle.toggled.connect(_on_flat_toggled)
						if not Events.desktop_background_toggled.is_connected(_on_background_toggled):
								Events.desktop_background_toggled.connect(_on_background_toggled)
		if toggle_button_path != NodePath():
				var button = get_node_or_null(toggle_button_path)
				if button and button is CheckButton:
						button.button_pressed = Events.is_desktop_background_visible(shader_name)
						if not button.toggled.is_connected(_on_toggled):
								button.toggled.connect(_on_toggled)
	if reset_button_path != NodePath():
		var reset = get_node_or_null(reset_button_path)
		if reset and reset is Button:
			if not reset.pressed.is_connected(_on_reset_pressed):
				reset.pressed.connect(_on_reset_pressed)

func _refresh_warp_shader_materials() -> void:
	shader_materials.clear()
	_collect_warp_shader_materials(get_tree().root)

func _collect_warp_shader_materials(n: Node) -> void:
	if n is CanvasItem:
		var mat = n.material
		if mat is ShaderMaterial and mat.shader and mat.shader.resource_path.ends_with("warp_shader.gdshader"):
			if mat not in shader_materials:
				shader_materials.append(mat)
	for c in n.get_children():
		_collect_warp_shader_materials(c)

func _on_node_added(n: Node) -> void:
	_collect_warp_shader_materials(n)

func _on_slider_changed(value: float, param: StringName) -> void:
	_set_param(param, value)

func _on_color_changed(color: Color, param: StringName) -> void:
	_set_param(param, color)

func _on_flat_color_changed(color: Color) -> void:
	if flat_color_rect:
		flat_color_rect.color = color
	PlayerManager.set_shader_param(shader_name, "flat_color", color)

func _on_flat_toggled(toggled_on: bool) -> void:
		if flat_color_rect:
				flat_color_rect.visible = toggled_on and Events.is_desktop_background_visible(shader_name)
		PlayerManager.set_shader_param(shader_name, "flat_visible", toggled_on)

func _on_toggled(toggled_on: bool) -> void:
	Events.set_desktop_background_visible(shader_name, toggled_on)

func _on_background_toggled(name: String, visible: bool) -> void:
		if name == shader_name and flat_color_rect:
				var toggle: CheckButton = null
				if flat_color_toggle_path != NodePath():
						toggle = get_node_or_null(flat_color_toggle_path)
				var toggled_on: bool = toggle.button_pressed if toggle else false
				flat_color_rect.visible = visible and toggled_on

func _get_param(param: StringName):
	if shader_materials.is_empty():
		return 0
	if param == StringName():
		return 0
	if param == "scale_x" or param == "scale_y":
		var scale: Vector2 = shader_materials[0].get_shader_parameter("scale")
		return scale.x if param == "scale_x" else scale.y
	var result = shader_materials[0].get_shader_parameter(param)
	return result if result != null else 0

func _set_param(param: StringName, value) -> void:
	if param == "scale_x" or param == "scale_y":
		for mat in shader_materials:
			var scale: Vector2 = mat.get_shader_parameter("scale")
			if param == "scale_x":
				scale.x = value
			else:
				scale.y = value
			mat.set_shader_parameter("scale", scale)
	else:
		for mat in shader_materials:
			mat.set_shader_parameter(param, value)
	PlayerManager.set_shader_param(shader_name, param, value)

func _on_reset_pressed() -> void:
	PlayerManager.reset_shader(shader_name)
	var d = PlayerManager.DEFAULT_BACKGROUND_SHADERS[shader_name]
	for i in range(slider_nodes.size()):
		var node = get_node_or_null(slider_nodes[i])
		if node and node is HSlider:
			var param = slider_params[i]
			var val = d[param]
			node.value = val
			_set_param(param, val)
	for i in range(color_picker_nodes.size()):
		var node = get_node_or_null(color_picker_nodes[i])
		if node and node is ColorPickerButton:
			var param = color_picker_params[i]
			var val = PlayerManager.dict_to_color(d[param])
			node.color = val
			_set_param(param, val)
	if flat_color_picker_path != NodePath():
		var picker = get_node_or_null(flat_color_picker_path)
		if picker and picker is ColorPickerButton:
			var val = PlayerManager.dict_to_color(d.get("flat_color", {"r": 0.0, "g": 0.0, "b": 0.2, "a": 1.0}))
			picker.color = val
			_on_flat_color_changed(val)
	if flat_color_toggle_path != NodePath():
		var toggle = get_node_or_null(flat_color_toggle_path)
		if toggle and toggle is CheckButton:
			var vis = d.get("flat_visible", false)
			toggle.button_pressed = vis
			_on_flat_toggled(vis)
