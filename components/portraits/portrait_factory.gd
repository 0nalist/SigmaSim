extends Node
class_name PortraitFactory

static var _manifest: Dictionary = {}

static var PALETTES := {
    "Skin": [
        Color("3a2f1b"),
        Color("4c342a"),
        Color("6b4f33"),
        Color("8d6b5a"),
        Color("a6785b"),
        Color("c09786")
    ],
    "Hair": [
        Color("1b1b1b"),
        Color("2e1e16"),
        Color("4a2a1f"),
        Color("5b3b2e"),
        Color("673b2f"),
        Color("7c4b3a")
    ],
    "Eyes": [
        Color("3b2f23"),
        Color("4a3f2d"),
        Color("596552"),
        Color("46533a"),
        Color("3e403b"),
        Color("2e312d")
    ],
    "Shirt": [
        Color("556b2f"),
        Color("2f4f4f"),
        Color("333333"),
        Color("1f2a44"),
        Color("5c4033"),
        Color("4b5320")
    ]
}

static func djb2(s: String) -> int:
    var hash: int = 5381
    for i in s.length():
        hash = ((hash << 5) + hash) + int(s.unicode_at(i))
    return abs(hash)

static func rng_from_seed(seed: int) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    return rng

static func load_manifest() -> Dictionary:
    if _manifest.is_empty():
        var text := FileAccess.get_file_as_string("res://components/portraits/manifest.json")
        var data = JSON.parse_string(text)
        if typeof(data) == TYPE_DICTIONARY:
            _manifest = data
        else:
            _manifest = {}
    return _manifest

static func get_layers_order() -> Array[String]:
    var manifest := load_manifest()
    return manifest.get("order", [])

static func get_layer_info(layer: String) -> Dictionary:
    var manifest := load_manifest()
    var layers: Dictionary = manifest.get("layers", {})
    return layers.get(layer, {})

static func get_texture_for(layer: String, index: int) -> Texture2D:
    var info := get_layer_info(layer)
    var path: String = info.get("path", "")
    var prefix: String = info.get("prefix", "")
    var tex_path := path + prefix + str(index) + ".png"
    return load(tex_path)

static func random_palette_color(layer: String, rng: RandomNumberGenerator) -> Color:
    var info := get_layer_info(layer)
    var palette_name: String = info.get("palette", "")
    var colors: Array = PALETTES.get(palette_name, [])
    if colors.is_empty():
        return Color.WHITE
    var idx := rng.randi_range(0, colors.size() - 1)
    return colors[idx]

static func pick_index(layer: String, rng: RandomNumberGenerator) -> int:
    var info := get_layer_info(layer)
    var count: int = int(info.get("count", 1))
    return rng.randi_range(1, count)

static func generate_config_for_name(name: String) -> PortraitConfig:
    var seed := djb2(name)
    var rng := rng_from_seed(seed)
    var indices: Dictionary = {}
    var colors: Dictionary = {}
    for layer in get_layers_order():
        var idx := pick_index(layer, rng)
        indices[layer] = idx
        colors[layer] = random_palette_color(layer, rng)
    var cfg := PortraitConfig.new()
    cfg.name = name
    cfg.indices = indices
    cfg.colors = colors
    cfg.seed = seed
    return cfg

static func apply_config_to_view(config: PortraitConfig, view: PortraitView) -> void:
    for layer in get_layers_order():
        var idx: int = config.indices.get(layer, 1)
        var tex := get_texture_for(layer, idx)
        view.set_layer_texture(layer, tex)
        var col: Color = config.colors.get(layer, Color.WHITE)
        view.set_layer_color(layer, col)

static func export_view_to_png(view: PortraitView, out_path: String) -> bool:
    var viewport := Viewport.new()
    viewport.disable_3d = true
    viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
    viewport.size = view.size
    var inst := view.duplicate()
    viewport.add_child(inst)
    viewport.render_target_update_mode = Viewport.UPDATE_ONCE
    var img := viewport.get_texture().get_image()
    return img.save_png(out_path) == OK
