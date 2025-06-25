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
	card.set("npc_idx", idx)
	var npc = NPCManager.get_npc_by_index(idx)
	add_child(card) # Add as the last child (topmost)
	card.call("load_npc", npc)
	cards.append(card) # Last = topmost

func _update_card_positions():
	# Optionally just: nothing here, or only do scene order
	for i in range(cards.size()):
		move_child(cards[i], i)

func swipe_left():
	if cards.size() == 0:
		return
	var card = cards[cards.size() - 1] # Topmost card
	var idx = npc_indices[npc_indices.size() - 1]
	card.animate_swipe_left(func():
		card.queue_free()
		cards.pop_back()
		npc_indices.pop_back()
		NPCManager.mark_npc_inactive_in_app(idx, app_name)
		emit_signal("card_swiped_left", idx)
		_after_swipe()
	)

func swipe_right():
	if cards.size() == 0:
		return
	var card = cards[cards.size() - 1]
	var idx = npc_indices[npc_indices.size() - 1]
	card.animate_swipe_right(func():
		card.queue_free()
		cards.pop_back()
		npc_indices.pop_back()
		emit_signal("card_swiped_right", idx)
		_after_swipe()
	)

func _after_swipe():
	var idx = get_next_npc_index()
	if idx != -1:
		add_profile_card(idx)
		npc_indices.append(idx)



func clear_cards():
	for card in cards:
		card.queue_free()
	cards.clear()

func get_next_npc_index() -> int:
	return NPCManager.encounter_new_npc_for_app(app_name)
