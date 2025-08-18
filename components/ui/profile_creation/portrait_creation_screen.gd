extends Control

signal step_valid(valid: bool)

var current_config: PortraitConfig = PortraitConfig.new()

@onready var portrait_creator: PortraitCreator = %PortraitCreator

func _ready() -> void:
    portrait_creator.applied.connect(_on_portrait_applied)
    emit_signal("step_valid", false)

    # Auto-fill the player's name and generate an initial portrait
    var pname := PlayerManager.get_var("name", "")
    if pname != "":
        portrait_creator.name_edit.text = pname
        portrait_creator._on_generate_pressed()

func _on_portrait_applied(cfg: PortraitConfig) -> void:
    current_config = cfg
    emit_signal("step_valid", true)

func save_data() -> void:
    PlayerManager.user_data["portrait_config"] = current_config.to_dict()
