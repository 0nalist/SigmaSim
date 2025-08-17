extends Node
#class_name PortraitCache

var manifest: Dictionary = {}
var _texture_cache: Dictionary = {}

func _ready() -> void:
	_load_manifest()

func _load_manifest() -> void:
	var path = "res://resources/portraits/portrait_manifest.json"
	if not FileAccess.file_exists(path):
		push_error("Portrait manifest not found: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY:
		manifest = data
	else:
		manifest = {}

func layers_order() -> Array:
	return manifest.get("layers", [])

func layer_info(layer: String) -> Dictionary:
	return manifest.get(layer, {})

func get_texture(layer: String, index: int) -> Texture2D:
	var layer_cache = _texture_cache.get(layer, {})
	if layer_cache.has(index):
		return layer_cache[index]
	var info := layer_info(layer)
	var textures: Array = info.get("textures", [])
	if index >= 0 and index < textures.size():
		var path: String = textures[index]
		var tex: Texture2D = load(path)
		if tex != null:
			if not _texture_cache.has(layer):
				_texture_cache[layer] = {}
			_texture_cache[layer][index] = tex
			return tex
	return null
