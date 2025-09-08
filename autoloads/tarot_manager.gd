extends Node
#Autoload TarotManager

const TarotDeck = preload("res://components/apps/tarot/tarot_deck.gd")
const TarotCardView = preload("res://components/apps/tarot/tarot_card_view.gd")

signal collection_changed(card_id: String, count: int)

const DATA_PATH := "res://data/tarot_cards.json"
const COOLDOWN_MINUTES := 24 * 60
const RARITY_SELL_VALUES := {1: 1.0, 2: 10.0, 3: 50.0, 4: 250.0, 5: 1000.0}

var deck: TarotDeck = TarotDeck.new()
var collection: Dictionary = {}
var last_draw_minutes: int = -COOLDOWN_MINUTES
var last_card_id: String = ""
var last_card_rarity: int = 0
var last_card_upside_down: bool = false
@export var reading_cost_base: float = 1.0
@export var reading_cost_increase: float = 1.1 # Multiplier
@export var reading_cost_decrease: float = 1.0 # Decreases by this much per hour
@export var reading_cost_decrease_rate: float = 1.0 # Multiplier for decrease amount per hour
@export var reading_cost_min_increase: float = 1.0 # Minimum absolute increase after a reading
@export var major_reading_cost_base: float = 1.0
@export var major_reading_cost_increase: float = 1.1
@export var major_reading_cost_decrease: float = 1.0
@export var major_reading_cost_decrease_rate: float = 1.0
@export var major_reading_cost_min_increase: float = 0.0
var reading_cost: float = 1.0
var major_reading_cost: float = 1.0
var last_reading: Array = []
var last_major_reading: Array = []


func _ready() -> void:
	deck.load_from_file(DATA_PATH)
	TimeManager.hour_passed.connect(_on_hour_passed)


func reset() -> void:
	collection.clear()
	last_draw_minutes = -COOLDOWN_MINUTES
	last_card_id = ""
	last_card_rarity = 0
	last_card_upside_down = false
	reading_cost = reading_cost_base
	major_reading_cost = major_reading_cost_base
	last_reading.clear()
	last_major_reading.clear()
	deck.load_from_file(DATA_PATH)


func get_save_data() -> Dictionary:
	return {
		"collection": collection,
		"last_draw": last_draw_minutes,
		"last_card_id": last_card_id,
		"last_card_rarity": last_card_rarity,
		"last_card_upside_down": last_card_upside_down,
		"reading_cost": reading_cost,
		"major_reading_cost": major_reading_cost,
		"last_reading": last_reading,
		"last_major_reading": last_major_reading
	}


func load_from_data(data: Dictionary) -> void:
	collection.clear()
	var raw_collection: Dictionary = data.get("collection", {})
	for id in raw_collection.keys():
		var raw_rarities: Dictionary = raw_collection[id]
		var fixed_rarities: Dictionary = {}
		for k in raw_rarities.keys():
			var rarity_int := int(k)
			fixed_rarities[rarity_int] = int(raw_rarities[k])
		collection[id] = fixed_rarities

	last_draw_minutes = int(data.get("last_draw", -COOLDOWN_MINUTES))
	last_card_id = data.get("last_card_id", "")
	last_card_rarity = int(data.get("last_card_rarity", 0))
	last_card_upside_down = bool(data.get("last_card_upside_down", false))
	reading_cost = float(data.get("reading_cost", reading_cost_base))
	major_reading_cost = float(data.get("major_reading_cost", major_reading_cost_base))
	last_reading = data.get("last_reading", [])
	last_major_reading = data.get("last_major_reading", [])
	deck.load_from_file(DATA_PATH)


func get_card_count(id: String) -> int:
	var rarities: Dictionary = collection.get(id, {})
	var total := 0
	for r in rarities.values():
		total += int(r)
	return total


func get_card_rarity_count(id: String, rarity: int) -> int:
	var rarities: Dictionary = collection.get(id, {})
	return int(rarities.get(rarity, 0))


func get_highest_owned_rarity(id: String) -> int:
	var rarities: Dictionary = collection.get(id, {})
	var highest := 1
	for r in rarities.keys():
		var r_int := int(r)
		if r_int > highest and int(rarities[r]) > 0:
			highest = r_int
	return highest


func get_all_cards_ordered() -> Array:
	return deck.get_all_cards_ordered()


func instantiate_card_view(
	id: String, count: int = 0, mark_sold_on_sell: bool = false, rarity: int = -1
) -> TarotCardView:
	return deck.instantiate_card_view(id, count, mark_sold_on_sell, rarity)


func time_until_next_draw() -> int:
	var now = TimeManager.get_now_minutes()
	return max(0, COOLDOWN_MINUTES - (now - last_draw_minutes))


func can_draw() -> bool:
	return time_until_next_draw() == 0


func _roll_rarity(rng: RandomNumberGenerator) -> int:
	var weights := {1: 80, 2: 12, 3: 5, 4: 2, 5: 1}
	var r := rng.randi_range(1, 100)
	var cumulative := 0
	for rarity in [1, 2, 3, 4, 5]:
		cumulative += weights.get(rarity, 0)
		if r <= cumulative:
			return rarity
	return 1


func draw_card() -> Dictionary:
	if not can_draw():
		return {}
	var card_rng := RNGManager.tarot_card.get_rng()
	var rarity_rng := RNGManager.tarot_rarity.get_rng()
	var orientation_rng := RNGManager.tarot_orientation.get_rng()
	var rarity := _roll_rarity(rarity_rng)
	var all_cards: Array = deck.cards
	if all_cards.is_empty():
		return {}
	var card: Dictionary = all_cards[card_rng.randi_range(0, all_cards.size() - 1)]
	var id: String = card.get("id", "")
	var rarities: Dictionary = collection.get(id, {})
	rarities[rarity] = int(rarities.get(rarity, 0)) + 1
	collection[id] = rarities
	last_draw_minutes = TimeManager.get_now_minutes()
	last_card_id = id
	last_card_rarity = rarity
	last_card_upside_down = orientation_rng.randf() < 0.5
	collection_changed.emit(id, get_card_count(id))
	return {"id": id, "rarity": rarity, "upside_down": last_card_upside_down}


func draw_reading(count: int) -> Array:
	var total_cost := reading_cost * count
	if total_cost > 0.0:
		if not PortfolioManager.pay_with_cash(total_cost):
			return []
		var previous_cost := reading_cost
		reading_cost *= reading_cost_increase
		if reading_cost < previous_cost + reading_cost_min_increase:
			reading_cost = previous_cost + reading_cost_min_increase
	var card_rng := RNGManager.tarot_card.get_rng()
	var rarity_rng := RNGManager.tarot_rarity.get_rng()
	var orientation_rng := RNGManager.tarot_orientation.get_rng()
	var results: Array = []
	for i in range(count):
		var rarity := _roll_rarity(rarity_rng)
		var all_cards: Array = deck.cards
		if all_cards.is_empty():
			continue
		var card: Dictionary = all_cards[card_rng.randi_range(0, all_cards.size() - 1)]
		var id: String = card.get("id", "")
		var rarities: Dictionary = collection.get(id, {})
		rarities[rarity] = int(rarities.get(rarity, 0)) + 1
		collection[id] = rarities
		collection_changed.emit(id, get_card_count(id))
		var upside_down := orientation_rng.randf() < 0.5
		results.append({"id": id, "rarity": rarity, "upside_down": upside_down})
	last_reading = results
	return results


func draw_major_reading(count: int) -> Array:
	var total_cost := major_reading_cost * count
	if total_cost > 0.0:
		var current_ex = StatManager.get_stat("ex", 0.0)
		if current_ex < total_cost:
			return []
		StatManager.set_base_stat("ex", current_ex - total_cost)
		var previous_cost := major_reading_cost
		major_reading_cost *= major_reading_cost_increase
		if major_reading_cost < previous_cost + major_reading_cost_min_increase:
			major_reading_cost = previous_cost + major_reading_cost_min_increase
	var card_rng := RNGManager.tarot_card.get_rng()
	var rarity_rng := RNGManager.tarot_rarity.get_rng()
	var orientation_rng := RNGManager.tarot_orientation.get_rng()
	var majors: Array = []
	for c in deck.cards:
		if c.get("suit", "") == "major":
			majors.append(c)
	var results: Array = []
	for i in range(count):
		if majors.is_empty():
			continue
		var rarity := _roll_rarity(rarity_rng)
		var card: Dictionary = majors[card_rng.randi_range(0, majors.size() - 1)]
		var id: String = card.get("id", "")
		var rarities: Dictionary = collection.get(id, {})
		rarities[rarity] = int(rarities.get(rarity, 0)) + 1
		collection[id] = rarities
		collection_changed.emit(id, get_card_count(id))
		var upside_down := orientation_rng.randf() < 0.5
		results.append({"id": id, "rarity": rarity, "upside_down": upside_down})
	last_major_reading = results
	return results


func _on_hour_passed(_current_hour: int, _total_minutes: int) -> void:
	reading_cost = max(reading_cost_base, reading_cost - reading_cost_decrease * reading_cost_decrease_rate)
	major_reading_cost = max(major_reading_cost_base, major_reading_cost - major_reading_cost_decrease * major_reading_cost_decrease_rate)


func sell_card(card_id: String, rarity: int, upside_down: bool = false) -> void:
	var rarities: Dictionary = collection.get(card_id, {})
	var count := int(rarities.get(rarity, 0))
	if count <= 0:
		return
	rarities[rarity] = count - 1
	if rarities[rarity] <= 0:
		rarities.erase(rarity)
	if rarities.is_empty():
		collection.erase(card_id)
	else:
		collection[card_id] = rarities
	var price := get_sell_price(rarity)
	if upside_down:
		price *= 2.0
	PortfolioManager.add_cash(price)
	collection_changed.emit(card_id, get_card_count(card_id))


func get_sell_price(rarity: int) -> float:
	return RARITY_SELL_VALUES.get(rarity, 1.0)
