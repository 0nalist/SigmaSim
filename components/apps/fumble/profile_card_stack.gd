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
var is_animating: bool = false

var swipe_pool: Array[int] = []

var gender_similarity_threshold: float = 0.85
var preferred_gender: Vector3 = Vector3(0, 0, 0) # Set from FumbleUI



func _ready() -> void:
	await load_initial_cards()


func load_initial_cards() -> void:
	clear_cards()
	await _refill_swipe_pool_async()
	await _populate_cards_over_frames(CARD_VISIBLE_COUNT, true)


func _add_card_at_top(idx: int) -> void:
	var card = profile_card_scene.instantiate()
	card.set("npc_idx", idx)
	var npc = NPCManager.get_npc_by_index(idx)
	add_child(card)
	card.call("load_npc", npc)
	cards.append(card)
	npc_indices.append(idx)
	_update_card_positions()


func _add_card_at_bottom(idx: int) -> void:
	var card = profile_card_scene.instantiate()
	card.set("npc_idx", idx)
	var npc = NPCManager.get_npc_by_index(idx)
	add_child(card)
	card.call("load_npc", npc)
	cards.insert(0, card)
	npc_indices.insert(0, idx)
	_update_card_positions()


func _update_card_positions() -> void:
	for i in range(cards.size()):
		move_child(cards[i], i)


func swipe_left() -> void:
		if is_animating or cards.size() < 1:
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


func swipe_left_and_wait() -> void:
	swipe_left()
	while is_animating:
		await get_tree().process_frame


func swipe_right() -> void:
	if is_animating or cards.size() < 1:
		return
	is_animating = true
	var card = cards[cards.size() - 1]
	var idx = npc_indices[npc_indices.size() - 1]
	card.animate_swipe_right(func():
		emit_signal("card_swiped_right", idx)
		card.queue_free()
		cards.pop_back()
		npc_indices.pop_back()
		_after_swipe()
		is_animating = false
	)


func _after_swipe() -> void:
	if swipe_pool.size() < CARD_VISIBLE_COUNT + 2:
		await _refill_swipe_pool_async()
	var idx: int = await _fetch_next_index_from_pool()
	if idx != -1:
		_add_card_at_bottom(idx)


func clear_cards() -> void:
	for card in cards:
		card.queue_free()
	cards.clear()
	npc_indices.clear()
	swipe_pool.clear()


# Now a coroutine—always call with await!
func _fetch_next_index_from_pool() -> int:
	if swipe_pool.is_empty():
		await _refill_swipe_pool_async()
	if swipe_pool.is_empty():
		return -1
	return swipe_pool.pop_front()


func refresh_swipe_pool_with_gender(gender_vec: Vector3, threshold: float = -1.0) -> void:
	preferred_gender = gender_vec
	if threshold > 0:
		gender_similarity_threshold = threshold
	await _refill_swipe_pool_async()
	clear_cards()
	await _populate_cards_over_frames(CARD_VISIBLE_COUNT, true)


func refresh_pool_under_top_with_gender(gender_vec: Vector3, threshold: float = -1.0) -> void:
	preferred_gender = gender_vec
	if threshold > 0:
		gender_similarity_threshold = threshold

	# Remove all but top
	for i in range(cards.size() - 1):
		cards[i].queue_free()
	cards = cards.slice(-1)
	npc_indices = npc_indices.slice(-1)

	swipe_pool.clear()
	await _refill_swipe_pool_async()

	while cards.size() < CARD_VISIBLE_COUNT:
		var idx: int = await _fetch_next_index_from_pool()
		if idx == -1:
			break
		_add_card_at_bottom(idx)
		await get_tree().process_frame


# Async helper
func _populate_cards_over_frames(count: int, add_at_top: bool = true) -> void:
	for i in range(count):
		var idx: int = await _fetch_next_index_from_pool()
		if idx == -1:
			break
		if add_at_top:
			_add_card_at_top(idx)
		else:
			_add_card_at_bottom(idx)
		await get_tree().process_frame  # Spread out the work


func _refill_swipe_pool_async(time_budget_msec: int = 8) -> void:
	var start_time: int = Time.get_ticks_msec()
	var seen: int = NPCManager.encounter_count
	var t: float = clamp(float(seen) / float(max_recycled_cap_index), 0.0, 1.0)
	var percent: float = lerp(min_recycled_percent, max_recycled_percent, t)
	var num_recycled: int = int(round(swipe_pool_size * percent))
	var num_new: int = swipe_pool_size - num_recycled
	var pool: Array[int] = []

	var exclude: Array = npc_indices + swipe_pool
	var min_att: int = PlayerManager.get_var("fumble_fugly_filter_threshold", 0) * 10

	var new_indices: Array[int] = []
	for idx in NPCManager.get_batch_of_new_npc_indices(app_name, num_new * 3):
		if not exclude.has(idx):
			var npc = NPCManager.get_npc_by_index(idx)
			if npc.attractiveness >= min_att and gender_dot_similarity(preferred_gender, npc.gender_vector) >= gender_similarity_threshold:
				new_indices.append(idx)
		if new_indices.size() >= num_new:
			break
		if Time.get_ticks_msec() - start_time > time_budget_msec:
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()

	var recycled_indices: Array[int] = []
	for idx in NPCManager.get_batch_of_recycled_npc_indices(app_name, num_recycled * 3):
		if not exclude.has(idx):
			var npc = NPCManager.get_npc_by_index(idx)
			if npc.attractiveness >= min_att and gender_dot_similarity(preferred_gender, npc.gender_vector) >= gender_similarity_threshold:
				recycled_indices.append(idx)
		if recycled_indices.size() >= num_recycled:
			break
		if Time.get_ticks_msec() - start_time > time_budget_msec:
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()

	pool += new_indices
	pool += recycled_indices
	RNGManager.fumble_profile_stack.shuffle(pool)

	while swipe_pool.size() < swipe_pool_size and not pool.is_empty():
		swipe_pool.append(pool.pop_front())


# Helper function for dot similarity
func gender_dot_similarity(a: Vector3, b: Vector3) -> float:
	if a.length() == 0 or b.length() == 0:
		return 0.0
	return a.dot(b) / (a.length() * b.length())


func set_curiosity(threshold: float) -> void:
	gender_similarity_threshold = threshold

func apply_gender_filter(gender_vec: Vector3, threshold: float = -1.0) -> void:
	preferred_gender = gender_vec
	if threshold > 0:
		gender_similarity_threshold = threshold

	for i in range(swipe_pool.size() - 1, -1, -1):
		var idx = swipe_pool[i]
		var npc = NPCManager.get_npc_by_index(idx)
		if gender_dot_similarity(preferred_gender, npc.gender_vector) < gender_similarity_threshold:
			swipe_pool.remove_at(i)

	while is_animating:
		await get_tree().process_frame

	while true:
		var removed: bool = false

		if cards.size() > 0:
			var top_idx: int = npc_indices[npc_indices.size() - 1]
			var top_npc = NPCManager.get_npc_by_index(top_idx)
			if gender_dot_similarity(preferred_gender, top_npc.gender_vector) < gender_similarity_threshold:
				var card = cards[cards.size() - 1]
				card.queue_free()
				cards.pop_back()
				npc_indices.pop_back()
				NPCManager.mark_npc_inactive_in_app(top_idx, app_name)
				emit_signal("card_swiped_left", top_idx)
				_update_card_positions()
				await _after_swipe()
				removed = true

		if not removed and cards.size() > 1:
			var bottom_idx: int = npc_indices[0]
			var bottom_npc = NPCManager.get_npc_by_index(bottom_idx)
			if gender_dot_similarity(preferred_gender, bottom_npc.gender_vector) < gender_similarity_threshold:
				var card = cards[0]
				card.queue_free()
				cards.remove_at(0)
				npc_indices.remove_at(0)
				NPCManager.mark_npc_inactive_in_app(bottom_idx, app_name)
				emit_signal("card_swiped_left", bottom_idx)
				_update_card_positions()
				await _after_swipe()
				removed = true

		if not removed:
			break


# Removes NPCs below the fugly filter threshold without refreshing the entire stack.
func apply_fugly_filter() -> void:
	var min_att: int = PlayerManager.get_var("fumble_fugly_filter_threshold", 0) * 10

	# Filter out existing entries in the swipe_pool that no longer meet the requirement
	for i in range(swipe_pool.size() - 1, -1, -1):
		var idx: int = swipe_pool[i]
		var npc = NPCManager.get_npc_by_index(idx)
		if npc.attractiveness < min_att:
			swipe_pool.remove_at(i)

	while true:
		var removed: bool = false

		# Check the top card first so that it animates properly
		if cards.size() > 0:
			var top_idx: int = npc_indices[npc_indices.size() - 1]
			var top_npc = NPCManager.get_npc_by_index(top_idx)
			if top_npc.attractiveness < min_att:
				await swipe_left_and_wait()
				removed = true

		# Then check the bottom card
		if not removed and cards.size() > 1:
			var bottom_idx: int = npc_indices[0]
			var bottom_npc = NPCManager.get_npc_by_index(bottom_idx)
			if bottom_npc.attractiveness < min_att:
				var card = cards[0]
				card.queue_free()
				cards.remove_at(0)
				npc_indices.remove_at(0)
				NPCManager.mark_npc_inactive_in_app(bottom_idx, app_name)
				emit_signal("card_swiped_left", bottom_idx)
				_update_card_positions()
				await _after_swipe()
				removed = true

		if not removed:
			break
