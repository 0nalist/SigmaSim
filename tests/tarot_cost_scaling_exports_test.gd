extends SceneTree

func _ready():
    TarotManager.reading_cost_base = 2.0
    TarotManager.reading_cost_increase = 1.1
    TarotManager.reading_cost_min_increase = 1.0
    TarotManager.reading_cost_decrease = 0.5
    TarotManager.reading_cost_decrease_rate = 2.0
    TarotManager.major_reading_cost_base = 2.0
    TarotManager.major_reading_cost_increase = 1.1
    TarotManager.major_reading_cost_min_increase = 1.0
    TarotManager.major_reading_cost_decrease = 0.5
    TarotManager.major_reading_cost_decrease_rate = 2.0
    TarotManager.reset()
    PortfolioManager.cash = 100.0
    StatManager.set_base_stat("ex", 100.0)
    var cards = TarotManager.draw_reading(1)
    assert(not cards.is_empty())
    assert(TarotManager.reading_cost == 3.0)
    TarotManager._on_hour_passed(0, 0)
    assert(TarotManager.reading_cost == 2.0)
    TarotManager.reset()
    var majors = TarotManager.draw_major_reading(1)
    assert(not majors.is_empty())
    assert(TarotManager.major_reading_cost == 3.0)
    TarotManager._on_hour_passed(0, 0)
    assert(TarotManager.major_reading_cost == 2.0)
    print("tarot_cost_scaling_exports_test passed")
    quit()
