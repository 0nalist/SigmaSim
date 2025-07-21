extends MarginContainer
class_name ChatBox

@onready var text_label: Label = %TextLabel

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

# Call this to set the result ("success" or "fail" or "neutral") and animate flash
func set_result_and_flash(new_result: String, duration := 0.4):
	set_result(new_result)
	flash_result(duration)

# Just sets the persistent color, does NOT animate
func set_result(new_result: String):
	result = new_result
	if result == "success":
		modulate = COLOR_PERSIST_SUCCESS
	elif result == "fail":
		modulate = COLOR_PERSIST_FAIL
	else:
		modulate = COLOR_PERSIST_NEUTRAL

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
