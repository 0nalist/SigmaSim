extends Resource
class_name PortraitConfig

@export var name: String = ""
@export var indices: Dictionary = {}
@export var colors: Dictionary = {}
@export var seed: int = 0

func to_dict() -> Dictionary:
    var data: Dictionary = {
        "name": name,
        "indices": indices,
        "colors": {},
        "seed": seed
    }
    for k in colors.keys():
        data["colors"][k] = colors[k].to_html()
    return data

static func from_dict(d: Dictionary) -> PortraitConfig:
    var cfg := PortraitConfig.new()
    cfg.name = d.get("name", "")
    cfg.indices = d.get("indices", {})
    var cols: Dictionary = {}
    for k in d.get("colors", {}).keys():
        cols[k] = Color(d["colors"][k])
    cfg.colors = cols
    cfg.seed = d.get("seed", 0)
    return cfg
