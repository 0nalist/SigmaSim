class_name ProfileCardStack
extends Control

@export var app_name: String = "fumble"
@export var profile_card_scene: PackedScene

signal card_swiped_left(npc_idx)
signal card_swiped_right(npc_idx)

const CARD_VISIBLE_COUNT := 2

var npc_indices: Array[int] = []
var cards: Array[Control] = []

func _ready():
	load_initial_cards()

func load_initial_cards():
	clear_cards()
	npc_indices.clear()
	for i in range(CARD_VISIBLE_COUNT):
		var idx = get_next_npc_index()
		if idx == -1:
			break
		npc_indices.append(idx)
		add_profile_card(idx, i)

func add_profile_card(idx: int, position: int = -1):
	var card = profile_card_scene.instantiate()
	card.z_index = position if position >= 0 else cards.size()
	card.set("npc_idx", idx)
	var npc = NPCManager.get_npc_by_index(idx)
	card.call("load_npc", npc)
	add_child(card)
	cards.append(card)
	_update_card_positions()

func swipe_left():
	if cards.size() == 0:
		return
	var card = cards[0]
	var idx = npc_indices[0]
	card.animate_swipe_left(func():
		# After animation completes:
		card.queue_free()
		cards.pop_front()
		npc_indices.pop_front()
		NPCManager.mark_npc_inactive_in_app(idx, app_name)
		emit_signal("card_swiped_left", idx)
		_after_swipe()
	)

func swipe_right():
	if cards.size() == 0:
		return
	var card = cards[0]
	var idx = npc_indices[0]
	card.animate_swipe_right(func():
		card.queue_free()
		cards.pop_front()
		npc_indices.pop_front()
		# (Optional: Mark liked, or promote to persistent, etc)
		emit_signal("card_swiped_right", idx)
		_after_swipe()
	)

func _after_swipe():
	var idx = get_next_npc_index()
	if idx != -1:
		npc_indices.append(idx)
		add_profile_card(idx, position=cards.size())
	_update_card_positions()

func _update_card_positions():
	for i in range(cards.size()):
		cards[i].z_index = i
		# You can add visual stack offset here if you wish

func clear_cards():
	for card in cards:
		card.queue_free()
	cards.clear()

func get_next_npc_index() -> int:
	return NPCManager.encounter_new_npc_for_app(app_name)
