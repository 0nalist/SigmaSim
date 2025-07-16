class_name ProfileCardStack
extends Control

signal card_swiped_left(npc_idx)
signal card_swiped_right(npc_idx)

@export var app_name: String = "fumble"
@export var profile_card_scene: PackedScene

@export var min_recycled_percent: float = 0.0
@export var max_recycled_percent: float = 0.9
@export var max_recycled_cap_index: int = 20000
@export var swipe_pool_size: int = 20

const CARD_VISIBLE_COUNT := 2

var npc_indices: Array[int] = []
var cards: Array[Control] = []
var is_animating := false

var swipe_pool: Array[int] = []

var gender_similarity_threshold: float = 0.85
var preferred_gender: Vector3 = Vector3(0,0,0) # Set from FumbleUI


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
	for i in range(cards.size()):
		move_child(cards[i], i)

func swipe_left():
	if is_animating or cards.size() < 2:
		return
	is_animating = true
	var card = cards[cards.size() - 1]
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
	var card = cards[cards.size() - 1]
	var idx = npc_indices[npc_indices.size() - 1]
	card.animate_swipe_right(func():
		card.queue_free()
		cards.pop_back()
		npc_indices.pop_back()
		NPCManager.set_relationship_status(idx, app_name, "liked")
		emit_signal("card_swiped_right", idx)
		_after_swipe()
		is_animating = false
	)

func _after_swipe():
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



func refresh_swipe_pool_with_gender(gender_vec: Vector3, threshold := -1.0):
	preferred_gender = gender_vec
	if threshold > 0:
		gender_similarity_threshold = threshold
	_refill_swipe_pool()
	clear_cards()
	for i in range(CARD_VISIBLE_COUNT):
		var idx = _fetch_next_index_from_pool()
		if idx == -1:
			break
		_add_card_at_top(idx)

func refresh_pool_under_top_with_gender(gender_vec: Vector3, threshold := -1.0):
	preferred_gender = gender_vec
	if threshold > 0:
		gender_similarity_threshold = threshold

	# 1. Save top card (if any)
	var top_card: Control = null
	var top_idx: int = -1
	if cards.size() > 0:
		top_card = cards.back()
		top_idx = npc_indices.back()

	# 2. Remove all cards except top
	for i in range(cards.size() - 1):
		cards[i].queue_free()
	cards = cards.slice(-1)
	npc_indices = npc_indices.slice(-1)

	# 3. Clear and refill the pool using new filter
	swipe_pool.clear()
	_refill_swipe_pool()

	# 4. Add new cards underneath top until CARD_VISIBLE_COUNT is reached
	while cards.size() < CARD_VISIBLE_COUNT:
		var idx = _fetch_next_index_from_pool()
		if idx == -1:
			break
		_add_card_at_bottom(idx)


func _refill_swipe_pool():
	var seen = NPCManager.encounter_count
	var t = clamp(float(seen) / float(max_recycled_cap_index), 0.0, 1.0)
	var percent = lerp(min_recycled_percent, max_recycled_percent, t)
	var num_recycled = int(round(swipe_pool_size * percent))
	var num_new = swipe_pool_size - num_recycled
	var pool: Array[int] = []

	var exclude = npc_indices + swipe_pool

	# Filter new NPCs by gender similarity
	var new_indices: Array[int] = []
	for idx in NPCManager.get_batch_of_new_npc_indices(app_name, num_new * 3): # Overfetch for more choices
		if not exclude.has(idx):
			var npc = NPCManager.get_npc_by_index(idx)
			var sim = gender_dot_similarity(preferred_gender, npc.gender_vector)
			#print("idx:", idx, "vec:", npc.gender_vector, "sim:", sim, "pref:", preferred_gender, "threshold:", gender_similarity_threshold)
			if sim >= gender_similarity_threshold:
				new_indices.append(idx)
		if new_indices.size() >= num_new:
			break

	# Filter recycled NPCs by gender similarity
	var recycled_indices: Array[int] = []
	for idx in NPCManager.get_batch_of_recycled_npc_indices(app_name, num_recycled * 3):
		if not exclude.has(idx):
			var npc = NPCManager.get_npc_by_index(idx)
			if gender_dot_similarity(preferred_gender, npc.gender_vector) >= gender_similarity_threshold:
				recycled_indices.append(idx)
		if recycled_indices.size() >= num_recycled:
			break

	pool += new_indices  
	pool += recycled_indices
	pool.shuffle()

	while swipe_pool.size() < swipe_pool_size and not pool.is_empty():
		swipe_pool.append(pool.pop_front())

# Helper function for dot similarity
func gender_dot_similarity(a: Vector3, b: Vector3) -> float:
	if a.length() == 0 or b.length() == 0:
		return 0.0
	return a.dot(b) / (a.length() * b.length())


func set_curiosity(threshold: float):
	gender_similarity_threshold = threshold
