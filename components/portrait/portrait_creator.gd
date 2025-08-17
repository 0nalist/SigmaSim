extends Control
class_name PortraitCreator

signal applied(config: PortraitConfig)

var config: PortraitConfig = PortraitConfig.new()
var layer_controls: Dictionary = {}

@onready var preview: PortraitView = %Preview
@onready var layers_container: VBoxContainer = %Layers
@onready var name_edit: LineEdit = %NameEdit
@onready var generate_button: Button = %Generate
@onready var randomize_button: Button = %Randomize
@onready var apply_button: Button = %Apply

const PortraitFactory = preload("res://resources/portraits/portrait_factory.gd")


func _ready() -> void:
	_setup_layers()
	_sync_ui_with_config()
	name_edit.text_changed.connect(_on_name_changed)
	generate_button.pressed.connect(_on_generate_pressed)
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
		index_btn.add_item("0", 0)
		for i in range(tex_arr.size()):
				index_btn.add_item(str(i + 1), i + 1)
		index_btn.item_selected.connect(_on_index_changed.bind(layer))
		row.add_child(index_btn)
		var color_btn := ColorPickerButton.new()
		color_btn.name = "Color"
		color_btn.custom_minimum_size = Vector2(15, 0)
		color_btn.color_changed.connect(_on_color_changed.bind(layer))
		row.add_child(color_btn)
		layers_container.add_child(row)
		layer_controls[layer] = {"index": index_btn, "color": color_btn}


func _on_index_changed(idx: int, layer: String) -> void:
		config.indices[layer] = idx
		preview.apply_config(config)


func _on_color_changed(color: Color, layer: String) -> void:
	if layer == "hair" or layer == "hair_back":
		config.colors["hair"] = color
		config.colors["hair_back"] = color
		var other := "hair_back" if layer == "hair" else "hair"
		var btns = layer_controls.get(other, {})
		if btns.has("color") and btns["color"] is ColorPickerButton:
			btns["color"].color = color
	else:
			config.colors[layer] = color
	preview.apply_config(config)


func _on_name_changed(new_text: String) -> void:
	config.name = new_text


func _on_randomize_pressed() -> void:
	var rng := RandomNumberGenerator.new()
	config = PortraitFactory.generate_config_for_name(str(rng.randi()))
	config.name = name_edit.text
	_sync_ui_with_config()
	preview.apply_config(config)


func _on_generate_pressed() -> void:
	config = PortraitFactory.generate_config_for_name(name_edit.text)
	_sync_ui_with_config()
	preview.apply_config(config)


func _on_apply_pressed() -> void:
	emit_signal("applied", config)


func _sync_ui_with_config() -> void:
	for layer in PortraitCache.layers_order():
		var idx = config.indices.get(layer, 0)
		var btns = layer_controls.get(layer, {})
		if btns.has("index") and btns["index"] is OptionButton:
			var ob: OptionButton = btns["index"]
			if idx < 0 or idx >= ob.item_count:
				idx = 0
				config.indices[layer] = idx
			ob.select(idx)
		var col = config.colors.get(layer, Color.WHITE)
		if layer == "hair_back":
			col = config.colors.get("hair_back", config.colors.get("hair", Color.WHITE))
		if btns.has("color") and btns["color"] is ColorPickerButton:
			btns["color"].color = col
