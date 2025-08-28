extends PanelContainer
class_name WalletCardBase

const WALLET_DEBUG: bool = false

var _root: VBoxContainer
var _header_box: HBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _content: VBoxContainer
var _footer_box: HBoxContainer

@export var card_id: String = ""
@export var card_title: String = "Card"
@export var card_subtitle: String = ""
@export var preferred_width: float = 336.0
@export var preferred_height: float = 212.0

var _border_highlight_running: bool = false
var _value_flash_running: bool = false
var _tween: Tween = null

var _pending_setup: bool = false
var _pending_id: String = ""
var _pending_title: String = ""
var _pending_subtitle: String = ""

var _shell_built: bool = false

func _d(msg: String) -> void:
	if WALLET_DEBUG:
		print("[Wallet] " + msg)

func _ready() -> void:
       # Allow mouse events (like wheel scrolling) to bubble up to the
       # WalletStack for card navigation.
       mouse_filter = Control.MOUSE_FILTER_PASS
       _ensure_shell()

func _ensure_shell() -> void:
	if _shell_built:
		return
	_build_card_shell()
	_apply_default_theme()
	_apply_card_size()
	_apply_pending_setup()
	_shell_built = true
	# Center pivot after a frame so size is valid
	call_deferred("_apply_pivot")

func _apply_pivot() -> void:
	pivot_offset = size * 0.5

func setup(id: String, title: String, subtitle: String = "") -> void:
	_pending_setup = true
	_pending_id = id
	_pending_title = title
	_pending_subtitle = subtitle
	_apply_pending_setup()

func _apply_pending_setup() -> void:
	if not _pending_setup:
		return
	card_id = _pending_id
	card_title = _pending_title
	card_subtitle = _pending_subtitle
	if _title_label != null:
		_title_label.text = card_title
	if _subtitle_label != null:
		_subtitle_label.text = card_subtitle

func _build_card_shell() -> void:
	_root = VBoxContainer.new()
	_root.name = "Root"
	_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_root.custom_minimum_size = Vector2(preferred_width, preferred_height)
	_root.add_theme_constant_override("separation", 8)
	add_child(_root)

	_header_box = HBoxContainer.new()
	_header_box.name = "Header"
	_header_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_box.add_theme_constant_override("separation", 6)
	_root.add_child(_header_box)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = card_title
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	_header_box.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.text = card_subtitle
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
	_header_box.add_child(_subtitle_label)

	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	_root.add_child(_content)

	_footer_box = HBoxContainer.new()
	_footer_box.name = "Footer"
	_footer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_box.add_theme_constant_override("separation", 8)
	_root.add_child(_footer_box)

func _apply_default_theme() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.13, 0.18)
	sb.border_color = Color(0.25, 0.45, 0.85)
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.shadow_size = 10
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", sb)

func _apply_card_size() -> void:
	custom_minimum_size = Vector2(preferred_width, preferred_height)

func add_group(group_title: String, rows: Array) -> void:
	_ensure_shell()
	if _content == null:
		return
	var group_v: VBoxContainer = VBoxContainer.new()
	group_v.add_theme_constant_override("separation", 2)
	group_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_v.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var cap: Label = Label.new()
	cap.text = group_title.to_upper()
	cap.add_theme_font_size_override("font_size", 11)
	cap.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95, 0.85))
	group_v.add_child(cap)

	for entry in rows:
		var row_h: HBoxContainer = HBoxContainer.new()
		row_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_h.add_theme_constant_override("separation", 6)

		var l: Label = Label.new()
		l.text = String(entry.get("label", ""))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
		row_h.add_child(l)

		var v: Label = Label.new()
		v.text = String(entry.get("value", ""))
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_color_override("font_color", Color(0.95, 0.80, 0.40))
		row_h.add_child(v)

		group_v.add_child(row_h)

	_content.add_child(group_v)

func add_meter(label_text: String, percent_0_100: float) -> ProgressBar:
	_ensure_shell()
	if _content == null:
		return null
	var cap_h: HBoxContainer = HBoxContainer.new()
	cap_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var l: Label = Label.new()
	l.text = label_text
	l.add_theme_color_override("font_color", Color(0.8, 0.88, 0.97))
	cap_h.add_child(l)

	var p: Label = Label.new()
	p.text = String.num(percent_0_100, 1) + "%"
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	cap_h.add_child(p)

	_content.add_child(cap_h)

	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = 100.0
	bar.value = percent_0_100
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0.0, 8.0)
	_content.add_child(bar)
	return bar

func set_footer_note(text: String) -> void:
	_ensure_shell()
	if _footer_box == null:
		return
	for child in _footer_box.get_children():
		child.queue_free()
	var lab: Label = Label.new()
	lab.text = text
	lab.add_theme_color_override("font_color", Color(0.80, 0.85, 0.94, 0.85))
	lab.add_theme_font_size_override("font_size", 11)
	_footer_box.add_child(lab)

func flash_border() -> void:
	_ensure_shell()
	if _border_highlight_running:
		return
	_border_highlight_running = true
	var sb: StyleBox = get_theme_stylebox("panel")
	var flat: StyleBoxFlat = sb as StyleBoxFlat
	var original: Color = flat.border_color
	flat.border_color = Color(0.55, 0.8, 1.0)
	await get_tree().create_timer(0.22).timeout
	flat.border_color = original
	_border_highlight_running = false

func bump_value_color() -> void:
	_ensure_shell()
	if _value_flash_running:
		return
	_value_flash_running = true
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	await get_tree().create_timer(0.25).timeout
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	_value_flash_running = false

func tween_bar_to(bar: ProgressBar, target: float, seconds: float) -> void:
	if bar == null:
		return
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(bar, "value", clampf(target, 0.0, 100.0), seconds)
