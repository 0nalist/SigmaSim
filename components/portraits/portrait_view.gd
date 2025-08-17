extends Control
class_name PortraitView

func get_order() -> Array[String]:
    return PortraitFactory.get_layers_order()

func set_layer_texture(layer: String, tex: Texture2D) -> void:
    var node: TextureRect = get_node_or_null(layer)
    if node:
        node.texture = tex

func set_layer_color(layer: String, color: Color) -> void:
    var node: TextureRect = get_node_or_null(layer)
    if node:
        node.modulate = color
