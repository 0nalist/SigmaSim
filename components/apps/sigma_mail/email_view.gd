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
	body_label.text = email.body

	for child in button_container.get_children():
		child.queue_free()
	for action in email.buttons:
		var btn := Button.new()
		btn.text = action.get("text", "Action")
		btn.pressed.connect(func(): _on_email_action(action))
		button_container.add_child(btn)

func _on_email_action(action: Dictionary) -> void:
	for stat in action.get("stat_changes", {}).keys():
		var amt = action["stat_changes"][stat]
		StatManager.set_base_stat(stat, StatManager.get_stat(stat) + amt)
	for upgrade_id in action.get("upgrade_ids", []):
		UpgradeManager.purchase(upgrade_id)
	var app_name: String = action.get("app_name", "")
	if app_name != "":
		WindowManager.launch_app_by_name(app_name)
