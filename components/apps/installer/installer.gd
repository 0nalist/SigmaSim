extends Pane
class_name Installer

@onready var shortcut_checkbox: CheckBox = %ShortcutCheckBox
@onready var open_checkbox: CheckBox = %OpenCheckBox
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var install_button: Button = %InstallButton
@onready var app_logo: TextureRect = %AppLogo

var app_id: String = ""
var app_title: String = ""
var app_icon: Texture2D = null
var icon_path: String = ""

func _ready() -> void:
	window_can_close = false
	progress_bar.value = 0
	progress_bar.show_percentage = true
	install_button.pressed.connect(_on_install_button_pressed)

func setup_custom(data: Dictionary) -> void:
	app_id = data.get("app_id", "")
	app_title = data.get("app_title", "")
	app_icon = data.get("app_icon", null)
	if app_icon:
		icon_path = app_icon.resource_path
		app_logo.texture = _prepare_icon(app_icon)
		app_logo.stretch_mode = TextureRect.STRETCH_SCALE
		app_logo.custom_minimum_size = Vector2(64, 64)
	if app_title != "":
		window_title = "Installing " + app_title

func _prepare_icon(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	var img: Image = source.get_image()
	if img.get_width() != 64 or img.get_height() != 64:
		img.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

func _on_install_button_pressed() -> void:
	install_button.disabled = true
	progress_bar.value = 0
	var tween := get_tree().create_tween()
	tween.tween_property(progress_bar, "value", 99.0, 3.0)
	tween.tween_interval(4.0)
	tween.tween_property(progress_bar, "value", 100.0, 0.2)
	tween.tween_callback(Callable(self, "_complete_install"))

func _complete_install() -> void:
	if app_id != "":
			WindowManager.unlock_app(app_id)
			if open_checkbox.button_pressed:
				WindowManager.launch_app(app_id)
	if shortcut_checkbox.button_pressed:
		DesktopLayoutManager.create_app_shortcut(app_title, app_title, icon_path, Vector2.ZERO)
	var window = get_parent().get_parent().get_parent()
	if WindowManager:
		WindowManager.close_window(window)
	else:
		window.queue_free()
