class_name ProfileCardStack
extends Control

signal card_swiped_left(npc_idx)
signal card_swiped_right(npc_idx)

@export var app_name: String = "fumble"
@export var profile_card_scene: PackedScene

@export var min_recycled_percent: float = 0.0   # 0% at start
@export var max_recycled_percent: float = 0.9   # 90% at end
@export var max_recycled_cap_index: int = 20000 # Index at which max is reached
@export var swipe_pool_size: int = 20

const CARD_VISIBLE_COUNT := 2

var npc_indices: Array[int] = []  # bottom → top
var cards: Array[Control] = []    # bottom → top
var is_animating := false

var swipe_pool: Array[int] = []

func _ready():
	load_initial_cards()

func load_initial_cards():
	clear_cards()
	_refill_swipe_pool()
	for i in range(CARD_VISIBLE_COUNT):
		var idx = _fetch_next_index_from_pool()
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
	# Always refill the pool if running low
	if swipe_pool.size() < CARD_VISIBLE_COUNT + 2:
		_refill_swipe_pool()
	var idx = _fetch_next_index_from_pool()
	if idx != -1:
		_add_card_at_bottom(idx)

func clear_cards():
	for card in cards:
		card.queue_free()
	cards.clear()
	npc_indices.clear()
	swipe_pool.clear()

func _fetch_next_index_from_pool() -> int:
	if swipe_pool.is_empty():
		_refill_swipe_pool()
	if swipe_pool.is_empty():
		return -1
	return swipe_pool.pop_front()

func _refill_swipe_pool():
	# Calculates desired number of recycled and new npcs in pool
	var seen = NPCManager.encounter_count
	var t = clamp(float(seen) / float(max_recycled_cap_index), 0.0, 1.0)
	var percent = lerp(min_recycled_percent, max_recycled_percent, t)
	var num_recycled = int(round(swipe_pool_size * percent))
	var num_new = swipe_pool_size - num_recycled
	var pool: Array[int] = []

	# Only fetch NEW that aren't already in pool or on stack
	var new_indices = NPCManager.get_batch_of_new_npc_indices(app_name, num_new)
	# Only fetch RECYCLED that aren't already in pool or on stack
	var recycled_indices = NPCManager.get_batch_of_recycled_npc_indices(app_name, num_recycled)

	# Exclude any NPCs already on stack or already queued for the pool
	var exclude = npc_indices + pool
	new_indices = new_indices.filter(func(idx): return not exclude.has(idx))
	recycled_indices = recycled_indices.filter(func(idx): return not exclude.has(idx))

	pool += new_indices
	pool += recycled_indices
	pool.shuffle()

	# Add only as many as needed to reach pool size
	while swipe_pool.size() < swipe_pool_size and not pool.is_empty():
		swipe_pool.append(pool.pop_front())

func get_allowed_recycled_count() -> int:
	var seen = NPCManager.encounter_count
	var t = clamp(float(seen) / float(max_recycled_cap_index), 0.0, 1.0)
	var percent = lerp(min_recycled_percent, max_recycled_percent, t)
	return int(round(swipe_pool_size * percent))
