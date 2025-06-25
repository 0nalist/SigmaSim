class_name ProfileCardStack
extends Control

@export var app_name: String = "fumble"
@export var profile_card_scene: PackedScene

signal card_swiped_left(npc_idx)
signal card_swiped_right(npc_idx)

const CARD_VISIBLE_COUNT := 2

var npc_indices: Array[int] = []  # bottom → top
var cards: Array[Control] = []    # bottom → top
var is_animating := false

func _ready():
	load_initial_cards()

func load_initial_cards():
	clear_cards()
	npc_indices.clear()
	cards.clear()
	for i in range(CARD_VISIBLE_COUNT):
		var idx = get_next_npc_index()
		if idx == -1:
			break
		_add_card_at_top(idx)

func _add_card_at_top(idx: int):
	var card = profile_card_scene.instantiate()
	card.set("npc_idx", idx)
	var npc = NPCManager.get_npc_by_index(idx)
	add_child(card)
	card.call("load_npc", npc)
	cards.append(card)
	npc_indices.append(idx)
	_update_card_positions()

func _add_card_at_bottom(idx: int):
	var card = profile_card_scene.instantiate()
	card.set("npc_idx", idx)
	var npc = NPCManager.get_npc_by_index(idx)
	add_child(card)
	card.call("load_npc", npc)
	cards.insert(0, card)
	npc_indices.insert(0, idx)
	_update_card_positions()

func _update_card_positions():
	# Ensure the correct visual order (bottom first)
	for i in range(cards.size()):
		move_child(cards[i], i)

func swipe_left():
	if is_animating or cards.size() < 2:
		return
	is_animating = true
	var card = cards[cards.size() - 1]  # top card
	var idx = npc_indices[npc_indices.size() - 1]
	card.animate_swipe_left(func():
		card.queue_free()
		cards.pop_back()
		npc_indices.pop_back()
		NPCManager.mark_npc_inactive_in_app(idx, app_name)
		emit_signal("card_swiped_left", idx)
		_after_swipe()
		is_animating = false
	)

func swipe_right():
	if is_animating or cards.size() < 2:
		return
	is_animating = true
	var card = cards[cards.size() - 1]  # top card
	var idx = npc_indices[npc_indices.size() - 1]
	card.animate_swipe_right(func():
		card.queue_free()
		cards.pop_back()
		npc_indices.pop_back()
		emit_signal("card_swiped_right", idx)
		_after_swipe()
		is_animating = false
	)

func _after_swipe():
	# After swipe, always add a new card to the bottom of the stack
	var idx = get_next_npc_index()
	if idx != -1:
		_add_card_at_bottom(idx)

func clear_cards():
	for card in cards:
		card.queue_free()
	cards.clear()
	npc_indices.clear()

func get_next_npc_index() -> int:
	return NPCManager.encounter_new_npc_for_app(app_name)
