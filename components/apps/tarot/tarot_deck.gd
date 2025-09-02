extends Resource
class_name TarotDeck

const CARD_VIEW_SCENE = preload("res://components/apps/tarot/tarot_card_view.tscn")

var cards: Array = []
var card_map: Dictionary = {}
var cards_by_rarity: Dictionary = {}

func load_from_file(path: String) -> void:
    cards.clear()
    card_map.clear()
    cards_by_rarity.clear()
    if not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    var text := file.get_as_text()
    file.close()
    var data = JSON.parse_string(text)
    if typeof(data) != TYPE_ARRAY:
        return
    cards = data
    for card in cards:
        var id: String = card.get("id", "")
        card_map[id] = card
        var rarity: int = int(card.get("rarity", 1))
        if not cards_by_rarity.has(rarity):
            cards_by_rarity[rarity] = []
        cards_by_rarity[rarity].append(card)

func get_card(id: String) -> Dictionary:
    return card_map.get(id, {})

func instantiate_card_view(id: String, count: int = 0, mark_sold_on_sell: bool = false, rarity: int = -1) -> TarotCardView:
    var data = get_card(id).duplicate()
    if rarity > 0:
        data["rarity"] = rarity
    var view: TarotCardView = CARD_VIEW_SCENE.instantiate()
    view.mark_sold_on_sell = mark_sold_on_sell
    view.setup(data, count)
    return view

func _compare_cards(a: Dictionary, b: Dictionary) -> bool:
    var order = {
        "major": 0,
        "wands": 1,
        "cups": 2,
        "swords": 3,
        "pentacles": 4
    }
    var sa = order.get(a.get("suit", "major"), 99)
    var sb = order.get(b.get("suit", "major"), 99)
    if sa == sb:
        return int(a.get("number", 0)) < int(b.get("number", 0))
    return sa < sb

func get_all_cards_ordered() -> Array:
    var arr = cards.duplicate()
    arr.sort_custom(Callable(self, "_compare_cards"))
    return arr
