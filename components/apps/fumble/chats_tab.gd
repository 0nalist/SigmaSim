extends Control
class_name ChatsTab

signal request_resize_x_to(pixels)

@onready var matches_label: Label = %MatchesLabel
@onready var match_container: HBoxContainer = %MatchContainer
@onready var chat_battles_container: VBoxContainer = %ChatBattlesContainer

@onready var average_match_label: Label = %AverageMatchLabel


@export var match_button_scene: PackedScene 
@export var battle_button_scene: PackedScene 
@export var match_profile_scene : PackedScene
@export var battle_scene: PackedScene

func _ready():
	refresh_matches()
	refresh_battles()

func refresh_matches():
	for child in match_container.get_children():
		child.queue_free()

	var matches = FumbleManager.get_matches()
	var battles = FumbleManager.get_active_battles()
	var battle_npc_indices = []
	for b in battles:
		battle_npc_indices.append(b.npc_idx)

	var total_attractiveness = 0
	var filtered_count = 0

	for idx in matches:
		# Only show if not in an active battle
		if battle_npc_indices.has(idx):
			continue
		var npc = NPCManager.get_npc_by_index(idx)
		total_attractiveness += npc.attractiveness
		filtered_count += 1
		var btn = match_button_scene.instantiate()
		btn.match_pressed.connect(_on_match_button_pressed)
		match_container.add_child(btn)
		btn.set_profile(npc, idx)

	matches_label.text = "Matches: %d" % filtered_count

	var avg_att = 0.0
	if filtered_count > 0:
		avg_att = float(total_attractiveness) / filtered_count
	average_match_label.text = "Avg: 🔥 %.1f/10" % (avg_att / 10.0)



func refresh_battles():
	for child in chat_battles_container.get_children():
		child.queue_free()
	var battles = FumbleManager.get_active_battles()
	for b in battles:
		var npc = NPCManager.get_npc_by_index(b.npc_idx)
               var btn = battle_button_scene.instantiate()
               chat_battles_container.add_child(btn)
               btn.set_battle(npc, b.battle_id, b.npc_idx)
               btn.pressed.connect(func(): _on_battle_button_pressed(b.battle_id, npc, b.npc_idx))
		

func _on_match_button_pressed(npc, idx):
	var match_profile = match_profile_scene.instantiate()
	#get_tree().root.
	add_child(match_profile)
	match_profile.set_profile(npc, idx)
       match_profile.start_battle_requested.connect(_on_start_battle_requested)
	

func _on_start_battle_requested(battle_id, npc, idx):
       open_battle(battle_id, npc, idx)
       refresh_battles()
       refresh_matches()

func _on_battle_button_pressed(battle_id, npc, idx):
       open_battle(battle_id, npc, idx)

func open_battle(battle_id, npc, idx):
        print("opening battle!")
        var scene = battle_scene.instantiate()
        #get_tree().root.
        add_child(scene)
        scene.load_battle(battle_id, npc, [], {}, idx)

        request_resize_x_to.emit(860)
	
