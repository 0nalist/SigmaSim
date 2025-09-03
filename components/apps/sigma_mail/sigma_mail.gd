extends Pane
class_name SigmaMail

@onready var search_bar: LineEdit = %SearchBar
@onready var limit_option: OptionButton = %LimitOption
@onready var inbox: VBoxContainer = %Inbox
@onready var page_label: Label = %PageLabel
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton

var emails: Array = []
var filtered_emails: Array = []
var current_page: int = 0
var emails_per_page: int = 12

func _ready() -> void:
        _generate_initial_email()
        limit_option.add_item("12", 12)
        limit_option.add_item("24", 24)
        limit_option.add_item("48", 48)
        limit_option.select(0)
        search_bar.text_changed.connect(_on_search_changed)
        limit_option.item_selected.connect(_on_limit_selected)
        prev_button.pressed.connect(_on_prev_page)
        next_button.pressed.connect(_on_next_page)
        _apply_filter()

func _generate_initial_email() -> void:
        emails.clear()
        var template: EmailResource = ResourceLoader.load("res://resources/emails/earlybird_email.tres") as EmailResource
        if template != null:
                var email: EmailResource = template.duplicate()
                var idx := int(PlayerManager.get_var("friend1_npc_index", -1))
                var first := "Friend"
                if idx != -1:
                        var npc = NPCManager.get_npc_by_index(idx)
                        if npc != null:
                                first = npc.first_name
                email.from = first
                email.body = email.body.format({"friend1_first_name": first})
                emails.append(email)

func _on_search_changed(_new_text: String) -> void:
		_apply_filter()

func _on_limit_selected(index: int) -> void:
		emails_per_page = int(limit_option.get_item_id(index))
		current_page = 0
		_render_emails()

func _on_prev_page() -> void:
		if current_page > 0:
				current_page -= 1
				_render_emails()

func _on_next_page() -> void:
		if (current_page + 1) * emails_per_page < filtered_emails.size():
				current_page += 1
				_render_emails()

func _apply_filter() -> void:
		var query = search_bar.text.to_lower()
		filtered_emails.clear()
		for email: EmailResource in emails:
				if query == "" or email.from.to_lower().find(query) != -1 or email.subject.to_lower().find(query) != -1:
						filtered_emails.append(email)
		current_page = 0
		_render_emails()

func _render_emails() -> void:
	for child in inbox.get_children():
			child.queue_free()
	var start = current_page * emails_per_page
	var end = min(start + emails_per_page, filtered_emails.size())
	for i in range(start, end):
		var email: EmailResource = filtered_emails[i]
		var box := VBoxContainer.new()
		inbox.add_child(box)

		var btn := Button.new()
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("14", 14)
		btn.text = "From: %s  Subject: %s" % [email.from, email.subject]
		btn.pressed.connect(func(): _open_email(email))
		box.add_child(btn)

	var total_pages = max(1, int(ceil(filtered_emails.size() / float(emails_per_page))))
	page_label.text = "Page %d/%d" % [current_page + 1, total_pages]
	prev_button.disabled = current_page == 0
	next_button.disabled = current_page >= total_pages - 1

func _open_email(email: EmailResource) -> void:
	var popup_scene = preload("res://components/apps/sigma_mail/email_view.tscn")
	var key = "email_%s" % email.get_instance_id()
	WindowManager.launch_popup(popup_scene, key, email)

func _on_email_action(action: Dictionary) -> void:
	for stat in action.get("stat_changes", {}).keys():
		var amt = action["stat_changes"][stat]
		StatManager.set_base_stat(stat, StatManager.get_stat(stat) + amt)
	for upgrade_id in action.get("upgrade_ids", []):
		UpgradeManager.purchase(upgrade_id)
	var app_name: String = action.get("app_name", "")
	if app_name != "":
		WindowManager.launch_app_by_name(app_name)
