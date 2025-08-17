extends Control
class_name PortraitCreator

signal applied(config: PortraitConfig)

var config: PortraitConfig = PortraitConfig.new()
var layer_controls: Dictionary = {}

@onready var preview: PortraitView = %Preview
@onready var layers_container: VBoxContainer = %Layers
@onready var name_edit: LineEdit = %NameEdit
@onready var randomize_button: Button = %Randomize
@onready var apply_button: Button = %Apply

func _ready() -> void:
	_setup_layers()
	name_edit.text_changed.connect(_on_name_changed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	preview.apply_config(config)

func _setup_layers() -> void:
	for layer in PortraitCache.layers_order():
		var info := PortraitCache.layer_info(layer)
		config.indices[layer] = 0
		config.colors[layer] = Color.WHITE
		var row := HBoxContainer.new()
		row.name = layer
		var label := Label.new()
		label.text = layer.capitalize()
		row.add_child(label)
		var index_btn := OptionButton.new()
		index_btn.name = "Index"
		var tex_arr: Array = info.get("textures", [])
		for i in range(tex_arr.size()):
			index_btn.add_item(str(i + 1), i)
		index_btn.item_selected.connect(_on_index_changed.bind(layer))
		row.add_child(index_btn)
		var color_btn := OptionButton.new()
		color_btn.name = "Color"
		var colors_arr: Array = info.get("colors", [])
		for i in range(colors_arr.size()):
			var cstr = colors_arr[i]
			color_btn.add_item(cstr, i)
		color_btn.item_selected.connect(_on_color_changed.bind(layer))
		row.add_child(color_btn)
		layers_container.add_child(row)
		layer_controls[layer] = {"index": index_btn, "color": color_btn}

func _on_index_changed(layer: String, idx: int) -> void:
	config.indices[layer] = idx
	preview.apply_config(config)

func _on_color_changed(layer: String, idx: int) -> void:
	var info := PortraitCache.layer_info(layer)
	var colors_arr: Array = info.get("colors", [])
	if idx >= 0 and idx < colors_arr.size():
		config.colors[layer] = Color(colors_arr[idx])
	preview.apply_config(config)

func _on_name_changed(new_text: String) -> void:
	config.name = new_text

func _on_randomize_pressed() -> void:
	var rng := RandomNumberGenerator.new()
	config.seed = rng.randi()
	rng.seed = config.seed
	for layer in PortraitCache.layers_order():
		var info := PortraitCache.layer_info(layer)
		var tex_arr: Array = info.get("textures", [])
		var max_index = tex_arr.size()
		var idx = 0
		if max_index > 0:
			idx = rng.randi_range(0, max_index - 1)
		config.indices[layer] = idx
		var btns = layer_controls.get(layer, {})
		if btns.has("index") and btns["index"] is OptionButton:
			btns["index"].select(idx)
		var colors_arr: Array = info.get("colors", [])
		var color_idx = 0
		if colors_arr.size() > 0:
			color_idx = rng.randi_range(0, colors_arr.size() - 1)
			config.colors[layer] = Color(colors_arr[color_idx])
			if btns.has("color") and btns["color"] is OptionButton:
				btns["color"].select(color_idx)
	preview.apply_config(config)

func _on_apply_pressed() -> void:
	emit_signal("applied", config)
