extends PanelContainer
class_name SoftWareItem

@export var app_icon: Texture2D
@export var app_title: String = ""
@export var app_description: String = ""
@export var app_cost: int = 0
@export var app_id: String = ""

var upgrade_scene: PackedScene = null

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var action_button: Button = %ActionButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var feedback_label: Label = %FeedbackLabel

func _ready() -> void:

	icon_rect.texture = _prepare_icon(app_icon)
	#icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
	icon_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	title_label.text = app_title
	description_label.text = app_description
	upgrades_button.visible = upgrade_scene != null
	_update_action_button()
	action_button.pressed.connect(_on_action_button_pressed)
	action_button.gui_input.connect(_on_action_button_gui_input)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	WindowManager.app_unlocked.connect(_on_app_unlocked)


func _prepare_icon(source: Texture2D) -> Texture2D:
	if source == null:
			return null
	var img: Image = source.get_image()
	if img.get_width() != 64 or img.get_height() != 64:
			img.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

func _update_action_button() -> void:
	if WindowManager.is_app_unlocked(app_id):
			action_button.text = "Launch"
	else:
			action_button.text = "Buy App for $" + str(app_cost)

func _on_action_button_pressed() -> void:
	feedback_label.text = ""
	feedback_label.remove_theme_color_override("font_color")
	if WindowManager.is_app_unlocked(app_id):
			WindowManager.launch_app(app_id)
			return
	var required_score: int = PortfolioManager.CREDIT_REQUIREMENTS.get(app_title, 0)
	if PortfolioManager.attempt_spend(float(app_cost), required_score):
		var data = {
			"app_id": app_id,
			"app_title": app_title,
			"app_icon": app_icon,
		}
		WindowManager.launch_app_by_name("Installer", data)
	else:
		feedback_label.text = "Not enough funds!"
		feedback_label.add_theme_color_override("font_color", Color.RED)

func _on_action_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		feedback_label.text = ""
		feedback_label.remove_theme_color_override("font_color")
		if WindowManager.is_app_unlocked(app_id):
			WindowManager.launch_app(app_id)
			event.accept()
			return
		var required_score: int = PortfolioManager.CREDIT_REQUIREMENTS.get(app_title, 0)
		if PortfolioManager.attempt_spend(float(app_cost), required_score, false, true):
			var data = {
				"app_id": app_id,
				"app_title": app_title,
				"app_icon": app_icon,
			}
			WindowManager.launch_app_by_name("Installer", data)
		else:
			feedback_label.text = "Not enough credit!"
			feedback_label.add_theme_color_override("font_color", Color.RED)
		event.accept()

func _on_upgrades_button_pressed() -> void:
		if upgrade_scene:
				WindowManager.launch_popup(upgrade_scene, app_title + "::upgrade")

func _on_app_unlocked(unlocked_id: String) -> void:
	if unlocked_id == app_id:
		_update_action_button()
