extends Pane
class_name Installer

@onready var shortcut_checkbox: CheckBox = %ShortcutCheckBox
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var install_button: Button = %InstallButton

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
	if app_title != "":
		window_title = "Installing " + app_title

func _on_install_button_pressed() -> void:
	install_button.disabled = true
	progress_bar.value = 0
	var tween := get_tree().create_tween()
	tween.tween_property(progress_bar, "value", 99.0, 3.0)
	tween.tween_interval(4.0)
	tween.tween_property(progress_bar, "value", 100.0, 0.01)
	tween.tween_callback(Callable(self, "_complete_install"))

func _complete_install() -> void:
	if app_id != "":
		WindowManager.unlock_app(app_id)
	WindowManager.register_start_app(app_title)
	if shortcut_checkbox.button_pressed:
		DesktopLayoutManager.create_app_shortcut(app_title, app_title, icon_path, Vector2.ZERO)
	var window = get_parent().get_parent().get_parent()
	if WindowManager:
		WindowManager.close_window(window)
	else:
		window.queue_free()
