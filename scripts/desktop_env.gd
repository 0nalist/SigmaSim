extends Control

@onready var start_panel: StartPanelWindow = %StartPanel
@onready var taskbar: Control = %Taskbar
@onready var trash_window: Pane = %TrashWindow
@onready var background: TextureRect = %Background

@export var background_texture: Texture = preload("res://assets/backgrounds/Bliss_(Windows_XP) (2).png")

func _ready() -> void:
	#SaveManager.save_to_slot(PlayerManager.get_slot_id())
	
	GameManager.in_game = true
	#hide_all_windows_and_panels()
	WindowManager.taskbar_container = taskbar
	WindowManager.start_panel = start_panel
	
	call_deferred("_deferred_load_save")
	launch_startup_apps()
	print("Active slot_id:", SaveManager.current_slot_id)

func launch_startup_apps() -> void:
	WindowManager.launch_app_by_name("BrokeRage")


func _deferred_load_save():
	SaveManager.load_from_slot(SaveManager.current_slot_id)
	var path = PlayerManager.user_data.get("background_path", "")
	if path != "":
		var tex = load(path)
		if tex is Texture2D:
			background.texture = tex
		else:
			print("❌ Couldn't load texture from path: ", path)
	else:
		background.texture = background_texture  # fallback


func hide_all_windows_and_panels() -> void:
	start_panel.hide()
	trash_window.hide()
	# All apps should now open dynamically via StartPanel

# ----------------------------- #
# Taskbar / Start Menu Buttons #
# ----------------------------- #

func _on_start_button_pressed() -> void:
	start_panel.toggle_start_panel()

func _on_trash_button_pressed() -> void:
	open_trash_folder()

func open_trash_folder() -> void:
	trash_window.show()
	trash_window.grab_focus()


func _on_save_button_pressed() -> void:
	SaveManager.save_to_slot(SaveManager.current_slot_id)


func _on_load_button_pressed() -> void:
	SaveManager.load_from_slot(SaveManager.current_slot_id)
