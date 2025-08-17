class_name PortraitCreator
extends Control

signal applied(config: PortraitConfig)

const PortraitFactory = preload("res://resources/portraits/portrait_factory.gd")

var config: PortraitConfig = PortraitConfig.new()
var layer_controls: Dictionary = {}
var hair_color_sync := true

@onready var preview: PortraitView = %Preview
@onready var layers_container: HBoxContainer = %Layers
@onready var name_edit: LineEdit = %NameEdit
@onready var generate_button: Button = %Generate
@onready var randomize_button: Button = %Randomize
@onready var apply_button: Button = %Apply


func _ready() -> void:
	_setup_layers()
	_sync_ui_with_config()
	name_edit.text_changed.connect(_on_name_changed)
	name_edit.text_submitted.connect(_on_name_submitted)
	generate_button.pressed.connect(_on_generate_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	preview.apply_config(config)


func _setup_layers() -> void:
	var hair_back_col: VBoxContainer = null
	for layer in PortraitCache.layers_order():
		var info := PortraitCache.layer_info(layer)
		if layer == "face":
			config.indices[layer] = 1
		else:
			config.indices[layer] = 0
		config.colors[layer] = Color.WHITE
		var col := VBoxContainer.new()
		col.name = layer
		var label := Label.new()
		label.text = "Hair2" if layer == "hair_back" else layer.capitalize()
		col.add_child(label)
		var index_btn := OptionButton.new()
		index_btn.name = "Index"
		var tex_arr: Array = info.get("textures", [])
		if layer != "face":
			index_btn.add_item("0", 0)
		for i in range(tex_arr.size()):
			index_btn.add_item(str(i + 1), i + 1)
		index_btn.item_selected.connect(_on_index_changed.bind(layer))
		col.add_child(index_btn)
		var color_btn := ColorPickerButton.new()
		color_btn.name = "Color"
		color_btn.custom_minimum_size = Vector2(15, 15)
		color_btn.color_changed.connect(_on_color_changed.bind(layer))
		col.add_child(color_btn)
		if layer == "hair" or layer == "hair_back":
			var sync_chk := CheckBox.new()
			sync_chk.name = "Sync"
			sync_chk.text = "Sync"
			sync_chk.add_theme_font_size_override("font_size", 14)
			sync_chk.button_pressed = hair_color_sync
			sync_chk.toggled.connect(_on_hair_sync_toggled.bind(layer))
			col.add_child(sync_chk)
			layer_controls[layer] = {"index": index_btn, "color": color_btn, "sync": sync_chk}
		else:
			layer_controls[layer] = {"index": index_btn, "color": color_btn}
		if layer == "hair_back":
			hair_back_col = col
		else:
			layers_container.add_child(col)
	if hair_back_col != null:
		layers_container.add_child(hair_back_col)


func _on_index_changed(idx: int, layer: String) -> void:
	if layer == "face":
		config.indices[layer] = idx + 1
	else:
		config.indices[layer] = idx
	preview.apply_config(config)


func _on_color_changed(color: Color, layer: String) -> void:
	if hair_color_sync and (layer == "hair" or layer == "hair_back"):
		config.colors["hair"] = color
		config.colors["hair_back"] = color
		var other := "hair_back" if layer == "hair" else "hair"
		var btns = layer_controls.get(other, {})
		if btns.has("color") and btns["color"] is ColorPickerButton:
			btns["color"].color = color
	else:
		config.colors[layer] = color
	preview.apply_config(config)


func _on_hair_sync_toggled(pressed: bool, layer: String) -> void:
	hair_color_sync = pressed
	for l in ["hair", "hair_back"]:
		var btns = layer_controls.get(l, {})
		if btns.has("sync") and btns["sync"] is CheckBox:
			var cbx: CheckBox = btns["sync"]
			if cbx.button_pressed != pressed:
				cbx.button_pressed = pressed
	if pressed:
		var other := "hair_back" if layer == "hair" else "hair"
		var col = config.colors.get(other, Color.WHITE)
		config.colors["hair"] = col
		config.colors["hair_back"] = col
		for l in ["hair", "hair_back"]:
			if layer_controls.has(l) and layer_controls[l].has("color"):
				var cb: ColorPickerButton = layer_controls[l]["color"]
				cb.color = col
	preview.apply_config(config)


func _on_name_changed(new_text: String) -> void:
	config.name = new_text


func _on_name_submitted(_text: String) -> void:
	_on_generate_pressed()


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
	hair_color_sync = config.colors.get("hair") == config.colors.get("hair_back")
	for layer in PortraitCache.layers_order():
		var btns = layer_controls.get(layer, {})
		if btns.has("index") and btns["index"] is OptionButton:
			var ob: OptionButton = btns["index"]
			var idx: int
			if layer == "face":
				idx = config.indices.get(layer, 1) - 1
				if idx < 0 or idx >= ob.item_count:
					idx = 0
					config.indices[layer] = 1
			else:
				idx = config.indices.get(layer, 0)
				if idx < 0 or idx >= ob.item_count:
					idx = 0
					config.indices[layer] = idx
			ob.select(idx)
		var col = config.colors.get(layer, Color.WHITE)
		if hair_color_sync and layer == "hair_back":
			col = config.colors.get("hair", Color.WHITE)
		if btns.has("color") and btns["color"] is ColorPickerButton:
			btns["color"].color = col
		if (
			(layer == "hair" or layer == "hair_back")
			and btns.has("sync")
			and btns["sync"] is CheckBox
		):
			btns["sync"].button_pressed = hair_color_sync
