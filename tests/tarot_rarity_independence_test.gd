extends SceneTree

func _ready():
    RNGManager.init_seed(0)
    TarotManager.reset()
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.tarot_card.init_seed(42)
    RNGManager.tarot_rarity.init_seed(1)
    var first = TarotManager.draw_card()
    var card_id = first.get("id")
    var rarity1 = first.get("rarity")
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.tarot_card.init_seed(42)
    RNGManager.tarot_rarity.init_seed(2)
    var second = TarotManager.draw_card()
    var rarity2 = second.get("rarity")
    assert(card_id == second.get("id"))
    assert(rarity1 != rarity2)
    print("tarot_rarity_independence_test passed")
    quit()
