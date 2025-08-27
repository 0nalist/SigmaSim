extends Pane
class_name CryptoUpgradeUI

@onready var system_ui: SystemUpgradeUI = %SystemUpgradeUI

var crypto_symbol: String = ""

func setup_custom(symbol: String) -> void:
	crypto_symbol = symbol
	unique_popup_key = "crypto_upgrades_%s" % symbol
	window_title = "%s Upgrades" % symbol
	_ensure_upgrades()
	if not is_node_ready():
		await ready
	system_ui.system_name = _get_system_name()
	system_ui.refresh_upgrades()

func _get_system_name() -> String:
	return "crypto_%s" % crypto_symbol

func _upgrade_id() -> String:
	return "%s_big_blocks" % crypto_symbol

func _ensure_upgrades() -> void:
	var id = _upgrade_id()
	if not UpgradeManager.upgrades.has(id):
		var upgrade = {
			"id": id,
			"name": "Big Blocks",
			"description": "Increase block size by 1",
			"systems": [_get_system_name()],
			"dependencies": [],
			"max_level": -1,
			"repeatable": true,
			"cost_per_level": {crypto_symbol: 1},
			"effects": [],
		}
		UpgradeManager.upgrades[id] = upgrade
		Events.register_upgrade_signals([id])
	if not Events.is_connected("%s_purchased" % id, Callable(self, "_on_big_blocks_purchased")):
		Events.connect("%s_purchased" % id, Callable(self, "_on_big_blocks_purchased"))

func _on_big_blocks_purchased(level: int) -> void:
	var crypto: Cryptocurrency = MarketManager.crypto_market.get(crypto_symbol)
	if crypto:
		crypto.block_size += 1
		MarketManager.crypto_price_updated.emit(crypto_symbol, crypto)
