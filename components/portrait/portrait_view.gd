class_name PortraitView
extends Control

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

                # Ensure crisp pixel-art rendering and scale to 2× the source size.
                # custom_minimum_size keeps Containers from shrinking the rect.
                # A project-wide default for NEAREST filtering can be set under
                # Rendering → Textures → Default Texture Filter.
                rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                rect.stretch_mode = TextureRect.STRETCH_SCALE
                var scaled_size: Vector2 = tex.get_size() * 2
                rect.custom_minimum_size = scaled_size
                rect.size = scaled_size

                var col_val = cfg.colors.get(layer, Color.WHITE)
                if col_val is String:
                        rect.modulate = Color(col_val)
                else:
                        rect.modulate = col_val
