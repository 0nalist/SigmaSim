extends Control

@onready var logging_in_panel: Panel = %LoggingInPanel
@onready var profile_v_box_container: VBoxContainer = %ProfileVBoxContainer
@onready var password_text_edit: TextEdit = %PasswordTextEdit
@onready var log_in_button: Button = %LogInButton
@onready var panel: Panel = %Panel
@onready var logging_in_label: Label = %LoggingInLabel


func _ready() -> void:
	password_text_edit.hide()
	log_in_button.hide()
	%LoggingInPanel.hide()
	%ProfileVBoxContainer.show()
	panel.custom_minimum_size.y = 170


func select_profile() -> void:
	password_text_edit.show()
	log_in_button.show()
	panel.custom_minimum_size.y = 240


func _on_panel_gui_input(event: InputEvent) -> void:
	select_profile()


func _on_log_in_button_pressed() -> void:
	await get_tree().create_timer(.2).timeout
	profile_v_box_container.hide()
	logging_in_panel.show()
	await get_tree().create_timer(.3).timeout
	%LoggingInLabel.text = "Locking in."
	await get_tree().create_timer(.65).timeout
	%LoggingInLabel.text = "Locking in.."
	await get_tree().create_timer(.8).timeout
	var desktop_scene = preload("res://desktop_env.tscn")
	%LoggingInLabel.text = "Locking in..."
	await get_tree().create_timer(.8).timeout
	var desktop = desktop_scene.instantiate()
	get_parent().add_child(desktop)
	queue_free()
