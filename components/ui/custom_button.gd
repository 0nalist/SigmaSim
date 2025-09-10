extends PanelContainer
class_name CustomButton

signal pressed
signal toggled(toggled_on: bool)

enum IconPlacement { LEFT, RIGHT }
enum IconVAlign { TOP, CENTER, BOTTOM }

var _text: String = ""
var _content_margin: int = 4
var _icon_margin: int = 0
var _icon_texture: Texture2D
var _icon_placement: IconPlacement = IconPlacement.LEFT
var _icon_v_align: IconVAlign = IconVAlign.CENTER

var _style_normal: StyleBox
var _style_hover: StyleBox
var _style_pressed: StyleBox
var _style_disabled: StyleBox

@onready var _content_margin_node: MarginContainer = %ContentMargin
@onready var _hbox: HBoxContainer = %HBox
@onready var _icon_margin_node: MarginContainer = %IconMargin
@onready var _icon_rect: TextureRect = %Icon
@onready var _label: Label = %Label
var _button: Button

@export var text: String:
	set(value):
		_text = value
		if _label:
			_label.text = value
	get:
		return _text

@export var content_margin: int = 4:
	set(value):
		_content_margin = value
		if _content_margin_node:
			for side in ["left", "top", "right", "bottom"]:
				_content_margin_node.add_theme_constant_override("margin_" + side, value)
	get:
		return _content_margin

@export var icon_margin: int = 0:
	set(value):
		_icon_margin = value
		if _icon_margin_node:
			for side in ["left", "top", "right", "bottom"]:
				_icon_margin_node.add_theme_constant_override("margin_" + side, value)
	get:
		return _icon_margin

@export var icon_texture: Texture2D:
	set(value):
		_icon_texture = value
		if _icon_rect:
			_icon_rect.texture = value
			_icon_margin_node.visible = value != null
	get:
		return _icon_texture

@export var icon_placement: IconPlacement = IconPlacement.LEFT:
	set(value):
		_icon_placement = value
		if _hbox and _icon_margin_node and _label:
			if value == IconPlacement.LEFT:
				_hbox.move_child(_icon_margin_node, 0)
				_hbox.move_child(_label, 1)
			else:
				_hbox.move_child(_label, 0)
				_hbox.move_child(_icon_margin_node, 1)
	get:
		return _icon_placement

@export var icon_v_align: IconVAlign = IconVAlign.CENTER:
	set(value):
		_icon_v_align = value
		if _icon_rect:
			match value:
				IconVAlign.TOP:
					_icon_rect.v_size_flags = Control.SIZE_SHRINK_BEGIN
				IconVAlign.BOTTOM:
					_icon_rect.v_size_flags = Control.SIZE_SHRINK_END
				_:
					_icon_rect.v_size_flags = Control.SIZE_SHRINK_CENTER
	get:
		return _icon_v_align

func _ready() -> void:
	_button = Button.new()
	_button.text = ""
	_button.toggle_mode = false
	_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for style in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		_button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	add_child(_button)
	_style_normal = _get_button_stylebox("normal")
	_style_hover = _get_button_stylebox("hover")
	_style_pressed = _get_button_stylebox("pressed")
	_style_disabled = _get_button_stylebox("disabled")
	_update_style()
	_button.pressed.connect(func(): emit_signal("pressed"))
	_button.toggled.connect(func(t): emit_signal("toggled", t))
	_button.button_down.connect(_update_style)
	_button.button_up.connect(_update_style)
	_button.mouse_entered.connect(_update_style)
	_button.mouse_exited.connect(_update_style)
	_button.focus_entered.connect(_update_style)
	_button.focus_exited.connect(_update_style)
	call_deferred("update_label")

func update_label():
	_label.text = _text


func _get_button_stylebox(name: String) -> StyleBox:
	var theme: Theme = get_theme()
	if theme and theme.has_stylebox(name, "Button"):
		return theme.get_stylebox(name, "Button")
	return ThemeDB.get_default_theme().get_stylebox(name, "Button")

func _update_style() -> void:
	var sb: StyleBox = _style_normal
	if _button.disabled:
		sb = _style_disabled
	elif _button.button_pressed:
		sb = _style_pressed
	elif _button.is_hovered() or _button.has_focus():
		sb = _style_hover
	add_theme_stylebox_override("panel", sb)
