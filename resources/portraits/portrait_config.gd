extends Resource
class_name PortraitConfig

@export var name: String = ""
@export var seed: int = 0
@export var indices: Dictionary = {}
@export var colors: Dictionary = {}

func _init() -> void:
	pass

func to_dict() -> Dictionary:
	var data: Dictionary = {}
	data["name"] = name
	data["seed"] = seed
	data["indices"] = indices.duplicate(true)
	var color_copy: Dictionary = {}
	for key in colors.keys():
		var value = colors[key]
		if value is Color:
			color_copy[key] = value.to_html()
		else:
			color_copy[key] = value
	data["colors"] = color_copy
	return data

static func from_dict(d: Dictionary) -> PortraitConfig:
	var cfg := PortraitConfig.new()
	cfg.name = d.get("name", "")
	cfg.seed = d.get("seed", 0)
	cfg.indices = d.get("indices", {}).duplicate(true)
	var color_dict: Dictionary = {}
	var src_colors: Dictionary = d.get("colors", {})
	for key in src_colors.keys():
		var val = src_colors[key]
		if typeof(val) == TYPE_STRING:
			color_dict[key] = Color(val)
		else:
			color_dict[key] = val
	cfg.colors = color_dict
	return cfg
