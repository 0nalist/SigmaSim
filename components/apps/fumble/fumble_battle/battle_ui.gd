extends PanelContainer
class_name BattleUI

@export var chat_box_scene: PackedScene

@onready var profile_pic: TextureRect = %ProfilePic
@onready var attractiveness_label: Label = %AttractivenessLabel
@onready var name_label: Label = %NameLabel

@onready var npc_profile_pic: TextureRect = %NPCProfilePic
@onready var npc_attractiveness_label: Label = %NPCAttractivenessLabel
@onready var npc_name_label: Label = %NPCNameLabel

@onready var action_button_1: Button = %ActionButton1
@onready var action_button_2: Button = %ActionButton2
@onready var action_button_3: Button = %ActionButton3
@onready var action_button_4: Button = %ActionButton4

@onready var ghost_button: Button = %GhostButton
@onready var catch_button: Button = %CatchButton
@onready var inventory_button: Button = %InventoryButton

@onready var chat_container: VBoxContainer = %ChatContainer

var equipped_moves := ["RIZZ", "NEG", "FLEX", "SIMP"]
var action_buttons := []

func _ready():
	action_buttons = [action_button_1, action_button_2, action_button_3, action_button_4]
	update_action_buttons()

func update_action_buttons():
	for i in equipped_moves.size():
		action_buttons[i].text = equipped_moves[i].capitalize()
		# Disconnect any previous signals to prevent stacking
		if action_buttons[i].is_connected("pressed", Callable(self, "_on_action_button_pressed")):
			action_buttons[i].disconnect("pressed", Callable(self, "_on_action_button_pressed"))
		action_buttons[i].pressed.connect(_on_action_button_pressed.bind(i))

func _on_action_button_pressed(index):
	var move_type = equipped_moves[index]
	do_move(move_type)

func swap_move(slot_index: int, new_move: String):
	equipped_moves[slot_index] = new_move
	update_action_buttons()

func do_move(move_type: String):
	# Find all eligible player lines for this move
	move_type = move_type.to_lower()
	var options = []
	for line in RizzBattleData.player_lines:
		if line["move_type"] == move_type:
			options.append(line)
	if options.is_empty():
		print("No lines for move:", move_type)
		return

	var chosen_line = options[randi() % options.size()]

	var prefix := ""
	if chosen_line["prefixes"].size() > 0:
		prefix = chosen_line["prefixes"].pick_random() + " "

	var core = chosen_line["core"]

	var suffix := ""
	if chosen_line["suffixes"].size() > 0:
		suffix = chosen_line["suffixes"].pick_random()

	var full_line = prefix + core + suffix

	# Show in chat box
	var chat = chat_box_scene.instantiate()
	chat_container.add_child(chat)  # Or wherever your chat log goes
	chat.text_label.text = full_line

	# Handle response id for NPC reply
	process_npc_response(move_type, chosen_line.get("response_id", null), true) # Replace with success/fail logic


func process_npc_response(move_type, response_id, success: bool):
	var response_text = ""
	var key = "FALSE"
	if success:
		key = "TRUE"

	if response_id and RizzBattleData.npc_responses.has(response_id):
		var pool = RizzBattleData.npc_responses[response_id][key]
		if pool.size() > 0:
			response_text = pool.pick_random()
	elif RizzBattleData.npc_generic_responses.has(move_type):
		var pool = RizzBattleData.npc_generic_responses[move_type][key]
		if pool.size() > 0:
			response_text = pool.pick_random()
	else:
		response_text = "..."

	var chat = chat_box_scene.instantiate()
	chat_container.add_child(chat)
	chat.text_label.text = response_text

func animate_chat_text(chat_box: Control, text: String) -> void:
	# Set the text, start hidden
	var label = chat_box.text_label
	label.text = text
	label.visible_ratio = 0.0
	
	# Wait 0.5 seconds
	await get_tree().create_timer(0.5).timeout
	
	# Animation duration depends on length
	var chars = text.length()
	var duration_per_char = 0.03 # seconds per character
	var min_time = 0.4
	var max_time = 3.0
	var duration = clamp(chars * duration_per_char, min_time, max_time)
	
	var elapsed = 0.0
	while elapsed < duration:
		var ratio = elapsed / duration
		label.visible_ratio = ratio
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	label.visible_ratio = 1.0
