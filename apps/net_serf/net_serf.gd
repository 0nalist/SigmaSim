extends Pane
class_name NetSerf

@onready var back_button: Button = %BackButton
@onready var forward_button: Button = %ForwardButton
@onready var go_button: Button = %GoButton
@onready var reload_button: Button = %ReloadButton
@onready var devtools_button: Button = %DevtoolsButton
@onready var url_field: LineEdit = %UrlField
@onready var web_view: Control = %WebView  # class is WebView from godot_wry

var _home_url: String = "https://www.youtube.com/watch?v=ueNY30Cs8Lk&list=RDueNY30Cs8Lk&start_radio=1"
var _last_committed_url: String = ""
const URL_HOOK_JS: String = """
(function() {
	if (window.__godot_url_hook_installed) return;
	window.__godot_url_hook_installed = true;
	const report = url => window.ipc.postMessage("URL:" + url);
	report(window.location.href);
	document.addEventListener("click", e => {
		const a = e.target.closest("a");
		if (a && a.href) report(a.href);
	}, true);
	window.addEventListener("hashchange", () => report(window.location.href));
	window.addEventListener("popstate", () => report(window.location.href));
	const pushState = history.pushState;
	history.pushState = function(state, title, url) {
		pushState.call(this, state, title, url);
		report(window.location.href);
	};
	const replaceState = history.replaceState;
	history.replaceState = function(state, title, url) {
		replaceState.call(this, state, title, url);
		report(window.location.href);
	};
})();
"""

func _ready() -> void:
	# Toolbar wiring
	back_button.pressed.connect(_on_back_pressed)
	forward_button.pressed.connect(_on_forward_pressed)
	go_button.pressed.connect(_on_go_pressed)
	reload_button.pressed.connect(_on_reload_pressed)
	devtools_button.pressed.connect(_on_devtools_pressed)
	url_field.text_submitted.connect(_on_url_submitted)
	url_field.gui_input.connect(_on_url_field_gui_input)

	# WebView initial state
	if _is_valid_url(_home_url):
		_set_url_field(_home_url)
		_load_url_normalized(_home_url)
	else:
		_set_url_field("https://www.wikipedia.org")
		_load_url_normalized("https://www.wikipedia.org")
	call_deferred("_inject_url_hook")

	# Optional: listen for IPC messages from page JS
	if web_view.has_signal("ipc_message"):
		web_view.connect("ipc_message", Callable(self, "_on_webview_ipc_message"))
	if window_frame:
		window_frame.resized.connect(_update_webview_rect)
		if window_frame.has_signal("position_changed"):
			window_frame.position_changed.connect(_update_webview_rect)
	var root_viewport: Viewport = get_tree().root
	root_viewport.size_changed.connect(_update_webview_rect_deferred)
	_update_webview_rect()
	_update_webview_rect_deferred()

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
	call_deferred("_inject_url_hook")

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
	if message.begins_with("URL:"):
		var current: String = message.substr(4)
		_set_url_field(current)
		_last_committed_url = current
		call_deferred("_inject_url_hook")
	else:
		# For future interop with page JS; keep a simple debug log for now.
		print("[NetSerf] IPC:", message)

func _update_webview_rect() -> void:
	var root_viewport: Viewport = get_tree().root
	var visible_rect: Rect2 = root_viewport.get_visible_rect()

	# Convert to Vector2 so both operands match
	var scale: Vector2 = visible_rect.size / Vector2(root_viewport.size)

	var position: Vector2 = (global_position * scale) + visible_rect.position
	var scaled_size: Vector2 = size * scale

	web_view.set_position(position)
	web_view.set_size(scaled_size)


func _update_webview_rect_deferred() -> void:
	await get_tree().process_frame
	_update_webview_rect()

func _inject_url_hook() -> void:
	web_view.call("eval", URL_HOOK_JS)

func _on_url_field_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		url_field.grab_focus()
		url_field.accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_webview_rect_deferred()
