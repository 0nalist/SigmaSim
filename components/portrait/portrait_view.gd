class_name PortraitView
extends Control

const PORTRAIT_SCALE := 2.0

func _ready() -> void:
	pass

func apply_config(cfg: PortraitConfig) -> void:
	for layer in PortraitCache.layers_order():
		var rect: TextureRect = get_node_or_null(layer)
		if rect == null:
			continue

		var idx: int = cfg.indices.get(layer, 0)
		var tex := PortraitCache.get_texture(layer, idx)

		# Crisp sampling + scale-by-size
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.stretch_mode = TextureRect.STRETCH_SCALE

		if tex is Texture2D:
			rect.texture = tex
			var native_size: Vector2 = (tex as Texture2D).get_size()
			var scaled_size: Vector2 = native_size * PORTRAIT_SCALE
			rect.custom_minimum_size = scaled_size
			rect.size = scaled_size
			rect.visible = true
		else:
			# No texture selected for this layer
			rect.texture = null
			rect.custom_minimum_size = Vector2.ZERO
			rect.size = Vector2.ZERO
			rect.visible = false

		var col_val = cfg.colors.get(layer, Color.WHITE)
		if col_val is String:
			rect.modulate = Color(col_val)
		else:
			rect.modulate = col_val
