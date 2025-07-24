extends MarginContainer
class_name ChatBox

@onready var text_label: Label = %TextLabel
@onready var emoji_reaction: TextureRect = %EmojiReaction


@onready var effect_icons_hbox: HBoxContainer = $Control2/EffectIconsHBox

const ICONS = {
	"chem_up": preload("res://assets/emojis/testtube_emoji_x32.png"),
	"chem_down": preload("res://assets/emojis/testtube_emoji_x32.png"),
	"esteem_up": preload("res://assets/emojis/crown_emoji_x32.png"),
	"esteem_down": preload("res://assets/emojis/crown_emoji_x32.png"),
	"appre_up": preload("res://assets/emojis/grimace_emoji_x32.png"),
	"appre_down": preload("res://assets/emojis/smiley_eyes_x32.png"),
	"conf_up": preload("res://assets/emojis/sunglasses_smiley_emoji_x32.png"),
	"conf_down": preload("res://assets/emojis/peek_emoji_x32.png"),
}

@onready var message_container: PanelContainer = %MessageContainer


@onready var effect_icon_label_1: Label = %EffectIconLabel1
@onready var effect_icon_label_2: Label = %EffectIconLabel2
@onready var effect_icon_label_3: Label = %EffectIconLabel3




var text: String = ""
var result: String = "neutral" # "neutral", "success", "fail"

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
	
	emoji_reaction.size = Vector2(32, 32)
	emoji_reaction.custom_minimum_size = Vector2(32, 32)
	emoji_reaction.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)


# Call this to set the result ("success" or "fail" or "neutral") and animate flash
func set_result_and_flash(new_result: String, duration := 0.4):
	set_result(new_result)
	flash_result(duration)

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


func set_reaction(emoji: Texture2D, tooltip_text: String):
	emoji_reaction.texture = emoji
	emoji_reaction.tooltip_text = tooltip_text
	animate_emoji_reaction()

func clear_reaction():
	emoji_reaction.visible = false
	emoji_reaction.tooltip_text = ""

func animate_emoji_reaction():
	# Reset scale to tiny, make visible
	emoji_reaction.scale = Vector2(0.1, 0.1)
	emoji_reaction.visible = true

	# Create the pop tween
	var tween = get_tree().create_tween()
	tween.tween_property(emoji_reaction, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(emoji_reaction, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func set_stat_effects(effects: Dictionary, for_player: bool = true):
	# Remove all previous effect icons+labels
	for child in effect_icons_hbox.get_children():
		child.queue_free()
	
	var effect_order = []
	if for_player:
		effect_order = ["chemistry", "self_esteem", "apprehension"]
	else:
		effect_order = ["confidence"]
	
	for effect_name in effect_order:
		if effects.has(effect_name):
			var delta = int(effects[effect_name])
			var icon_texture: Texture2D = null
			var color = Color.WHITE
			var label_text = ""
			
			match effect_name:
				"chemistry":
					if delta > 0:
						icon_texture = ICONS["chem_up"]
						color = Color("53ee83") # green
					elif delta < 0:
						icon_texture = ICONS["chem_down"]
						color = Color("e74c3c") # red
					label_text = ("%+d" % delta)
				"self_esteem":
					if delta > 0:
						icon_texture = ICONS["esteem_up"]
						color = Color("e74c3c") # red (up = red)
					elif delta < 0:
						icon_texture = ICONS["esteem_down"]
						color = Color("53ee83") # green (down = green)
					label_text = ("%+d" % delta)
				"apprehension":
					if delta < 0:
						icon_texture = ICONS["appre_down"]
						color = Color("53ee83") # green (less apprehension)
					else:
						icon_texture = ICONS["appre_up"]
						color = Color("e74c3c") # red (more apprehension)
					label_text = ("%+d" % delta)
				"confidence":
					if delta > 0:
						icon_texture = ICONS["conf_up"]
						color = Color("53ee83") # green
					elif delta < 0:
						icon_texture = ICONS["conf_down"]
						color = Color("e74c3c") # red
					label_text = ("%+d" % delta)
			
			# Build the icon+label stack
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER

			var icon = TextureRect.new()
			icon.texture = icon_texture
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(32, 32)
			icon.tooltip_text = "%s: %s" % [effect_name.capitalize(), label_text]

			var label = Label.new()
			label.text = label_text
			label.modulate = color
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			label.custom_minimum_size = Vector2(32, 14)
			label.tooltip_text = icon.tooltip_text

			vbox.add_child(icon)
			vbox.add_child(label)
			effect_icons_hbox.add_child(vbox)
