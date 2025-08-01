extends MarginContainer
class_name ChatBox

var is_npc_message: bool = false
var resolved: bool = false

@onready var text_label = %TextLabel
@onready var emoji_reaction: TextureRect = %EmojiReaction

@onready var effect_icons: Control = %EffectIcons
@onready var effect_icons_hbox: HBoxContainer = %EffectIconsHBox

@onready var left_effect_icons: Control = %LeftEffectIcons
@onready var left_effect_icons_hbox: HBoxContainer = $LeftEffectIcons/LeftEffectIconsHBox



const ICONS = {
	"chem_up": preload("res://assets/emojis/test_tube_twemoji_x72_1f9ea.png"),
	"chem_down": preload("res://assets/emojis/test_tube_twemoji_x72_1f9ea.png"),
	"esteem_up": preload("res://assets/emojis/mirror_twemoji_x72_1fa9e.png"),
	"esteem_down": preload("res://assets/emojis/mirror_twemoji_x72_1fa9e.png"),
	"appre_up": preload("res://assets/emojis/grimace_twemoji_x72_1f62c.png"),
	"appre_down": preload("res://assets/emojis/smiling_eyes_blush_twemoji_x72_1f60a.png"),
	"conf_up": preload("res://assets/emojis/sunglasses_smiley_twemoji_x72_1f60e.png"),
	"conf_down": preload("res://assets/emojis/flushed_face_twemoji_x72_1f633.png"),
}

@onready var message_container: PanelContainer = %MessageContainer

'''
func _input(event):
	if event is InputEventMouseMotion:
		var mouse_pos = get_viewport().get_mouse_position()
		var control = get_viewport().gui_get_hovered_control()
		if control:
			print("Hovering over: ", control.name, " (", control, ")")
'''


var text: String = ""
var result: String = "neutral" # "neutral", "success", "fail"
var reaction_name: String = ""
var reaction_tooltip: String = ""
var effects: Dictionary = {}
var is_victory_number: bool = false
var chatlog_index: int = -1


# Persistent color tints for result
const COLOR_PERSIST_NEUTRAL = Color(1, 1, 1)
const COLOR_PERSIST_SUCCESS = Color(0.78, 1.0, 0.78)
const COLOR_PERSIST_FAIL    = Color(1.0, 0.76, 0.76)

# Flash colors for "dopamine hit"
const COLOR_FLASH_SUCCESS = Color(0.5, 1.2, 0.5)
const COLOR_FLASH_FAIL    = Color(1.2, 0.3, 0.3)





func _ready():
	text_label.text = text
	set_result("neutral") # start neutral
	clear_reaction()
	
	#emoji_reaction.size = Vector2(32, 32)
	#emoji_reaction.custom_minimum_size = Vector2(32, 32)
	emoji_reaction.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	effect_icons.mouse_filter = Control.MOUSE_FILTER_PASS
	effect_icons_hbox.mouse_filter = Control.MOUSE_FILTER_PASS


func reveal_result_color(result: String) -> void:
	# Use await to make it sync with the rest of the animations if needed
	await get_tree().process_frame
	set_result_and_flash(result)


func set_result_and_flash(new_result: String, duration := 0.4):
	if resolved:
		return
	set_result(new_result)
	flash_result(duration)
	resolved = true

# Just sets the persistent color, does NOT animate
func set_result(new_result: String):
	result = new_result
	if result == "success":
		message_container.modulate = COLOR_PERSIST_SUCCESS
	elif result == "fail":
		message_container.modulate = COLOR_PERSIST_FAIL
	else:
		message_container.modulate = COLOR_PERSIST_NEUTRAL

# Animates a dopamine flash, then settles on result color
func flash_result(duration := 0.4):
	var flash_color = COLOR_FLASH_SUCCESS
	if result == "fail":
		flash_color = COLOR_FLASH_FAIL
	elif result == "neutral":
		flash_color = COLOR_PERSIST_NEUTRAL

	var persist_color = COLOR_PERSIST_NEUTRAL
	if result == "success":
		persist_color = COLOR_PERSIST_SUCCESS
	elif result == "fail":
		persist_color = COLOR_PERSIST_FAIL

	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", flash_color, duration * 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", persist_color, duration * 0.7).set_trans(Tween.TRANS_CUBIC)


func set_reaction(emoji: Texture2D, tooltip_text: String, animate := true, name: String = ""):
	reaction_name = name
	reaction_tooltip = tooltip_text
	emoji_reaction.texture = emoji
	emoji_reaction.tooltip_text = tooltip_text
	if animate:
			animate_emoji_reaction()
	else:
			emoji_reaction.visible = true
			emoji_reaction.scale = Vector2(1, 1)

func clear_reaction():
	reaction_name = ""
	reaction_tooltip = ""
	emoji_reaction.visible = false
	emoji_reaction.tooltip_text = ""

func animate_emoji_reaction():
	emoji_reaction.visible = false
	emoji_reaction.scale = Vector2(0.1, 0.1)
	await get_tree().create_timer(0.09).timeout # optional: staggers it to match icons
	emoji_reaction.visible = true

	var tween = get_tree().create_tween()
	tween.tween_property(emoji_reaction, "scale", Vector2(1.2, 1.2), 0.12)
	tween.tween_property(emoji_reaction, "scale", Vector2(1.0, 1.0), 0.10)



func _create_stat_icon(effect_name: String, delta: int) -> VBoxContainer:
	var icon_texture: Texture2D = null
	var color = Color.WHITE
	var label_text = ""

	match effect_name:
		"chemistry":
			icon_texture = ICONS["chem_up"] if delta > 0 else ICONS["chem_down"]
			color = Color("53ee83") if delta > 0 else Color("e74c3c")
			label_text = ("%+d" % delta)
		"self_esteem":
			icon_texture = ICONS["esteem_up"] if delta > 0 else ICONS["esteem_down"]
			color = Color("e74c3c") if delta > 0 else Color("53ee83")
			label_text = ("%+d" % delta)
		"apprehension":
			icon_texture = ICONS["appre_down"] if delta < 0 else ICONS["appre_up"]
			color = Color("53ee83") if delta < 0 else Color("e74c3c")
			label_text = ("%+d" % delta)
		"confidence":
			icon_texture = ICONS["conf_up"] if delta > 0 else ICONS["conf_down"]
			color = Color("53ee83") if delta > 0 else Color("e74c3c")
			label_text = ("%+d" % delta)
		_:
			return null

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", -1)

	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(18, 18)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.tooltip_text = "%s: %s" % [effect_name.capitalize(), label_text]
	icon.scale = Vector2(0.1, 0.1)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.visible = false

	var label = Label.new()
	label.text = label_text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.custom_minimum_size = Vector2(32, 14)
	label.tooltip_text = icon.tooltip_text

	vbox.add_child(icon)
	vbox.add_child(label)
	return vbox





func set_stat_effects(effects: Dictionary, stat_order := ["chemistry", "self_esteem", "apprehension", "confidence"], animate := true):
	self.effects = effects.duplicate()
	var icons_to_animate: Array = []

	if is_npc_message:
		for child in left_effect_icons_hbox.get_children():
			child.queue_free()
		for effect_name in stat_order:
			if effect_name == "confidence" and effects.has(effect_name):
				var delta = int(effects[effect_name])
				if abs(delta) < 1:
					continue
				var vbox = _create_stat_icon(effect_name, delta)
				vbox.add_theme_constant_override("separation", -1)
				if vbox != null:
					left_effect_icons_hbox.add_child(vbox)
					icons_to_animate.append(vbox.get_child(0))
				if animate:
					await _animate_icons(icons_to_animate, true)
				else:
					_animate_icons(icons_to_animate, false)
				return

	# For player: show only non-confidence effects
	for child in effect_icons_hbox.get_children():
		child.queue_free()
	for effect_name in stat_order:
		if effect_name != "confidence" and effects.has(effect_name):
			var delta = int(effects[effect_name])
			if abs(delta) < 1:
				continue
			var vbox = _create_stat_icon(effect_name, delta)
			vbox.add_theme_constant_override("separation", -1)
			if vbox != null:
				effect_icons_hbox.add_child(vbox)
				icons_to_animate.append(vbox.get_child(0))
			if animate:
				await _animate_icons(icons_to_animate, true)
			else:
				_animate_icons(icons_to_animate, false)


func _animate_icons(icons: Array, animate := true) -> void:
		for icon in icons:
				var label = icon.get_parent().get_child(1)
				if animate:
						label.visible = false
						icon.visible = true
						icon.scale = Vector2(0.1, 0.1)
						var tween = get_tree().create_tween()
						tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.12)
						tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.10)
						await get_tree().create_timer(0.09).timeout
						label.visible = true
				else:
						icon.visible = true
						icon.scale = Vector2(1,1)
						label.visible = true

func apply_saved_state(data: Dictionary, reaction_texture: Texture2D = null) -> void:
	text = data.get("text", "")
	result = data.get("result", "neutral")
	reaction_name = data.get("reaction_name", "")
	reaction_tooltip = data.get("reaction_tooltip", "")
	effects = data.get("effects", {})
	is_victory_number = data.get("is_victory_number", false)
	text_label.text = text
	text_label.visible_ratio = 1.0
	set_result(result)
	if reaction_name != "":
		emoji_reaction.texture = reaction_texture
		emoji_reaction.tooltip_text = reaction_tooltip
		emoji_reaction.visible = true
		emoji_reaction.scale = Vector2(1,1)
	else:
		clear_reaction()
	if effects.size() > 0:
		set_stat_effects(effects, ["chemistry", "self_esteem", "apprehension", "confidence"], false)
	resolved = true
