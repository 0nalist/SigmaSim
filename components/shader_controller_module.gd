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

var shader_materials: Array[ShaderMaterial] = []

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
            node.value_changed.connect(_on_slider_changed.bind(param))
    for i in range(color_picker_nodes.size()):
        var node = get_node_or_null(color_picker_nodes[i])
        if node and node is ColorPickerButton:
            var param = color_picker_params[i]
            node.color = _get_param(param)
            node.color_changed.connect(_on_color_changed.bind(param))
    if toggle_button_path != NodePath():
        var button = get_node_or_null(toggle_button_path)
        if button and button is CheckButton:
            button.button_pressed = Events.is_desktop_background_visible(shader_name)
            button.toggled.connect(_on_toggled)
    if reset_button_path != NodePath():
        var reset = get_node_or_null(reset_button_path)
        if reset and reset is Button:
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

func _on_toggled(toggled_on: bool) -> void:
    Events.set_desktop_background_visible(shader_name, toggled_on)

func _get_param(param: StringName):
    if shader_materials.is_empty():
        return 0
    if param == "scale_x" or param == "scale_y":
        var scale: Vector2 = shader_materials[0].get_shader_parameter("scale")
        return scale.x if param == "scale_x" else scale.y
    return shader_materials[0].get_shader_parameter(param)

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
