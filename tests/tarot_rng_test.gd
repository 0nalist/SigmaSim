extends SceneTree

const DRAWS := 5000

func _ready():
    RNGManager.init_seed(123)
    TarotManager.reset()
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    var deck_size := TarotManager.deck.cards.size()
    var card_counts := {}
    var rarity_counts := {}
    var orientation_counts := {true: 0, false: 0}
    var sequence_cards := []
    var sequence_rarities := []
    var sequence_orientations := []
    for i in range(DRAWS):
        var result = TarotManager.draw_card()
        sequence_cards.append(result.get("id"))
        sequence_rarities.append(result.get("rarity"))
        var orient = result.get("upside_down")
        sequence_orientations.append(orient)
        card_counts[result.get("id")] = int(card_counts.get(result.get("id"), 0)) + 1
        rarity_counts[result.get("rarity")] = int(rarity_counts.get(result.get("rarity"), 0)) + 1
        orientation_counts[orient] += 1
        TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.init_seed(123)
    TarotManager.reset()
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    for i in range(DRAWS):
        var result = TarotManager.draw_card()
        assert(sequence_cards[i] == result.get("id"))
        assert(sequence_rarities[i] == result.get("rarity"))
        assert(sequence_orientations[i] == result.get("upside_down"))
        TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.init_seed(1)
    TarotManager.reset()
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.tarot_card.init_seed(10)
    RNGManager.tarot_rarity.init_seed(20)
    RNGManager.tarot_orientation.init_seed(30)
    var base = TarotManager.draw_card()
    var base_orient = base.get("upside_down")
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.tarot_card.init_seed(11)
    RNGManager.tarot_rarity.init_seed(20)
    RNGManager.tarot_orientation.init_seed(30)
    var card_changed = TarotManager.draw_card()
    var orient_same = card_changed.get("upside_down")
    assert(base.get("id") != card_changed.get("id"))
    assert(base.get("rarity") == card_changed.get("rarity"))
    assert(base_orient == orient_same)
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.tarot_card.init_seed(10)
    RNGManager.tarot_rarity.init_seed(21)
    RNGManager.tarot_orientation.init_seed(30)
    var rarity_changed = TarotManager.draw_card()
    var orient_same2 = rarity_changed.get("upside_down")
    assert(base.get("id") == rarity_changed.get("id"))
    assert(base.get("rarity") != rarity_changed.get("rarity"))
    assert(base_orient == orient_same2)
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    RNGManager.tarot_card.init_seed(10)
    RNGManager.tarot_rarity.init_seed(20)
    RNGManager.tarot_orientation.init_seed(31)
    var orientation_changed = TarotManager.draw_card()
    var orient_diff = orientation_changed.get("upside_down")
    assert(base.get("id") == orientation_changed.get("id"))
    assert(base.get("rarity") == orientation_changed.get("rarity"))
    assert(base_orient != orient_diff)
    RNGManager.init_seed(555)
    TarotManager.reset()
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    for i in range(10):
        TarotManager.draw_card()
        TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    var rng_state = RNGManager.get_save_data()
    var tarot_state = TarotManager.get_save_data()
    var next_expected = TarotManager.draw_card()
    var orientation_expected = next_expected.get("upside_down")
    RNGManager.init_seed(555)
    TarotManager.reset()
    RNGManager.load_from_data(rng_state)
    TarotManager.load_from_data(tarot_state)
    TarotManager.last_draw_minutes = -TarotManager.COOLDOWN_MINUTES
    var next_loaded = TarotManager.draw_card()
    var orientation_loaded = next_loaded.get("upside_down")
    assert(next_expected.get("id") == next_loaded.get("id"))
    assert(next_expected.get("rarity") == next_loaded.get("rarity"))
    assert(orientation_expected == orientation_loaded)
    var expected_card_avg = DRAWS / float(deck_size)
    for id in card_counts.keys():
        assert(abs(card_counts[id] - expected_card_avg) <= expected_card_avg * 0.5)
    var expected_rarity = {1: DRAWS * 0.80, 2: DRAWS * 0.12, 3: DRAWS * 0.05, 4: DRAWS * 0.02, 5: DRAWS * 0.01}
    for r in expected_rarity.keys():
        assert(abs(rarity_counts.get(r, 0) - expected_rarity[r]) <= expected_rarity[r] * 0.5)
    assert(abs(orientation_counts[true] - DRAWS / 2.0) <= DRAWS * 0.1)
    assert(abs(orientation_counts[false] - DRAWS / 2.0) <= DRAWS * 0.1)
    print("tarot_rng_test passed")
    quit()
