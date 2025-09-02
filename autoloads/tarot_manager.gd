extends Node
#Autoload TarotManager

const TarotDeck = preload("res://components/apps/tarot/tarot_deck.gd")
const TarotCardView = preload("res://components/apps/tarot/tarot_card_view.gd")

signal collection_changed(card_id: String, count: int)

const DATA_PATH := "res://data/tarot_cards.json"
const COOLDOWN_MINUTES := 24 * 60
const RARITY_SELL_VALUES := {1:1.0, 2:10.0, 3:50.0, 4:250.0, 5:1000.0}

var deck: TarotDeck = TarotDeck.new()
var collection: Dictionary = {}
var last_draw_minutes: int = -COOLDOWN_MINUTES
var draw_cost: float = 1.0

func _ready() -> void:
	deck.load_from_file(DATA_PATH)

func reset() -> void:
	collection.clear()
	last_draw_minutes = -COOLDOWN_MINUTES
	deck.load_from_file(DATA_PATH)

func get_save_data() -> Dictionary:
	return {
		"collection": collection,
		"last_draw": last_draw_minutes
	}

func load_from_data(data: Dictionary) -> void:
	collection = data.get("collection", {}).duplicate()
	last_draw_minutes = int(data.get("last_draw", -COOLDOWN_MINUTES))
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

func get_all_cards_ordered() -> Array:
	return deck.get_all_cards_ordered()

func instantiate_card_view(id: String, count: int = 0, mark_sold_on_sell: bool = false, rarity: int = -1) -> TarotCardView:
        return deck.instantiate_card_view(id, count, mark_sold_on_sell, rarity)

func time_until_next_draw() -> int:
	var now = TimeManager.get_now_minutes()
	return max(0, COOLDOWN_MINUTES - (now - last_draw_minutes))

func can_draw() -> bool:
	return time_until_next_draw() == 0

func _roll_rarity(rng: RandomNumberGenerator) -> int:
	var weights := {1:80, 2:12, 3:5, 4:2, 5:1}
	var r := rng.randi_range(1, 100)
	var cumulative := 0
	for rarity in [1,2,3,4,5]:
		cumulative += weights.get(rarity, 0)
		if r <= cumulative:
			return rarity
	return 1

func draw_card() -> Dictionary:
	if not can_draw():
		return {}
	if not PortfolioManager.try_spend_cash(draw_cost):
		return {}
	var rng := RNGManager.get_rng()
	var rarity := _roll_rarity(rng)
	var pool: Array = deck.cards_by_rarity.get(rarity, [])
	if pool.is_empty():
		return {}
	var card: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
        var id: String = card.get("id", "")
        var rarities: Dictionary = collection.get(id, {})
        rarities[rarity] = int(rarities.get(rarity, 0)) + 1
        collection[id] = rarities
        last_draw_minutes = TimeManager.get_now_minutes()
        collection_changed.emit(id, get_card_count(id))
        return card

func sell_card(card_id: String, rarity: int) -> void:
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
        PortfolioManager.add_cash(price)
        collection_changed.emit(card_id, get_card_count(card_id))

func get_sell_price(rarity: int) -> float:
        return RARITY_SELL_VALUES.get(rarity, 1.0)
