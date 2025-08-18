class_name NewYouApp
extends Pane

const PortraitFactory = preload("res://resources/portraits/portrait_factory.gd")

var target_type: String = ""
var target_npc_idx: int = -1
var portrait_view: PortraitView

@onready var portrait_creator: PortraitCreator = %PortraitCreator


func _ready() -> void:
	portrait_creator.applied.connect(_on_portrait_applied)


func setup_custom(args: Dictionary) -> void:
	portrait_view = args.get("portrait_view")
	target_type = args.get("type", "")
	target_npc_idx = args.get("npc_idx", -1)

	var name_text := ""
	var npc: NPC = null
	if target_type == "player":
		name_text = PlayerManager.user_data.get("name", "")
	elif target_type == "npc" and target_npc_idx != -1:
		npc = NPCManager.get_npc_by_index(target_npc_idx)
		if npc != null:
			name_text = npc.full_name
	if portrait_view:
		portrait_creator.config = portrait_view.config.duplicate(true)
	elif target_type == "player":
		var cfg_dict = PlayerManager.user_data.get("portrait_config", {})
		if cfg_dict is Dictionary and cfg_dict.size() > 0:
			portrait_creator.config = PortraitConfig.from_dict(cfg_dict)
		else:
			var gen_cfg = PortraitFactory.generate_config_for_name(name_text)
			portrait_creator.config = gen_cfg
	elif npc != null:
		portrait_creator.config = npc.portrait_config
	portrait_creator._sync_ui_with_config()
	portrait_creator.preview.apply_config(portrait_creator.config)

	if name_text != "":
		portrait_creator.name_edit.text = name_text


func _on_portrait_applied(cfg: PortraitConfig) -> void:
	if portrait_view:
		portrait_view.apply_config(cfg)
	if target_type == "player":
		PlayerManager.user_data["portrait_config"] = cfg.to_dict()
	elif target_type == "npc" and target_npc_idx != -1:
		var npc = NPCManager.get_npc_by_index(target_npc_idx)
		if npc != null:
			npc.portrait_config = cfg
			NPCManager.set_npc_field(target_npc_idx, "portrait_config", cfg)
			DBManager.save_npc(target_npc_idx, npc)
