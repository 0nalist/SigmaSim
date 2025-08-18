class_name PortraitView
extends Control

const PORTRAIT_SCALE := 2.0

@export var portrait_creator_enabled: bool = true
@export var subject_is_player: bool = false
@export var subject_npc_idx: int = -1

var config: PortraitConfig = PortraitConfig.new()

@onready var new_you_button: Button = %NewYouButton


func _ready() -> void:
	await get_tree().process_frame
	pivot_offset = size / 2
	resized.connect(_center_layers)
	_center_layers()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	new_you_button.pressed.connect(_on_new_you_pressed)
	new_you_button.mouse_filter = Control.MOUSE_FILTER_PASS
	if subject_is_player:
		var cfg_dict = PlayerManager.get_var("portrait_config", {})
		if cfg_dict is Dictionary:
			var cfg = PortraitConfig.from_dict(cfg_dict)
			apply_config(cfg)

func _center_layers() -> void:
	for child in get_children():
		if child is TextureRect:
			child.position = (size - child.size) / 2


func apply_config(cfg: PortraitConfig) -> void:
	config = cfg.duplicate(true)
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

		# Keep each layer centered within the view
		rect.position = (size - rect.size) / 2


func _on_mouse_entered() -> void:
	if portrait_creator_enabled:
			new_you_button.visible = true


func _on_mouse_exited() -> void:
	new_you_button.visible = false


func _on_new_you_pressed() -> void:
	var scene = preload("res://components/apps/new_you/new_you.tscn")
	var pane = scene.instantiate()
	var args: Dictionary = {"portrait_view": self}
	if subject_is_player:
			args["type"] = "player"
	elif subject_npc_idx != -1:
			args["type"] = "npc"
			args["npc_idx"] = subject_npc_idx
	WindowManager.launch_pane_instance(pane, args)
