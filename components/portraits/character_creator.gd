extends Control
class_name CharacterCreator

signal applied(config: PortraitConfig)

var index_selectors: Dictionary = {}
var color_selectors: Dictionary = {}
var color_options: Dictionary = {}

@onready var name_edit: LineEdit = $VBox/NameRow/LineEdit
@onready var preview: PortraitView = $VBox/PortraitView
@onready var layer_container: VBoxContainer = $VBox/LayerControls
@onready var randomize_button: Button = $VBox/ButtonRow/Randomize
@onready var seed_button: Button = $VBox/ButtonRow/SeedFromName
@onready var save_button: Button = $VBox/ButtonRow/Save
@onready var apply_button: Button = $VBox/ButtonRow/Apply

func _ready():
    _build_controls()
    randomize_button.pressed.connect(randomize)
    seed_button.pressed.connect(func(): seed_from_name(name_edit.text))
    save_button.pressed.connect(func(): save_png("user://portraits/%s.png" % name_edit.text))
    apply_button.pressed.connect(apply_and_emit)

func _build_controls() -> void:
    for layer in PortraitFactory.get_layers_order():
        var h := HBoxContainer.new()
        layer_container.add_child(h)
        var label := Label.new()
        label.text = layer
        h.add_child(label)

        var idx_opt := OptionButton.new()
        var info := PortraitFactory.get_layer_info(layer)
        var count: int = info.get("count", 1)
        for i in count:
            idx_opt.add_item(str(i + 1), i + 1)
        idx_opt.item_selected.connect(_on_index_changed.bind(layer))
        h.add_child(idx_opt)
        index_selectors[layer] = idx_opt

        var color_opt := OptionButton.new()
        var palette_name: String = info.get("palette", "")
        var colors: Array = PortraitFactory.PALETTES.get(palette_name, [])
        color_options[layer] = colors
        for i in colors.size():
            color_opt.add_item(str(i + 1), i)
        color_opt.item_selected.connect(_on_color_changed.bind(layer))
        h.add_child(color_opt)
        color_selectors[layer] = color_opt

func _on_index_changed(index: int, layer: String) -> void:
    _update_layer(layer)

func _on_color_changed(index: int, layer: String) -> void:
    _update_layer(layer)

func _update_layer(layer: String) -> void:
    var idx: int = index_selectors[layer].get_selected_id()
    var tex := PortraitFactory.get_texture_for(layer, idx)
    preview.set_layer_texture(layer, tex)
    var color_idx: int = color_selectors[layer].get_selected_id()
    var cols: Array = color_options[layer]
    if cols.size() > color_idx:
        preview.set_layer_color(layer, cols[color_idx])

func seed_from_name(name: String) -> void:
    var cfg := PortraitFactory.generate_config_for_name(name)
    load_from_config(cfg)

func randomize() -> void:
    var rng := PortraitFactory.rng_from_seed(Time.get_unix_time_from_system())
    var indices: Dictionary = {}
    var colors: Dictionary = {}
    for layer in PortraitFactory.get_layers_order():
        indices[layer] = PortraitFactory.pick_index(layer, rng)
        colors[layer] = PortraitFactory.random_palette_color(layer, rng)
    var cfg := PortraitConfig.new()
    cfg.name = name_edit.text
    cfg.indices = indices
    cfg.colors = colors
    cfg.seed = rng.seed
    load_from_config(cfg)

func apply_and_emit() -> void:
    var cfg := gather_config()
    emit_signal("applied", cfg)

func save_png(path: String) -> void:
    var cfg := gather_config()
    PortraitFactory.apply_config_to_view(cfg, preview)
    PortraitFactory.export_view_to_png(preview, path)

func load_from_config(cfg: PortraitConfig) -> void:
    name_edit.text = cfg.name
    for layer in PortraitFactory.get_layers_order():
        var idx: int = cfg.indices.get(layer, 1)
        index_selectors[layer].select(idx - 1)
        var cols: Array = color_options[layer]
        var col: Color = cfg.colors.get(layer, Color.WHITE)
        var c_index := cols.find(col)
        if c_index == -1:
            c_index = 0
        color_selectors[layer].select(c_index)
    PortraitFactory.apply_config_to_view(cfg, preview)

func gather_config() -> PortraitConfig:
    var cfg := PortraitConfig.new()
    cfg.name = name_edit.text
    cfg.indices = {}
    cfg.colors = {}
    cfg.seed = PortraitFactory.djb2(cfg.name)
    for layer in PortraitFactory.get_layers_order():
        cfg.indices[layer] = index_selectors[layer].get_selected_id()
        var cols: Array = color_options[layer]
        var col_idx: int = color_selectors[layer].get_selected_id()
        cfg.colors[layer] = cols[col_idx]
    return cfg
