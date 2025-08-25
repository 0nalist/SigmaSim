extends PanelContainer
class_name BattleUI

signal chat_closed

@export var chat_box_scene: PackedScene
@export var victory_number_chat_box_scene: PackedScene
@export var battle_logic_resource: BattleLogic
var logic: BattleLogic

@onready var end_battle_screen_container: CenterContainer = %EndBattleScreenContainer
@onready var blocked_container: PanelContainer = %BlockedContainer

var victorious: bool = false
var blocked: bool = false
var block_warning_active: bool = false


@onready var profile_pic: PortraitView = %ProfilePic
@onready var attractiveness_label: Label = %AttractivenessLabel
@onready var name_label: Label = %NameLabel

@onready var npc_type_label: Label = %NPCTypeLabel
@onready var npc_portrait: PortraitView = %NPCProfilePic
@onready var npc_attractiveness_label: Label = %NPCAttractivenessLabel
@onready var npc_name_label: Label = %NPCNameLabel

@onready var action_button_1: ChatBattleActionButton = %ActionButton1
@onready var action_button_2: ChatBattleActionButton = %ActionButton2
@onready var action_button_3: ChatBattleActionButton = %ActionButton3
@onready var action_button_4: ChatBattleActionButton = %ActionButton4

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

@onready var no_confidence_container: PanelContainer = %NoConfidenceContainer



@onready var chat_container: VBoxContainer = %ChatContainer

var equipped_moves := ["RIZZ", "NEG", "FLEX", "SIMP"]
var action_buttons := []

var move_usage_counts := {}  # e.g. {"rizz": 0, "neg": 2, ...}

var battle_id: String
var npc: NPC
var npc_idx: int = -1
var chatlog: Array = []
var battle_stats := {
	"self_esteem": 50,
	"chemistry": 0,
	"apprehension": 0
}

var is_animating: bool = false

var auto_timer: Timer


const REACTION_EMOJI = {
	"heart": preload("res://assets/emojis/red_heart_emoji_x32.png"),
	"zzz": preload("res://assets/emojis/zzz_emoji_x32.png"),
	"thumbs_down": preload("res://assets/emojis/thumbsdown_emoji_x32.png"),
	"cry_laugh": preload("res://assets/emojis/cry_laughing_twemoji_x32_1f602.png"),
}


func shake_player_portrait(amount: float) -> void:
		TraumaManager.hit_item(profile_pic, amount)


func shake_npc_portrait(amount: float) -> void:
		TraumaManager.hit_item(npc_portrait, amount)


func get_reaction_tooltip(reaction: String) -> String:
	match reaction:
		"heart":
			return npc.first_name + " loved this line!"
		"zzz":
			return "Success, but a different line might work better."
		"thumbs_down":
			return "This type of line is not happening with " + npc.first_name
		"cry_laugh":
			return npc.first_name + " thought this was funny, but not enough to respond."
		
		_:
			return ""



func _ready():
	action_buttons = [action_button_1, action_button_2, action_button_3, action_button_4]
	for btn in action_buttons:
			btn.action_pressed.connect(_on_action_button_pressed)

	catch_button.pressed.connect(_on_catch_button_pressed)
	ghost_button.pressed.connect(_on_ghost_button_pressed)
	
	profile_center_container.hide()
	npc_profile_button.pressed.connect(_on_npc_profile_button_pressed)
	close_fumble_profile_button.pressed.connect(_on_close_fumble_profile_button_pressed)

	end_battle_screen_container.hide()
	blocked_container.hide()

	StatManager.connect_to_stat("dime_status", self, "_on_dime_status_changed")
	StatManager.connect_to_stat("confidence", self, "_on_confidence_changed")
	_update_player_attractiveness_label()

	auto_timer = Timer.new()
	auto_timer.wait_time = 0.1
	auto_timer.one_shot = false
	auto_timer.autostart = true
	add_child(auto_timer)
	auto_timer.timeout.connect(_on_auto_timer_timeout)

	no_confidence_container.hide()

	# Register portraits with TraumaManager so they can shake when hit.
	TraumaManager.register_item(profile_pic)
	TraumaManager.register_item(npc_portrait)
	

func load_battle(new_battle_id: String, new_npc: NPC, chatlog_in: Array = [], stats_in: Dictionary = {}, move_usage_counts_in: Dictionary = {}, new_npc_idx: int = -1, outcome: String = "active"):
	battle_id = new_battle_id
	npc = new_npc
	npc_idx = new_npc_idx
	if outcome == "victory":
		victorious = true
	elif outcome == "blocked":
		blocked = true
	if chatlog_in.size() == 0 and stats_in.size() == 0 and move_usage_counts_in.size() == 0:
			var data = FumbleManager.load_battle_state(battle_id)
			if data.size() > 0:
					chatlog = data.chatlog
					stats_in = data.stats
					move_usage_counts_in = data.get("move_usage_counts", {})
	chatlog = chatlog_in.duplicate() if chatlog_in.size() > 0 else chatlog

	var is_new_battle := chatlog.size() == 0 and stats_in.size() == 0 and move_usage_counts_in.size() == 0

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
			var chat = add_chat_line(msg.text, msg.is_player, msg.get("is_victory_number", false), false)
			var reaction_tex: Texture2D = null
			if msg.get("reaction_name", "") != "" and REACTION_EMOJI.has(msg.reaction_name):
					reaction_tex = REACTION_EMOJI[msg.reaction_name]
			chat.apply_saved_state(msg, reaction_tex)

	move_usage_counts.clear()
	var move_counts_to_use: Dictionary = {}
	if move_usage_counts_in.size() > 0:
			move_counts_to_use = move_usage_counts_in.duplicate()
	for move in equipped_moves:
			move_usage_counts[move.to_lower()] = move_counts_to_use.get(move.to_lower(), 0)
	move_usage_counts["catch"] = move_counts_to_use.get("catch", 0)
	if chatlog.size() == 0 and move_counts_to_use.size() == 0:
			var reveal_levels = UpgradeManager.get_level("fumble_speaking_from_experience")
			var rng = RNGManager.fumble_battle_ui.get_rng()
			for i in range(reveal_levels):
					var options := []
					for m in equipped_moves:
							var key = m.to_lower()
							if move_usage_counts[key] < 3:
									options.append(key)
					if options.is_empty():
							break
					var chosen_key = options[rng.randi_range(0, options.size() - 1)]
					move_usage_counts[chosen_key] += 1

	update_action_buttons()
	scroll_to_newest_chat()
	update_progress_bars()

	if victorious:
		ex_award = npc.attractiveness / 10.0
		victory_ex_label.text = "You earned " + str(ex_award) + " Ex"
		end_battle_screen_container.show()
		_disable_all_action_buttons()
	elif blocked:
		blocked_container.show()
		_disable_all_action_buttons()
		ghost_button.disabled = false
		ghost_button.text = "bye forever!"
		_on_confidence_changed(StatManager.get_stat("confidence"))
	
	if is_new_battle and UpgradeManager.get_level("fumble_friend_pic") > 0:
		await get_tree().create_timer(.6).timeout
		battle_stats_to_use["apprehension"] = clamp(battle_stats_to_use.get("apprehension", 0) - 10, 0, 100)



func scroll_to_newest_chat():
	var scroll = chat_container.get_parent()
	if scroll is ScrollContainer:
		# Let the tree process so the new child is visible
		await get_tree().process_frame
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func update_progress_bars():
		animate_progress_bar(chemistry_progress_bar,  battle_stats.get("chemistry", 0))
		animate_progress_bar(self_esteem_progress_bar,battle_stats.get("self_esteem", 0))
		animate_progress_bar(apprehension_progress_bar,  battle_stats.get("apprehension", 0))
		confidence_progress_bar.update_value(StatManager.get_stat("confidence"))

func clamp100(val: float) -> float:
	return clamp(val, 0, 100)

func animate_progress_bar(bar: ProgressBar, target_value: float, duration: float = 0.35):
	target_value = clamp100(target_value)
	var tween = get_tree().create_tween()
	tween.tween_property(bar, "value", target_value, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)



func _update_profiles():
	# === Player info ===
	var portrait_dict = PlayerManager.get_var("portrait_config", {})
	if portrait_dict is Dictionary:
			var cfg = PortraitConfig.from_dict(portrait_dict)
			profile_pic.apply_config(cfg)

	_update_player_attractiveness_label()
	name_label.text = PlayerManager.get_var("name", "You")
	
	# NPC info
	if npc.portrait_config != null:
			npc_portrait.apply_config(npc.portrait_config)
	npc_attractiveness_label.text = "🔥 %.1f/10" % (float(npc.attractiveness) / 10.0)
	npc_name_label.text = npc.full_name
	npc_type_label.text = npc.chat_battle_type


func _on_dime_status_changed(_value: float) -> void:
		_update_player_attractiveness_label()

func _on_confidence_changed(value: float) -> void:
        if blocked or victorious:
                        return
        var disable := value <= 0.0
        for btn in action_buttons:
                        btn.disabled = disable
        catch_button.disabled = disable
        inventory_button.disabled = disable
        no_confidence_container.visible = disable
        if disable:
                _reset_auto_checkboxes()


func _update_player_attractiveness_label() -> void:
	await get_tree().process_frame
	attractiveness_label.text = "🔥 %.1f/10" % float(StatManager.get_stat("dime_status"))


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

			var action := ChatBattleAction.new()
			action.name = equipped_moves[i]
			action_buttons[i].load_action(action, label_base)

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


func _on_action_button_pressed(action: ChatBattleAction) -> void:
		if is_animating:
				return
		await do_move(action.name)

func _on_catch_button_pressed():
	if is_animating:
		return
	await do_move("catch")

func _on_ghost_button_pressed():
	if is_animating:
			return
	if blocked:
		FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "blocked")
		DBManager.save_fumble_relationship(npc_idx, FumbleManager.FumbleStatus.BLOCKED_PLAYER)
		persist_battle_stats_to_npc()
		queue_free()
		return
	var chat = add_chat_line("*ghosts*", true)
	await animate_chat_text(chat, "*ghosts*")
	await get_tree().create_timer(0.69).timeout
	FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "ghosted")
	DBManager.save_fumble_relationship(npc_idx, FumbleManager.FumbleStatus.ACTIVE_CHAT)
	persist_battle_stats_to_npc()
	chat_closed.emit()
	queue_free()


func _on_auto_timer_timeout() -> void:
		if is_animating:
				return
		var options: Array = []
		for btn in action_buttons:
				if btn.is_auto_selected():
						options.append(btn.action)
		if options.is_empty():
				return
		var rng = RNGManager.fumble_battle_ui.get_rng()
		var action = options[rng.randi_range(0, options.size() - 1)]
		await do_move(action.name)



func swap_move(slot_index: int, new_move: String):
	equipped_moves[slot_index] = new_move
	update_action_buttons()

# Helper function to add a chat line in a proper HBox (left for player, right for NPC)
func add_chat_line(text: String, is_player: bool, is_victory_number := false, record := true) -> Control:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var chat
	if is_victory_number:
		chat = victory_number_chat_box_scene.instantiate()
	else:
		chat = chat_box_scene.instantiate()

	chat.is_npc_message = not is_player

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
	chat.text_label.text = text
	chat.text_label.visible_ratio = 0.0
	scroll_to_newest_chat()
	if record:
		var entry = {
			"text": text,
			"is_player": is_player,
			"result": "neutral",
			"reaction_name": "",
			"reaction_tooltip": "",
			"effects": {},
			"is_victory_number": is_victory_number
		}
		chatlog.append(entry)
		chat.chatlog_index = chatlog.size() - 1
		FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")
	else:
			chat.chatlog_index = -1
	return chat

func do_move(move_type: String) -> void:
	is_animating = true

	move_type = move_type.to_lower()
	if move_usage_counts.has(move_type):
		move_usage_counts[move_type] += 1
	update_action_buttons()

	# --- Choose player's line ---
	var options = []
	for line in RizzBattleData.player_lines:
		if line["move_type"] == move_type:
			options.append(line)
	if options.is_empty():
		print("No lines for move:", move_type)
		is_animating = false
		return

	var rng = RNGManager.fumble_battle_ui.get_rng()
	var chosen_line = options[rng.randi() % options.size()]
	var prefix := ""
	if chosen_line["prefixes"].size() > 0:
		var pref_arr = chosen_line["prefixes"]
		prefix = pref_arr[rng.randi() % pref_arr.size()]
	var core = chosen_line["core"]
	var suffix := ""
	if chosen_line["suffixes"].size() > 0:
		var suf_arr = chosen_line["suffixes"]
		suffix = suf_arr[rng.randi() % suf_arr.size()]
	var full_line = prefix + core + suffix

	# --- Animate player line ---
	var player_chat: ChatBox = add_chat_line(full_line, true)
	player_chat.clear_reaction()
	await animate_chat_text(player_chat, full_line)
	await get_tree().create_timer(0.5).timeout

	# Edge case response if number already given
	if victorious:
		var response_text = "You already have my number, text me!"
		var chat = add_chat_line(response_text, false)
		await animate_chat_text(chat, response_text)
		update_action_buttons()
		return

	# --- Resolve move ---
	var result = logic.resolve_move(move_type)
	var use_count = move_usage_counts.get(move_type, 0)
	var reaction = result.get("reaction", "")
	var filtered_effects = result.effects.duplicate()

	# Special case: "haha" = skip NPC reply and confidence, show player only
	if result.success and reaction == "haha" and move_type != "catch":
		player_chat.set_reaction(
			REACTION_EMOJI["cry_laugh"],
			get_reaction_tooltip("cry_laugh"),
			false,
			"cry_laugh"
		)
		if player_chat.chatlog_index >= 0 and player_chat.chatlog_index < chatlog.size():
			var entry = chatlog[player_chat.chatlog_index]
			entry.reaction_name = "cry_laugh"
			entry.reaction_tooltip = get_reaction_tooltip("cry_laugh")
			FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")
		filtered_effects.erase("confidence")
		await get_tree().create_timer(0.25).timeout
		await player_chat.set_stat_effects(filtered_effects)
		await player_chat.reveal_result_color("success")
		TraumaManager.hit_pane(npc_portrait, 0.6)
		battle_stats = logic.get_stats().duplicate()
		await update_progress_bars()
		FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")
		is_animating = false
		return

	# Handle other reactions
	if result.success and reaction == "heart":
		player_chat.set_reaction(
			REACTION_EMOJI["heart"],
			get_reaction_tooltip("heart"),
			false,
			"heart"
		)
		if player_chat.chatlog_index >= 0 and player_chat.chatlog_index < chatlog.size():
			var entry = chatlog[player_chat.chatlog_index]
			entry.reaction_name = "heart"
			entry.reaction_tooltip = get_reaction_tooltip("heart")
			FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")
	elif not result.success and use_count >= 3 and reaction == "thumbs_down":
		player_chat.set_reaction(
			REACTION_EMOJI["thumbs_down"],
			get_reaction_tooltip("thumbs_down"),
			false,
			"thumbs_down"
		)
		if player_chat.chatlog_index >= 0 and player_chat.chatlog_index < chatlog.size():
			var entry2 = chatlog[player_chat.chatlog_index]
			entry2.reaction_name = "thumbs_down"
			entry2.reaction_tooltip = get_reaction_tooltip("thumbs_down")
			FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")
	else:
		player_chat.clear_reaction()
		if player_chat.chatlog_index >= 0 and player_chat.chatlog_index < chatlog.size():
			chatlog[player_chat.chatlog_index].reaction_name = ""
			chatlog[player_chat.chatlog_index].reaction_tooltip = ""
			FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")

	await get_tree().create_timer(0.25).timeout

	# Prepare for NPC reply
	var npc_chat: ChatBox = null
	if not (result.success and reaction == "haha" and move_type != "catch"):
		npc_chat = await process_npc_response(move_type, chosen_line.get("response_id", null), result.success)

	# Reveal icons and flash color
	var player_result = "fail"
	if result.success:
		player_result = "success"
	var npc_result = player_result

	await _reveal_chat_effects_and_results(
		player_chat,
		player_result,
		npc_chat,
		npc_result,
		result.effects,
		result.effects
	)

	# Update UI bars
	battle_stats = logic.get_stats().duplicate()
	await update_progress_bars()
	FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")

	# Special logic for catch
	if move_type == "catch":
		if result.success:
			var raw_number = str(NPCFactory.djb2(npc.full_name))
			var number_msg = "Here’s my number: [url=number][u]%s[/u][/url]" % raw_number
			var chat2: VictoryNumberChatBox = add_victory_number_chat_line(number_msg)
			if chat2.has_signal("victory_number_clicked"):
				chat2.victory_number_clicked.connect(_on_victory_number_clicked)
			await animate_chat_text(chat2, number_msg)
			victorious = true
			var increased_conf = clamp(StatManager.get_stat("confidence") + 1 + npc.attractiveness / 10.0, 0.0, 100.0)
			StatManager.set_base_stat("confidence", increased_conf)
		else:
			var decreased_conf = clamp(StatManager.get_stat("confidence") - 10.0, 0.0, 100.0)
			StatManager.set_base_stat("confidence", decreased_conf)
		battle_stats["apprehension"] = clamp(battle_stats.get("apprehension", 0) + 7, 0, 100)

	if block_warning_active:
		if not result.success:
			await block_player()
			return
		block_warning_active = false

	if battle_stats.get("apprehension", 0) >= 90 and not result.success:
		var warning_text = RizzBattleData.get_random_block_warning()
		if warning_text != "":
			var warning_chat: ChatBox = add_chat_line(warning_text, false)
			await animate_chat_text(warning_chat, warning_text)
			update_action_buttons()
		block_warning_active = true

	is_animating = false


func add_victory_number_chat_line(text: String) -> VictoryNumberChatBox:
	return add_chat_line(text, false, true, true) as VictoryNumberChatBox

func block_player() -> void:
	blocked = true
	blocked_container.show()
	end_battle(false, npc)
	FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "blocked")
	DBManager.save_fumble_relationship(npc_idx, FumbleManager.FumbleStatus.BLOCKED_PLAYER)
	persist_battle_stats_to_npc()
	await get_tree().create_timer(0.69).timeout
	chat_closed.emit()
	queue_free()

func _on_victory_number_clicked() -> void:
	show_victory_screen()

@onready var victory_name_label: Label = %VictoryNameLabel


@onready var victory_ex_label: Label = %VictoryExLabel
@onready var victory_confidence_label: Label = %VictoryConfidenceLabel
var ex_award: float
var confidence_award: float = 25.0

func show_victory_screen():
        _reset_auto_checkboxes()
        ex_award = npc.attractiveness / 100.0
        victory_ex_label.text = "You earned " + str(ex_award) + " Ex"
        victory_confidence_label.text = "Confidence +" + str(confidence_award)
        victory_name_label.text = npc.first_name + " has been added to"
        end_battle_screen_container.show()
        end_battle(victorious, npc)
        FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "victory")
        DBManager.save_fumble_relationship(npc_idx, FumbleManager.FumbleStatus.LIKED)
        persist_battle_stats_to_npc()

func end_battle(success: bool, npc: NPC) -> void:
	# Lock out further player interaction
	_disable_all_action_buttons()

	if success:
		StatManager.set_base_stat("ex", StatManager.get_stat("ex") + ex_award)
		var new_conf = clamp(StatManager.get_stat("confidence") + confidence_award, 0.0, 100.0)
		StatManager.set_base_stat("confidence", new_conf)
		#StatManager.set_base_stat("ex", StatManager.get_stat("ex") + 0.002)
	else:
		# Optionally handle loss logic here
		pass

func _disable_all_action_buttons() -> void:
        for btn in action_buttons:
                btn.disabled = true
        catch_button.disabled = true
        ghost_button.disabled = true
        ghost_button.text = "TTYL"
        inventory_button.disabled = true

func _reset_auto_checkboxes() -> void:
        for btn in action_buttons:
                btn.reset_auto_checkbox()




func _reveal_chat_effects_and_results(player_chat: ChatBox, player_result: String, npc_chat: ChatBox, npc_result: String, player_effects: Dictionary, npc_effects: Dictionary) -> void:
	# Show icons and then flash color for both chats, in sync
	if player_chat:
		await player_chat.set_stat_effects(player_effects)
		var idx = player_chat.chatlog_index
		if idx >= 0 and idx < chatlog.size():
				chatlog[idx].effects = player_effects.duplicate()
	if npc_chat:
		await npc_chat.set_stat_effects(npc_effects)
		var idx2 = npc_chat.chatlog_index
		if idx2 >= 0 and idx2 < chatlog.size():
				chatlog[idx2].effects = npc_effects.duplicate()
	# Flash both after icons
	if player_chat:
		await player_chat.reveal_result_color(player_result)
		var idxp = player_chat.chatlog_index
		if idxp >= 0 and idxp < chatlog.size():
				chatlog[idxp].result = player_result
	if npc_chat:
		await npc_chat.reveal_result_color(npc_result)
		var idxn = npc_chat.chatlog_index
		if idxn >= 0 and idxn < chatlog.size():
				chatlog[idxn].result = npc_result
	FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, "active")
	if player_chat:
		await player_chat.set_stat_effects(player_effects)
		if player_result == "success":
			TraumaManager.hit_pane(npc_portrait, 0.6)
		elif player_result == "fail":
			TraumaManager.hit_pane(profile_pic, 0.6)
		var idx = player_chat.chatlog_index
		if idx >= 0 and idx < chatlog.size():
			chatlog[idx].effects = player_effects.duplicate()





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
		fumble_profile.load_npc(npc, npc_idx)


func _on_close_fumble_profile_button_pressed():
	profile_center_container.hide()






func _apply_effects(effects: Dictionary):
	for stat in effects.keys():
		if battle_stats.has(stat):
			battle_stats[stat] = clamp100(battle_stats[stat] + effects[stat])
	# player stats (like confidence) handled by StatManager


func process_npc_response(move_type, response_id, success: bool) -> ChatBox:

	var rng = RNGManager.fumble_battle_ui.get_rng()
	var response_text = ""
	var key = "FALSE"
	if success:
			key = "TRUE"
	var entry = null
	if response_id and RizzBattleData.npc_responses.has(response_id):
			var pool = RizzBattleData.npc_responses[response_id][key]
			if pool.size() > 0:
					entry = pool[rng.randi() % pool.size()]
	elif RizzBattleData.npc_generic_responses.has(move_type):
			var pool = RizzBattleData.npc_generic_responses[move_type][key]
			if pool.size() > 0 and typeof(pool[0]) == TYPE_DICTIONARY:
					entry = pool[rng.randi() % pool.size()]
	if entry != null:
			var prefix = ""
			var suffix = ""
			if entry.has("response_prefix") and entry.response_prefix is Array and entry.response_prefix.size() > 0:
					var pref_pool = entry.response_prefix
					prefix = pref_pool[rng.randi() % pref_pool.size()]
			if entry.has("response_suffix") and entry.response_suffix is Array and entry.response_suffix.size() > 0:
					var suf_pool = entry.response_suffix
					suffix = suf_pool[rng.randi() % suf_pool.size()]
			response_text = str(prefix) + str(entry.response_line) + str(suffix)
	else:
			if RizzBattleData.npc_generic_responses.has(move_type):
					var pool = RizzBattleData.npc_generic_responses[move_type][key]
					if pool.size() > 0 and typeof(pool[0]) == TYPE_STRING:
							response_text = pool[rng.randi() % pool.size()]
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
		var se = current_stats.get("self_esteem", npc.self_esteem)
		var chem = current_stats.get("chemistry", npc.chemistry)
		var app = current_stats.get("apprehension", npc.apprehension)
		npc.self_esteem = se
		npc.chemistry = chem
		npc.apprehension = app
		if npc_idx != -1:
			NPCManager.set_npc_field(npc_idx, "self_esteem", se)
			NPCManager.set_npc_field(npc_idx, "chemistry", chem)
			NPCManager.set_npc_field(npc_idx, "apprehension", app)




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


func _on_close_chat_button_pressed() -> void:
	var outcome := "active"
	var rel_status = FumbleManager.FumbleStatus.ACTIVE_CHAT
	if victorious:
		outcome = "victory"
		rel_status = FumbleManager.FumbleStatus.LIKED
	elif blocked:
		outcome = "blocked"
		rel_status = FumbleManager.FumbleStatus.BLOCKED_PLAYER
	FumbleManager.save_battle_state(battle_id, chatlog, battle_stats, move_usage_counts, outcome)
	DBManager.save_fumble_relationship(npc_idx, rel_status)
	persist_battle_stats_to_npc()
	chat_closed.emit()
	queue_free()


func _on_daterbase_button_pressed() -> void:
	WindowManager.launch_app_by_name("Daterbase")
	await get_tree().create_timer(.75).timeout
	queue_free()
