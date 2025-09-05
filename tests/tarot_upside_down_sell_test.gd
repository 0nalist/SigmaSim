extends SceneTree

func _ready():
    TarotManager.reset()
    PortfolioManager.cash = 0.0
    var cards = TarotManager.get_all_cards_ordered()
    var id = cards[0].get("id", "")
    var rarity = 3
    TarotManager.collection[id] = {rarity: 1}
    var base_price = TarotManager.get_sell_price(rarity)
    TarotManager.sell_card(id, rarity, true)
    assert(PortfolioManager.cash == base_price * 2.0)
    PortfolioManager.cash = 0.0
    TarotManager.collection[id] = {rarity: 1}
    TarotManager.sell_card(id, rarity)
    assert(PortfolioManager.cash == base_price)
    print("tarot_upside_down_sell_test passed")
    quit()
