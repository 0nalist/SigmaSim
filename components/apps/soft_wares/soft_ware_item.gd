extends HBoxContainer
class_name SoftWareItem

@export var app_icon: Texture2D
@export var app_title: String = ""
@export var app_description: String = ""
@export var app_cost: int = 0
@export var has_upgrades: bool = false
@export var app_id: String = ""

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = %CostLabel
@onready var action_button: Button = %ActionButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var feedback_label: Label = %FeedbackLabel

func _ready() -> void:
    icon_rect.texture = app_icon
    title_label.text = app_title
    description_label.text = app_description
    cost_label.text = "$" + str(app_cost)
    upgrades_button.visible = has_upgrades
    _update_action_button()
    action_button.pressed.connect(_on_action_button_pressed)
    upgrades_button.pressed.connect(_on_upgrades_button_pressed)
    WindowManager.app_unlocked.connect(_on_app_unlocked)

func _update_action_button() -> void:
    if WindowManager.is_app_unlocked(app_id):
        action_button.text = "Launch"
    else:
        action_button.text = "Unlock"

func _on_action_button_pressed() -> void:
    feedback_label.text = ""
    feedback_label.remove_theme_color_override("font_color")
    if WindowManager.is_app_unlocked(app_id):
        WindowManager.launch_app(app_id)
        return
    if PortfolioManager.cash >= float(app_cost):
        PortfolioManager.cash = PortfolioManager.cash - float(app_cost)
        WindowManager.unlock_app(app_id)
        _update_action_button()
    else:
        feedback_label.text = "Not enough cash!"
        feedback_label.add_theme_color_override("font_color", Color.RED)

func _on_upgrades_button_pressed() -> void:
    UpgradeManager.open_upgrade_pane(app_id)

func _on_app_unlocked(unlocked_id: String) -> void:
    if unlocked_id == app_id:
        _update_action_button()
