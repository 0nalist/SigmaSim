extends SceneTree

func _ready():
        var mm = Engine.get_singleton("MarketManager")
        var stock_symbol: String = mm.stock_market.keys()[0]
        var crypto_symbol: String = mm.crypto_market.keys()[0]
        var stock: Stock = mm.stock_market[stock_symbol]
        var crypto: Cryptocurrency = mm.crypto_market[crypto_symbol]
        var stock_price := 123.45
        var crypto_price := 987.65
        stock.price = stock_price
        crypto.price = crypto_price
        var data = mm.get_save_data()
        mm.load_from_data(data)
        assert(is_equal_approx(mm.stock_market[stock_symbol].price, stock_price))
        assert(is_equal_approx(mm.crypto_market[crypto_symbol].price, crypto_price))
        print("market_price_persistence_test passed")
        quit()
