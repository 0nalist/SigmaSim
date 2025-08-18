extends Pane
class_name NewYouApp

const PortraitFactory = preload("res://resources/portraits/portrait_factory.gd")

@onready var portrait_creator: PortraitCreator = %PortraitCreator

var target_type: String = ""
var target_npc_idx: int = -1
var portrait_view: PortraitView

func _ready() -> void:
        portrait_creator.applied.connect(_on_portrait_applied)

func setup_custom(args: Dictionary) -> void:
        portrait_view = args.get("portrait_view")
        target_type = args.get("type", "")
        target_npc_idx = args.get("npc_idx", -1)
        if portrait_view:
                portrait_creator.config = portrait_view.config.duplicate(true)
                portrait_creator._sync_ui_with_config()
                portrait_creator.preview.apply_config(portrait_creator.config)
        elif target_type == "player":
                var cfg_dict = PlayerManager.user_data.get("portrait_config", {})
                if cfg_dict is Dictionary and cfg_dict.size() > 0:
                        portrait_creator.config = PortraitConfig.from_dict(cfg_dict)
                else:
                        portrait_creator.config = PortraitFactory.generate_config_for_name(PlayerManager.user_data.get("name", ""))
                portrait_creator._sync_ui_with_config()
                portrait_creator.preview.apply_config(portrait_creator.config)
        elif target_type == "npc" and target_npc_idx != -1:
                var npc = NPCManager.get_npc_by_index(target_npc_idx)
                if npc != null:
                        portrait_creator.config = npc.portrait_config
                        portrait_creator._sync_ui_with_config()
                        portrait_creator.preview.apply_config(portrait_creator.config)

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
