extends Control
class_name PortraitView

func _ready() -> void:
	pass

func apply_config(cfg: PortraitConfig) -> void:
		for layer in PortraitCache.layers_order():
				var rect: TextureRect = get_node_or_null(layer)
				if rect == null:
						continue
				var idx: int = cfg.indices.get(layer, 0)
				var tex := PortraitCache.get_texture(layer, idx)
				rect.texture = tex
				var col_val = cfg.colors.get(layer, Color.WHITE)
				if col_val is String:
						rect.modulate = Color(col_val)
				else:
						rect.modulate = col_val
		if cfg.indices.get("hair", 0) > 0 and cfg.indices.get("hair_back", 0) > 0:
				var hair_rect: TextureRect = get_node_or_null("hair")
				var hair_back_rect: TextureRect = get_node_or_null("hair_back")
				if hair_rect != null and hair_back_rect != null:
						hair_back_rect.modulate = hair_rect.modulate
