extends Pane
class_name EmailView

@onready var from_label: Label = %FromLabel
@onready var subject_label: Label = %SubjectLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var button_container: HBoxContainer = %Buttons

var email: EmailResource

func setup(email_res: EmailResource) -> void:
	email = email_res
	unique_popup_key = "email_%s" % email.get_instance_id()
	window_title = email.subject
	from_label.text = "From: %s" % email.from
	subject_label.text = "Subject: %s" % email.subject
	body_label.bbcode_enabled = true
	body_label.parse_bbcode(email.body)
	body_label.meta_clicked.connect(_on_body_meta_clicked)

	for child in button_container.get_children():
		child.queue_free()
	for action in email.buttons:
		var btn := Button.new()
		btn.text = action.get("text", "Action")
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): _on_email_action(action))
		btn.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_on_email_action(action, true)
				#event.accept()
		)
		button_container.add_child(btn)

func _on_body_meta_clicked(meta: Variant) -> void:
	var meta_str := str(meta)
	for action in email.buttons:
		if action.get("id", "") == meta_str:
			_on_email_action(action)
			return
	_on_email_action({"app_name": meta_str})

func _on_email_action(action: Dictionary, credit_only: bool = false) -> void:
	for stat in action.get("stat_changes", {}).keys():
		var amt = action["stat_changes"][stat]
		StatManager.set_base_stat(stat, StatManager.get_stat(stat) + amt)
	for upgrade_id in action.get("upgrade_ids", []):
		UpgradeManager.purchase(upgrade_id, credit_only)
	var app_name: String = action.get("app_name", "")
	if app_name != "":
		WindowManager.launch_app_by_name(app_name)
