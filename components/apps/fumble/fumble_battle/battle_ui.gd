extends PanelContainer
class_name BattleUI

@export var chat_box_scene: PackedScene

@export var battle_logic_resource: BattleLogic
var logic: BattleLogic

@onready var profile_pic: TextureRect = %ProfilePic
@onready var attractiveness_label: Label = %AttractivenessLabel
@onready var name_label: Label = %NameLabel

@onready var npc_type_label: Label = %NPCTypeLabel
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

@onready var confidence_progress_bar: StatProgressBar = %ConfidenceProgressBar

@onready var npc_profile_button: Button = %NPCProfileButton
@onready var profile_center_container: CenterContainer = %ProfileCenterContainer
@onready var fumble_profile: FumbleProfileUI = %FumbleProfile
@onready var close_fumble_profile_button: Button = %CloseFumbleProfileButton


@onready var chat_container: VBoxContainer = %ChatContainer

var equipped_moves := ["RIZZ", "NEG", "FLEX", "SIMP"]
var action_buttons := []

var move_usage_counts := {}  # e.g. {"rizz": 0, "neg": 2, ...}

var battle_id: String
var npc: NPC
var chatlog: Array = []
var battle_stats := {
	"self_esteem": 50,
	"chemistry": 0,
	"apprehension": 0
}

var is_animating: bool = false


const REACTION_EMOJI = {
	"heart": preload("res://assets/emojis/red_heart_emoji_x32.png"),
	"zzz": preload("res://assets/emojis/zzz_emoji_x32.png"),
	"thumbs_down": preload("res://assets/emojis/thumbsdown_emoji_x32.png")
}


func get_reaction_tooltip(reaction: String) -> String:
	match reaction:
		"heart":
			return npc.first_name + " loved this line!"
		"zzz":
			return "Success, but a different line might work better."
		"thumbs_down":
			return "This type of line is not happening with " + npc.first_name
		_:
			return ""



func _ready():
	action_buttons = [action_button_1, action_button_2, action_button_3, action_button_4]
	
	
	catch_button.pressed.connect(_on_catch_button_pressed)
	ghost_button.pressed.connect(_on_ghost_button_pressed)
	
	profile_center_container.hide()
	npc_profile_button.pressed.connect(_on_npc_profile_button_pressed)
	close_fumble_profile_button.pressed.connect(_on_close_fumble_profile_button_pressed)

func load_battle(new_battle_id: String, new_npc: NPC, chatlog_in: Array = [], stats_in: Dictionary = {}):
	battle_id = new_battle_id
	npc = new_npc
	chatlog = chatlog_in.duplicate() if chatlog_in.size() > 0 else []

	# If stats_in is empty, pull stats from npc resource
	var battle_stats_to_use: Dictionary = {}
	if stats_in.size() > 0:
		battle_stats_to_use = stats_in.duplicate()
	else:
		battle_stats_to_use = {
			"self_esteem": npc.self_esteem,
			"chemistry": npc.chemistry,
			"apprehension": npc.apprehension
		}
	
	# Set up logic
	if battle_logic_resource:
		logic = battle_logic_resource.duplicate()
	else:
		logic = BattleLogic.new()
	logic.setup(npc, battle_stats_to_use)
	battle_stats = logic.get_stats()

	_update_profiles()
	for child in chat_container.get_children():
		child.queue_free()
	for msg in chatlog:
		add_chat_line(msg.text, msg.is_player)
	
	move_usage_counts.clear()
	for move in equipped_moves:
		move_usage_counts[move.to_lower()] = 0
	move_usage_counts["catch"] = 0
	
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
	animate_progress_bar(chemistry_progress_bar,     battle_stats.get("chemistry", 0))
	animate_progress_bar(self_esteem_progress_bar,   battle_stats.get("self_esteem", 0))
	animate_progress_bar(apprehension_progress_bar,  battle_stats.get("apprehension", 0))
	animate_progress_bar(confidence_progress_bar,    PlayerManager.get_stat("confidence"))

func clamp100(val: float) -> float:
	return clamp(val, 0, 100)

func animate_progress_bar(bar: ProgressBar, target_value: float, duration: float = 0.35):
	target_value = clamp100(target_value)
	var tween = get_tree().create_tween()
	tween.tween_property(bar, "value", target_value, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)



func _update_profiles():
	# === Player info ===
	var pic_path = PlayerManager.get_var("profile_picture_path", "")
	if pic_path != "":
		var img = load(pic_path)
		if img is Texture2D:
			profile_pic.texture = img
		else:
			profile_pic.texture = preload("res://assets/prof_pics/silhouette.png")
	else:
		profile_pic.texture = preload("res://assets/prof_pics/silhouette.png")

	attractiveness_label.text = "🔥 %.1f/10" % (float(PlayerManager.get_stat("attractiveness")) / 10.0)
	name_label.text = PlayerManager.get_var("name", "You")
	
	# NPC info
	npc_profile_pic.texture = npc.profile_pic if npc.profile_pic else preload("res://assets/prof_pics/silhouette.png")
	npc_attractiveness_label.text = "🔥 %.1f/10" % (float(npc.attractiveness) / 10.0)
	npc_name_label.text = npc.full_name
	npc_type_label.text = npc.chat_battle_type



func update_action_buttons():
	if logic == null:
		return

	for i in equipped_moves.size():
		var move_type = equipped_moves[i].to_lower()
		var use_count = move_usage_counts.get(move_type, 0)

		var label_base = equipped_moves[i].to_upper() + "\n"

		if use_count >= 3:
			var chance := logic.get_success_chance(move_type)
			var chance_percent = round(chance * 100.0)
			label_base += str(chance_percent) + "%"
		else:
			var mystery := String("?").repeat(3 - use_count)
			label_base += mystery

		action_buttons[i].text = label_base

		# Prevent signal stacking
		if action_buttons[i].is_connected("pressed", Callable(self, "_on_action_button_pressed")):
			action_buttons[i].disconnect("pressed", Callable(self, "_on_action_button_pressed"))
		action_buttons[i].pressed.connect(_on_action_button_pressed.bind(i))
	
	# === Catch button logic ===
	var catch_uses = move_usage_counts.get("catch", 0)
	var label_base = "CATCH\n"
	if catch_uses >= 3:
		var catch_chance = logic.get_success_chance("catch")
		label_base += str(round(catch_chance * 100.0)) + "%"
	else:
		var mystery := String("?").repeat(3 - catch_uses)
		label_base += mystery
	catch_button.text = label_base


func _on_action_button_pressed(index):
	if is_animating:
		return
	var move_type = equipped_moves[index]
	await do_move(move_type)

func _on_catch_button_pressed():
	if is_animating:
		return
	await do_move("catch")

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


func do_move(move_type: String) -> void:
	is_animating = true
	PlayerManager.suppress_stat("confidence", true)
	
	move_type = move_type.to_lower()
	
	if move_usage_counts.has(move_type):
		move_usage_counts[move_type] += 1
	update_action_buttons()

	# Player line logic
	var options = []
	for line in RizzBattleData.player_lines:
		if line["move_type"] == move_type:
			options.append(line)
	if options.is_empty():
		print("No lines for move:", move_type)
		is_animating = false
		return

	var chosen_line = options[randi() % options.size()]
	var prefix := ""
	if chosen_line["prefixes"].size() > 0:
		prefix = chosen_line["prefixes"].pick_random()
	var core = chosen_line["core"]
	var suffix := ""
	if chosen_line["suffixes"].size() > 0:
		suffix = chosen_line["suffixes"].pick_random()
	var full_line = prefix + core + suffix

	# Animate player line
	var chat = add_chat_line(full_line, true)
	chat.clear_reaction()
	await animate_chat_text(chat, full_line)
	await get_tree().create_timer(0.5).timeout

	# ---- resolve move with battle logic! ----

	var result = logic.resolve_move(move_type)
	_apply_effects(result.effects)

	

	
	
	var npc_chat: ChatBox = await process_npc_response(move_type, chosen_line.get("response_id", null), result.success)
	await get_tree().create_timer(.69).timeout
	

	var use_count = move_usage_counts.get(move_type, 0)
	var reaction = result.get("reaction", "")
	if result.success:
		# Only show heart/zzz on success
		if reaction == "heart" or reaction == "zzz":
			chat.set_reaction(
				REACTION_EMOJI[reaction],
				get_reaction_tooltip(reaction)
			)
		else:
			chat.clear_reaction()
	elif use_count >= 3 and reaction == "thumbs_down":
		# Show thumbs_down for immune moves only after ??? is cleared
		chat.set_reaction(
			REACTION_EMOJI["thumbs_down"],
			get_reaction_tooltip("thumbs_down")
		)
	else:
		chat.clear_reaction()
	
	await get_tree().create_timer(0.25).timeout
	
	# Animate effects/progress, etc.
	animate_success_or_fail(result.success)
	await update_progress_bars()
	
	chat.set_stat_effects(result.effects)
	
	if result.effects.has("confidence"):
		print("confidence changed")
		npc_chat.set_stat_effects({"confidence": result.effects.confidence}, ["confidence"])
	
	# SPECIAL LOGIC FOR CATCH
	if move_type == "catch":
		if result.success:
			# Add NPC's number as a new message
			var number_msg = "Here’s my number: %s" % str(NPCFactory.djb2(npc.full_name))
			var chat2 = add_chat_line(number_msg, false)
			await animate_chat_text(chat2, number_msg)
			end_battle(true)
			
		else:
			# Player loses confidence, NPC becomes more apprehensive
			PlayerManager.adjust_stat("confidence", -10)
			battle_stats["apprehension"] = clamp(battle_stats.get("apprehension", 0) + 7, 0, 100)
			# Optionally animate/apply any feedback here too
	
	
	
	is_animating = false
	PlayerManager.suppress_stat("confidence", false)

func end_battle(success: bool) -> void:
	pass
	#gain experience


func animate_success_or_fail(success: bool):
	var player_result = "success"
	var npc_result = "success"
	if not success:
		player_result = "fail"
		npc_result = "fail"

	var last_player_chat: ChatBox = null
	var last_npc_chat: ChatBox = null

	# Find last player and npc chat
	for i in range(chat_container.get_child_count() - 1, -1, -1):
		var hbox = chat_container.get_child(i)
		if hbox.get_child_count() >= 2:
			var left = hbox.get_child(0)
			var right = hbox.get_child(1)
			if left is ChatBox and last_player_chat == null:
				last_player_chat = left
			if right is ChatBox and last_npc_chat == null:
				last_npc_chat = right
		else:
			var chat = hbox.get_child(0)
			if chat is ChatBox:
				if last_player_chat == null:
					last_player_chat = chat
				elif last_npc_chat == null:
					last_npc_chat = chat
		if last_player_chat and last_npc_chat:
			break

	if last_player_chat:
		last_player_chat.set_result_and_flash(player_result)
	if last_npc_chat:
		last_npc_chat.set_result_and_flash(npc_result)



func _on_npc_profile_button_pressed():
	profile_center_container.show()
	fumble_profile.load_npc(npc)


func _on_close_fumble_profile_button_pressed():
	profile_center_container.hide()






func _apply_effects(effects: Dictionary):
	for stat in effects.keys():
		if battle_stats.has(stat):
			battle_stats[stat] = clamp100(battle_stats[stat] + effects[stat])
	# player stats (like confidence) handled by PlayerManager


func process_npc_response(move_type, response_id, success: bool) -> ChatBox:

	var response_text = ""
	var key = "FALSE"
	if success:
		key = "TRUE"
	var entry = null
	if response_id and RizzBattleData.npc_responses.has(response_id):
		var pool = RizzBattleData.npc_responses[response_id][key]
		if pool.size() > 0:
			entry = pool.pick_random()
	elif RizzBattleData.npc_generic_responses.has(move_type):
		var pool = RizzBattleData.npc_generic_responses[move_type][key]
		if pool.size() > 0 and typeof(pool[0]) == TYPE_DICTIONARY:
			entry = pool.pick_random()
	if entry != null:
		var prefix = ""
		var suffix = ""
		if entry.has("response_prefix") and entry.response_prefix is Array and entry.response_prefix.size() > 0:
			prefix = entry.response_prefix.pick_random()
		if entry.has("response_suffix") and entry.response_suffix is Array and entry.response_suffix.size() > 0:
			suffix = entry.response_suffix.pick_random()
		response_text = str(prefix) + str(entry.response_line) + str(suffix)
	else:
		if RizzBattleData.npc_generic_responses.has(move_type):
			var pool = RizzBattleData.npc_generic_responses[move_type][key]
			if pool.size() > 0 and typeof(pool[0]) == TYPE_STRING:
				response_text = pool.pick_random()
			else:
				response_text = "..."
		else:
			response_text = "..."
	
	var chat = add_chat_line(response_text, false)
	await animate_chat_text(chat, response_text)
	update_action_buttons()
	return chat


func persist_battle_stats_to_npc():
	if npc and logic:
		var current_stats = logic.get_stats()
		npc.self_esteem = current_stats.get("self_esteem", npc.self_esteem)
		npc.chemistry = current_stats.get("chemistry", npc.chemistry)
		npc.apprehension = current_stats.get("apprehension", npc.apprehension)




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
		# Scroll every frame while animating!
		scroll_to_newest_chat()
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	label.visible_ratio = 1.0
	scroll_to_newest_chat()
