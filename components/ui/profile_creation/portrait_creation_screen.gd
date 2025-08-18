extends Control

signal step_valid(valid: bool)

@onready var portrait_creator: PortraitCreator = %PortraitCreator

var current_config: PortraitConfig = PortraitConfig.new()

func _ready() -> void:
    portrait_creator.applied.connect(_on_portrait_applied)
    emit_signal("step_valid", false)

func _on_portrait_applied(cfg: PortraitConfig) -> void:
    current_config = cfg
    emit_signal("step_valid", true)

func save_data() -> void:
    PlayerManager.user_data["portrait_config"] = current_config.to_dict()
