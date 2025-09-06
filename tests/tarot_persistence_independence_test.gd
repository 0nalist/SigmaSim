extends SceneTree

func _ready():
    RNGManager.init_seed(0)
    TarotManager.reset()
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    var single = TarotManager.draw_card()
    var single_id = single.get("id")
    var single_rarity = single.get("rarity")
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    var reading = TarotManager.draw_reading(2)
    assert(TarotManager.last_card_id == single_id)
    assert(TarotManager.last_card_rarity == single_rarity)
    assert(TarotManager.last_reading.size() == reading.size())
    for i in range(reading.size()):
        assert(TarotManager.last_reading[i].get("id") == reading[i].get("id"))
        assert(TarotManager.last_reading[i].get("rarity") == reading[i].get("rarity"))
    var save = TarotManager.get_save_data()
    TarotManager.reset()
    TarotManager.load_from_data(save)
    assert(TarotManager.last_card_id == single_id)
    assert(TarotManager.last_card_rarity == single_rarity)
    assert(TarotManager.last_reading.size() == reading.size())
    for i in range(reading.size()):
        assert(TarotManager.last_reading[i].get("id") == reading[i].get("id"))
        assert(TarotManager.last_reading[i].get("rarity") == reading[i].get("rarity"))
    print("tarot_persistence_independence_test passed")
    quit()

