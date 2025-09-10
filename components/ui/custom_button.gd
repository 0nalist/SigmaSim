extends PanelContainer
class_name CustomButton

signal pressed
signal button_up
signal button_down
signal toggled(toggled_on: bool)

enum IconLocation { LEFT, RIGHT }

@onready var _button: Button = %Button
@onready var _content_margin: MarginContainer = %ContentMargin
@onready var _icon_margin: MarginContainer = %IconMargin
@onready var _icon: TextureRect = %Icon
@onready var _label: Label = %Label
@onready var _hbox: HBoxContainer = %HBox

@export var text: String = "":
	set(value):
		text = value
		if _label:
			_label.text = text

@export var margin_left: float = 0.0:
	set(value):
		margin_left = value
		_update_content_margins()

@export var margin_right: float = 0.0:
	set(value):
		margin_right = value
		_update_content_margins()

@export var margin_top: float = 0.0:
	set(value):
		margin_top = value
		_update_content_margins()

@export var margin_bottom: float = 0.0:
	set(value):
		margin_bottom = value
		_update_content_margins()

@export var icon_margin_left: float = 0.0:
	set(value):
		icon_margin_left = value
		_update_icon_margins()

@export var icon_margin_right: float = 0.0:
	set(value):
		icon_margin_right = value
		_update_icon_margins()

@export var icon_margin_top: float = 0.0:
	set(value):
		icon_margin_top = value
		_update_icon_margins()

@export var icon_margin_bottom: float = 0.0:
	set(value):
		icon_margin_bottom = value
		_update_icon_margins()

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if _icon:
			_icon.texture = icon_texture
			_icon_margin.visible = icon_texture != null

@export_enum("left", "right") var icon_location: String = "left":
	set(value):
		icon_location = value
		_update_icon_location()

@export var icon_spacing: float = 4.0:
	set(value):
		icon_spacing = value
		if _hbox:
			_hbox.add_theme_constant_override("separation", icon_spacing)

@export var disabled: bool = false:
	set(value):
		disabled = value
		if _button:
			_button.disabled = disabled

@export var toggle_mode: bool = false:
	set(value):
		toggle_mode = value
		if _button:
			_button.toggle_mode = toggle_mode

@export var button_pressed: bool = false:
	set(value):
		button_pressed = value
		if _button:
			_button.button_pressed = button_pressed

@export var flat: bool = false:
	set(value):
		flat = value
		if _button:
			_button.flat = flat

@export var focus_mode: Control.FocusMode = Control.FOCUS_NONE:
	set(value):
		focus_mode = value
		if _button:
			_button.focus_mode = focus_mode

@export var text_overrun_behavior: TextServer.OverrunBehavior = TextServer.OVERRUN_NO_TRIMMING:
	set(value):
		text_overrun_behavior = value
		if _label:
			_label.text_overrun_behavior = text_overrun_behavior

@export var icon_stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
	set(value):
		icon_stretch_mode = value
		if _icon:
			_icon.stretch_mode = icon_stretch_mode

@export var icon_h_alignment: HorizontalAlignment = HorizontalAlignment.CENTER:
	set(value):
		icon_h_alignment = value
		if _icon:
			_icon.horizontal_alignment = icon_h_alignment

@export var icon_v_alignment: VerticalAlignment = VerticalAlignment.CENTER:
	set(value):
		icon_v_alignment = value
		if _icon:
			_icon.vertical_alignment = icon_v_alignment

func _ready() -> void:
	_update_content_margins()
	_update_icon_margins()
	_update_icon_location()
	if _hbox:
		_hbox.add_theme_constant_override("separation", icon_spacing)
	if _button:
		_button.pressed.connect(pressed.emit)
		_button.button_down.connect(button_down.emit)
		_button.button_up.connect(button_up.emit)
		_button.toggled.connect(func(toggled_on: bool) -> void:
			toggled.emit(toggled_on)
		)

func _update_content_margins() -> void:
	if _content_margin:
		_content_margin.add_theme_constant_override("margin_left", margin_left)
		_content_margin.add_theme_constant_override("margin_right", margin_right)
		_content_margin.add_theme_constant_override("margin_top", margin_top)
		_content_margin.add_theme_constant_override("margin_bottom", margin_bottom)

func _update_icon_margins() -> void:
	if _icon_margin:
		_icon_margin.add_theme_constant_override("margin_left", icon_margin_left)
		_icon_margin.add_theme_constant_override("margin_right", icon_margin_right)
		_icon_margin.add_theme_constant_override("margin_top", icon_margin_top)
		_icon_margin.add_theme_constant_override("margin_bottom", icon_margin_bottom)

func _update_icon_location() -> void:
	if _icon_margin and _hbox:
		if icon_location == "left":
			_icon_margin.move_to_front()
		else:
			_icon_margin.move_to_back()
