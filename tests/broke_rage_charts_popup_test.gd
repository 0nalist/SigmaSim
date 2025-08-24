extends SceneTree

func _ready():
    var mm = Engine.get_singleton("MarketManager")
    mm.stock_market.clear()
    var stock = Stock.new()
    stock.symbol = "TEST"
    stock.display_name = "Test"
    mm.register_stock(stock)

    var scene = load("res://components/apps/app_scenes/broke_rage.tscn")
    var ui = scene.instantiate()
    get_root().add_child(ui)
    await get_tree().process_frame
    await get_tree().process_frame
    ui._build_charts_view()
    var content = ui.charts_content
    assert(content.get_child_count() == 1)
    var child = content.get_child(0)
    assert(child.get_class() == "StockPopupUI")
    print("broke_rage_charts_popup_test passed")
    quit()
