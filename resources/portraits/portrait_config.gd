extends Resource
class_name PortraitConfig

@export var name: String = ""
@export var seed: int = 0
@export var indices: Dictionary = {}
@export var colors: Dictionary = {}

func to_dict() -> Dictionary:
	var d := {}
	d["name"] = name
	d["seed"] = seed
	d["indices"] = indices.duplicate(true)
	var cols := {}
	for k in colors.keys():
		var c: Color = colors[k]
		cols[k] = [c.r, c.g, c.b, c.a]
	d["colors"] = cols
	return d

static func from_dict(src: Dictionary) -> PortraitConfig:
	var cfg := PortraitConfig.new()
	cfg.name = src.get("name", "")
	cfg.seed = int(src.get("seed", 0))
	cfg.indices = src.get("indices", {}).duplicate(true)
	var col_in: Dictionary = src.get("colors", {})
	var out := {}
	for k in col_in.keys():
		var arr: Array = col_in[k]
		if typeof(arr) == TYPE_ARRAY and arr.size() >= 3:
			var a = 1.0
			if arr.size() >= 4:
				a = float(arr[3])
			out[k] = Color(float(arr[0]), float(arr[1]), float(arr[2]), a)
	cfg.colors = out
	return cfg
