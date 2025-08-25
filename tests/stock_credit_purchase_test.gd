extends SceneTree

func _ready():
        var pm = Engine.get_singleton("PortfolioManager")
        var mm = Engine.get_singleton("MarketManager")
        var stock = mm.get_stock("GME_STOCK")
        pm.stock_data[stock.symbol] = stock
        var prev_level := UpgradeManager.get_level("brokerage_pattern_day_trader")
        UpgradeManager.player_levels.erase("brokerage_pattern_day_trader")
        pm.cash = 0.0
        pm.credit_used = 0.0
        pm.credit_limit = 1000.0
        pm.credit_interest_rate = 0.0
        pm.credit_score = 800
        var result := pm.buy_stock(stock.symbol)
        assert(not result)
        UpgradeManager.player_levels["brokerage_pattern_day_trader"] = 1
        result = pm.buy_stock(stock.symbol)
        assert(result)
        pm.stocks_owned[stock.symbol] = 0
        pm.credit_used = 0.0
        if prev_level > 0:
                UpgradeManager.player_levels["brokerage_pattern_day_trader"] = prev_level
        else:
                UpgradeManager.player_levels.erase("brokerage_pattern_day_trader")
        print("stock_credit_purchase_test passed")
        quit()
