extends Pane
class_name BrokeRage

@onready var stock_market: VBoxContainer = %StockMarket

func _ready() -> void:
        MarketManager.refresh_prices()

func _on_wallet_button_pressed() -> void:
        WindowManager.launch_app_by_name("Wallet")

func _on_ower_view_button_pressed() -> void:
        _on_wallet_button_pressed()
