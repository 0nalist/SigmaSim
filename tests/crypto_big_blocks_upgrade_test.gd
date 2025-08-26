extends SceneTree

func _ready() -> void:
    await MarketManager.crypto_market_ready
    var symbol := "BITC"
    var crypto: Cryptocurrency = MarketManager.crypto_market[symbol]
    var start_block := crypto.block_size
    var owned_before := PortfolioManager.get_crypto_amount(symbol)
    PortfolioManager.add_crypto(symbol, 1.0)
    var scene = preload("res://components/upgrade_scenes/crypto_upgrade_ui.tscn")
    var ui = scene.instantiate() as CryptoUpgradeUI
    add_child(ui)
    await ui.ready
    ui.setup_custom(symbol)
    var upgrade_id := "%s_big_blocks" % symbol
    var pre_spend := PortfolioManager.get_crypto_amount(symbol)
    var ok := UpgradeManager.purchase(upgrade_id)
    assert(ok)
    assert(crypto.block_size == start_block + 1)
    assert(PortfolioManager.get_crypto_amount(symbol) == pre_spend - 1.0)
    print("crypto_big_blocks_upgrade_test passed")
    quit()
