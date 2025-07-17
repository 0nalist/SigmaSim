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

@onready var chemistry_progress_bar: ProgressBar = %ChemistryProgressBar
@onready var self_esteem_progress_bar: ProgressBar = %SelfEsteemProgressBar
@onready var apprehension_progress_bar: ProgressBar = %ApprehensionProgressBar

@onready var confidence_progress_bar: ProgressBar = %ConfidenceProgressBar

@onready var chat_container: VBoxContainer = %ChatContainer

var equipped_moves := ["RIZZ", "NEG", "FLEX", "SIMP"]
var action_buttons := []

var battle_id: String
var npc: NPC
var chatlog: Array = []
var battle_stats := {
	"self_esteem": 50,
	"chemistry": 0,
	"apprehension": 0
}

var is_animating: bool = false


func _ready():
	action_buttons = [action_button_1, action_button_2, action_button_3, action_button_4]
	update_action_buttons()
	
	catch_button.pressed.connect(_on_catch_button_pressed)
	ghost_button.pressed.connect(_on_ghost_button_pressed)


func load_battle(new_battle_id: String, new_npc: NPC, chatlog_in: Array = [], stats_in: Dictionary = {}):
	battle_id = new_battle_id
	npc = new_npc
	chatlog = chatlog_in.duplicate() if chatlog_in.size() > 0 else []
	
	# Load stats (or use default values)
	for stat in battle_stats.keys():
		if stats_in.has(stat):
			battle_stats[stat] = stats_in[stat]
	
	# Set up UI for player and npc
	_update_profiles()
	
	# Rebuild chatlog in UI if provided
	for child in chat_container.get_children():
		child.queue_free()
	for msg in chatlog:
		# msg = {text: "hello", is_player: true/false}
		add_chat_line(msg.text, msg.is_player)
	update_action_buttons()
	scroll_to_newest_chat()
	update_progress_bars()

func scroll_to_newest_chat():
	var scroll = chat_container.get_parent()
	if scroll is ScrollContainer:
		# Let the tree process so the new child is visible
		await get_tree().process_frame
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func update_progress_bars():
	chemistry_progress_bar.value     = battle_stats.get("chemistry", 0)
	self_esteem_progress_bar.value   = battle_stats.get("self_esteem", 0)
	apprehension_progress_bar.value  = battle_stats.get("apprehension", 0)
	# Example for player confidence (set appropriately)
	confidence_progress_bar.value    = battle_stats.get("confidence", 50)

func _update_profiles():
	# Player info (if needed)
	# profile_pic.texture = ... (set if you want, or leave blank for now)
	# attractiveness_label.text = ...
	# name_label.text = ...
	
	# NPC info
	npc_profile_pic.texture = npc.profile_pic if npc.profile_pic else preload("res://assets/prof_pics/silhouette.png")
	npc_attractiveness_label.text = "❤️ %.1f/10" % (float(npc.attractiveness) / 10.0)
	npc_name_label.text = npc.full_name



func update_action_buttons():
	for i in equipped_moves.size():
		action_buttons[i].text = equipped_moves[i].capitalize()
		# Disconnect any previous signals to prevent stacking
		if action_buttons[i].is_connected("pressed", Callable(self, "_on_action_button_pressed")):
			action_buttons[i].disconnect("pressed", Callable(self, "_on_action_button_pressed"))
		action_buttons[i].pressed.connect(_on_action_button_pressed.bind(i))
	

func _on_action_button_pressed(index):
	if is_animating:
		return
	var move_type = equipped_moves[index]
	do_move(move_type)

func _on_catch_button_pressed():
	if is_animating:
		return
	do_move("catch")

func _on_ghost_button_pressed():
	if is_animating:
		return
	var chat = add_chat_line("*ghosts*", true)
	await animate_chat_text(chat, "*ghosts*")
	await get_tree().create_timer(0.69).timeout
	queue_free()


func swap_move(slot_index: int, new_move: String):
	equipped_moves[slot_index] = new_move
	update_action_buttons()

# Helper function to add a chat line in a proper HBox (left for player, right for NPC)
func add_chat_line(text: String, is_player: bool) -> Control:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var chat := chat_box_scene.instantiate()

	if is_player:
		hbox.add_child(chat)
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
	else:
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		hbox.add_child(chat)

	chat_container.add_child(hbox)
	# Now chat is in the tree, onready properties are valid!
	chat.text_label.text = text
	chat.text_label.visible_ratio = 0.0
	scroll_to_newest_chat()
	return chat


func do_move(move_type: String):
	if is_animating:
		return
	is_animating = true
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
		prefix = chosen_line["prefixes"].pick_random() #+ " "
	var core = chosen_line["core"]
	var suffix := ""
	if chosen_line["suffixes"].size() > 0:
		suffix = chosen_line["suffixes"].pick_random()
	var full_line = prefix + core + suffix

	# Add player chat to left and animate
	var chat = add_chat_line(full_line, true)
	await animate_chat_text(chat, full_line)

	await get_tree().create_timer(0.5).timeout

	await process_npc_response(move_type, chosen_line.get("response_id", null), true) # Replace with success/fail logic
	is_animating = false

func process_npc_response(move_type, response_id, success: bool):
	var response_text = ""
	var key = "FALSE"
	if success:
		key = "TRUE"
	if response_id and RizzBattleData.npc_responses.has(response_id):
		var pool = RizzBattleData.npc_responses[response_id][key]
		if pool.size() > 0:
			var entry = pool.pick_random()
			response_text = entry.response_line
			# Optionally, add suffix:
			if entry.has("response_suffix") and entry.response_suffix.size() > 0:
				# Pick one at random if you want to use it
				response_text += entry.response_suffix.pick_random()
	elif RizzBattleData.npc_generic_responses.has(move_type):
		var pool = RizzBattleData.npc_generic_responses[move_type][key]
		if pool.size() > 0:
			# For generic responses, assuming pool is a list of strings:
			if typeof(pool[0]) == TYPE_DICTIONARY:
				var entry = pool.pick_random()
				response_text = entry.response_line
				if entry.has("response_suffix") and entry.response_suffix.size() > 0:
					response_text += entry.response_suffix.pick_random()
			else:
				response_text = pool.pick_random()
	else:
		response_text = "..."

	# NPC chat (right aligned)
	var chat = add_chat_line(response_text, false)
	await animate_chat_text(chat, response_text)


func animate_chat_text(chat_box: Control, text: String) -> void:
	var label = chat_box.text_label
	label.text = text
	label.visible_ratio = 0.0
	
	await get_tree().create_timer(0.5).timeout
	
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
