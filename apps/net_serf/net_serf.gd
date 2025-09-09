extends Pane
class_name NetSerf

@onready var back_button: Button = %BackButton
@onready var forward_button: Button = %ForwardButton
@onready var go_button: Button = %GoButton
@onready var reload_button: Button = %ReloadButton
@onready var devtools_button: Button = %DevtoolsButton
@onready var url_field: LineEdit = %UrlField
@onready var web_view: Control = %WebView  # class is WebView from godot_wry

var _home_url: String = "https://www.wikipedia.org"
var _last_committed_url: String = ""

func _ready() -> void:
	# Toolbar wiring
	back_button.pressed.connect(_on_back_pressed)
	forward_button.pressed.connect(_on_forward_pressed)
	go_button.pressed.connect(_on_go_pressed)
	reload_button.pressed.connect(_on_reload_pressed)
	devtools_button.pressed.connect(_on_devtools_pressed)
	url_field.text_submitted.connect(_on_url_submitted)

	# WebView initial state
	if _is_valid_url(_home_url):
		_set_url_field(_home_url)
		_load_url_normalized(_home_url)
	else:
		_set_url_field("https://www.wikipedia.org")
		_load_url_normalized("https://www.wikipedia.org")

	# Optional: listen for IPC messages from page JS
	if web_view.has_signal("ipc_message"):
		web_view.connect("ipc_message", Callable(self, "_on_webview_ipc_message"))

func open_url(url: String) -> void:
	_load_url_normalized(url)
	web_view.call("focus")

func _on_back_pressed() -> void:
	# There is no native back() method in WebView; use JS history.
	web_view.call("eval", "history.back()")

func _on_forward_pressed() -> void:
	web_view.call("eval", "history.forward()")

func _on_go_pressed() -> void:
	var raw: String = url_field.text.strip_edges()
	if raw.is_empty():
		return
	_load_url_normalized(raw)
	web_view.call("focus")

func _on_reload_pressed() -> void:
	web_view.call("reload")

func _on_devtools_pressed() -> void:
	# Toggle DevTools window
	var is_open: bool = bool(web_view.call("is_devtools_open"))
	if is_open:
		web_view.call("close_devtools")
	else:
		web_view.call("open_devtools")

func _on_url_submitted(text: String) -> void:
	var raw: String = text.strip_edges()
	if raw.is_empty():
		return
	_load_url_normalized(raw)
	web_view.call("focus")

func _load_url_normalized(raw: String) -> void:
	var normalized: String = _normalize_url(raw)
	_set_url_field(normalized)
	_last_committed_url = normalized
	web_view.call("load_url", normalized)

func _set_url_field(text: String) -> void:
	# Avoid triggering text_submitted accidentally
	url_field.text = text

func _normalize_url(raw: String) -> String:
	var lower: String = raw.to_lower()
	if lower.begins_with("http://") or lower.begins_with("https://"):
		return raw
	if raw.find(".") >= 0:
		return "https://" + raw
	# Treat as search query if no dot; use DuckDuckGo by default
	var encoded: String = _url_encode(raw)
	return "https://duckduckgo.com/?q=" + encoded

func _url_encode(s: String) -> String:
	# Minimal URL encoding for spaces and a few common chars
	var result: PackedByteArray = s.to_utf8_buffer()
	var out: String = ""
	var i: int = 0
	while i < result.size():
		var c: int = int(result[i])
		var ch: String = String.chr(c)
		var is_unreserved: bool = _is_unreserved_char(ch)
		if is_unreserved:
			out += ch
		else:
			out += "%%%02X" % c
		i += 1
	return out

func _is_unreserved_char(ch: String) -> bool:
	# RFC 3986 unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
	if ch.length() != 1:
		return false
	var code: int = int(ch.unicode_at(0))
	var is_alpha: bool = (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
	var is_digit: bool = (code >= 48 and code <= 57)
	if is_alpha or is_digit:
		return true
	if ch == "-" or ch == "." or ch == "_" or ch == "~":
		return true
	return false

func _is_valid_url(url: String) -> bool:
	var lower: String = url.to_lower()
	var ok_scheme: bool = lower.begins_with("http://") or lower.begins_with("https://")
	return ok_scheme and url.find(".") >= 0

func _on_webview_ipc_message(message: String) -> void:
	# For future interop with page JS; keep a simple debug log for now.
        print("[NetSerf] IPC:", message)
