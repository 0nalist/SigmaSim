extends Pane
class_name SigmaMail

@onready var search_bar: LineEdit = %SearchBar
@onready var limit_spin: SpinBox = %LimitSpin
@onready var inbox: VBoxContainer = %Inbox
@onready var page_label: Label = %PageLabel
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton

var emails: Array = []
var filtered_emails: Array = []
var current_page: int = 0
var emails_per_page: int = 10

func _ready() -> void:
        _generate_dummy_emails()
        limit_spin.value = emails_per_page
        search_bar.text_changed.connect(_on_search_changed)
        limit_spin.value_changed.connect(_on_limit_changed)
        prev_button.pressed.connect(_on_prev_page)
        next_button.pressed.connect(_on_next_page)
        _apply_filter()

func _generate_dummy_emails() -> void:
        emails.clear()
        for i in range(1, 51):
                emails.append({
                        "from": "user%d@example.com" % i,
                        "subject": "Subject %d" % i,
                })

func _on_search_changed(_new_text: String) -> void:
        _apply_filter()

func _on_limit_changed(value: float) -> void:
        emails_per_page = int(value)
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
        for email in emails:
                if query == "" or email["from"].to_lower().find(query) != -1 or email["subject"].to_lower().find(query) != -1:
                        filtered_emails.append(email)
        current_page = 0
        _render_emails()

func _render_emails() -> void:
        for child in inbox.get_children():
                child.queue_free()
        var start = current_page * emails_per_page
        var end = min(start + emails_per_page, filtered_emails.size())
        for i in range(start, end):
                var email = filtered_emails[i]
                var btn = Button.new()
                btn.text = "From: %s  Subject: %s" % [email["from"], email["subject"]]
                btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
                inbox.add_child(btn)
        var total_pages = max(1, int(ceil(filtered_emails.size() / float(emails_per_page))))
        page_label.text = "Page %d/%d" % [current_page + 1, total_pages]
        prev_button.disabled = current_page == 0
        next_button.disabled = current_page >= total_pages - 1

