class_name ChatsTab
extends Control

signal request_resize_x_to(pixels)
signal request_resize_y_to(pixels)

@export var match_button_scene: PackedScene
@export var battle_button_scene: PackedScene
@export var match_profile_scene: PackedScene
@export var battle_scene: PackedScene

@onready var matches_label: Label = %MatchesLabel
@onready var matches_container: HBoxContainer = %MatchesContainer
@onready var matches_sort: OptionButton = %MatchesSort
@onready var chat_battles_container: VBoxContainer = %ChatBattlesContainer
@onready var chat_battles_sort: OptionButton = %ChatBattlesSort

@onready var average_match_label: Label = %AverageMatchLabel


func _ready():
	matches_sort.add_item("Recent")
	matches_sort.add_item("🔥 Asc")
	matches_sort.add_item("🔥 Desc")
	matches_sort.add_item("Name")
	matches_sort.add_item("Type")
	matches_sort.item_selected.connect(_on_matches_sort_selected)
	matches_sort.select(0)

	chat_battles_sort.add_item("🔥 Asc")
	chat_battles_sort.add_item("🔥 Desc")
	chat_battles_sort.add_item("Name")
	chat_battles_sort.add_item("Type")
	chat_battles_sort.add_item("Status")
	chat_battles_sort.item_selected.connect(_on_chat_battles_sort_selected)

	refresh_ui()


func refresh_ui():
		refresh_matches()
		refresh_battles()


func refresh_matches(time_budget_msec := 8) -> void:
		for child in matches_container.get_children():
				child.queue_free()
		var matches_rows: Array = FumbleManager.get_matches_with_times()
		var battles: Array = FumbleManager.get_active_battles()
		var battle_npc_indices := battles.map(func(b): return b.npc_idx)

		var total_attractiveness := 0
		var filtered_count := 0
		var data := []

		var start_time = Time.get_ticks_msec()

		for row in matches_rows:
				var idx: int = row.npc_id
				if battle_npc_indices.has(idx):
						continue
				var npc = NPCManager.get_npc_by_index(idx)
				total_attractiveness += npc.attractiveness
				filtered_count += 1
				data.append({"npc": npc, "idx": idx, "created_at": row.created_at})
				if Time.get_ticks_msec() - start_time > time_budget_msec:
						await get_tree().process_frame
						start_time = Time.get_ticks_msec()
		match matches_sort.selected:
				0:
						data.sort_custom(func(a, b): return a.created_at > b.created_at)
				1:
						data.sort_custom(func(a, b): return a.npc.attractiveness < b.npc.attractiveness)
				2:
						data.sort_custom(func(a, b): return a.npc.attractiveness > b.npc.attractiveness)
				3:
						data.sort_custom(func(a, b): return a.npc.full_name < b.npc.full_name)
				4:
						data.sort_custom(
								func(a, b): return str(a.npc.chat_battle_type) < str(b.npc.chat_battle_type)
						)
		for d in data:
				var btn = match_button_scene.instantiate()
				matches_container.add_child(btn)
				btn.set_profile(d.npc, d.idx)
				btn.match_pressed.connect(_on_match_button_pressed)
				if Time.get_ticks_msec() - start_time > time_budget_msec:
						await get_tree().process_frame
						start_time = Time.get_ticks_msec()
		for b in battles:
				var npc = NPCManager.get_npc_by_index(b.npc_idx)
				total_attractiveness += npc.attractiveness
				if Time.get_ticks_msec() - start_time > time_budget_msec:
						await get_tree().process_frame
						start_time = Time.get_ticks_msec()
		var total_count := filtered_count + battles.size()
		matches_label.text = "Matches: %d" % total_count

		var avg_att := 0.0
		if total_count > 0:
				avg_att = float(total_attractiveness) / total_count
		average_match_label.text = "Avg: 🔥 %.1f/10" % (avg_att / 10.0)


func refresh_battles():
	for child in chat_battles_container.get_children():
		child.queue_free()
	var battles: Array = FumbleManager.get_active_battles()
	var data := []
	for b in battles:
		var npc = NPCManager.get_npc_by_index(b.npc_idx)
		data.append({"npc": npc, "battle": b})
	match chat_battles_sort.selected:
		0:
			data.sort_custom(func(a, b): return a.npc.attractiveness < b.npc.attractiveness)
		1:
			data.sort_custom(func(a, b): return a.npc.attractiveness > b.npc.attractiveness)
		2:
			data.sort_custom(func(a, b): return a.npc.full_name < b.npc.full_name)
		3:
			data.sort_custom(
				func(a, b): return str(a.npc.chat_battle_type) < str(b.npc.chat_battle_type)
			)
		4:
			var order = {"blocked": 0, "victory": 1, "active": 2}
			data.sort_custom(
				func(a, b):
					return (
						order.get(a.battle.get("outcome", "active"), 2)
						< order.get(b.battle.get("outcome", "active"), 2)
					)
			)
	for d in data:
		var npc = d.npc
		var b = d.battle
		var btn = battle_button_scene.instantiate()
		btn.set_battle(npc, b.battle_id, b.npc_idx, b.get("outcome", "active"))
		btn.pressed.connect(func(): _on_battle_button_pressed(b.battle_id, npc, b.npc_idx))
		chat_battles_container.add_child(btn)


func _on_match_button_pressed(npc, idx):
	var match_profile = match_profile_scene.instantiate()
	add_child(match_profile)
	match_profile.set_profile(npc, idx)
	match_profile.start_battle_requested.connect(_on_start_battle_requested)


func _on_start_battle_requested(battle_id, npc, idx):
	open_battle(battle_id, npc, idx)
	refresh_ui()


func _on_battle_button_pressed(battle_id, npc, idx):
	open_battle(battle_id, npc, idx)


func open_battle(battle_id, npc, idx):
	var battle_data = FumbleManager.load_battle_state(battle_id)
	var scene = battle_scene.instantiate()
	add_child(scene)
	(
		scene
		. load_battle(
				battle_id,
				npc,
				battle_data.chatlog,
				battle_data.stats,
				battle_data.get("move_usage_counts", {}),
				idx,
				battle_data.get("outcome", "active"),
		)
	)
	scene.chat_closed.connect(_on_chat_closed)
	request_resize_x_to.emit(941)
	request_resize_y_to.emit(666)


func _on_chat_closed() -> void:
	print("chat closed")
	refresh_ui()


# Optional: If you want to always re-sync when the chats tab is shown from parent UI
func on_tab_selected():
	refresh_ui()


func sort_containers_by_recency() -> void:
	pass
	#sort matches_container with the most recent additions on the left
	#sort chat_battles_container with the most recently interacted on top


func _on_matches_sort_selected(_idx):
	refresh_matches()


func _on_chat_battles_sort_selected(_idx):
	refresh_battles()
