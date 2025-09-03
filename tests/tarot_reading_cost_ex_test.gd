extends SceneTree

func _ready():
    TarotManager.reset()
    StatManager.set_base_stat("ex", 100.0)
    var cards = TarotManager.draw_reading(1)
    assert(not cards.is_empty())
    assert(TarotManager.reading_cost == 2.0)
    TarotManager._on_hour_passed(0, 0)
    assert(TarotManager.reading_cost == 1.0)
    print("tarot_reading_cost_ex_test passed")
    quit()
