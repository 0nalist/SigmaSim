extends SceneTree

func _ready() -> void:
    var crypto := preload("res://resources/crypto/hawk2_crypto.tres").duplicate(true)

    var event := MarketEvent.new()
    event.target_symbol = "HAWK2"
    event.target_type = "crypto"
    event.start_min_minutes = 0
    event.start_max_minutes = 0
    event.pump_duration_min = 1
    event.pump_duration_max = 1
    event.pump_multiplier_min = 1.333333
    event.pump_multiplier_max = 1.333333
    event.dump_duration_min = 1
    event.dump_duration_max = 1
    event.dump_multiplier_min = 1.0
    event.dump_multiplier_max = 1.0

    var rng := RandomNumberGenerator.new()
    event.schedule(0, rng)
    event.process(0, crypto)
    event.process(1, crypto)

    assert(is_equal_approx(crypto.price, snapped(crypto.price, 0.01)))
    print("hawk2_price_precision_test passed")
    quit()

