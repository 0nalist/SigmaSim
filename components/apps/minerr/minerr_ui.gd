extends Pane
class_name Minerr

#@export var crypto_list: Array[Cryptocurrency]
@export var crypto_card_scene: PackedScene
var crypto_cards: Dictionary = {}

@onready var crypto_container: HBoxContainer = %CryptoContainer
@onready var gpus_label: Label = %GPUsLabel

@onready var new_gpu_price_label: Label = %NewGPUPriceLabel
@onready var used_gpu_price_label: Label = %UsedGPUPriceLabel


func _ready() -> void:
	MarketManager.crypto_market_ready.connect(refresh_cards_from_market)
	if not MarketManager.crypto_market.is_empty():
		refresh_cards_from_market()

	MarketManager.crypto_price_updated.connect(_on_crypto_updated)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	GPUManager.gpus_changed.connect(update_gpu_label)
	#GPUManager.crypto_mined.connect(_on_crypto_mined)
	GPUManager.gpu_prices_changed.connect(_on_gpu_prices_changed)
	update_gpu_label()

func refresh_cards_from_market() -> void:
	for card in crypto_cards.values():
		card.queue_free()
	crypto_cards.clear()

	for crypto in MarketManager.crypto_market.values():
		var symbol: String = crypto.symbol
		var card: CryptoCard = crypto_card_scene.instantiate() as CryptoCard
		crypto_container.add_child(card)
		card.setup(crypto)

		card.add_gpu.connect(_on_add_gpu)
		card.remove_gpu.connect(_on_remove_gpu)
		card.overclock_toggled.connect(_on_toggle_overclock)
		card.open_upgrades.connect(_on_open_upgrades)

		crypto_cards[symbol] = card


func update_gpu_label() -> void:
	var total_gpus: int = GPUManager.get_total_gpu_count()
	var free_gpus: int = GPUManager.get_free_gpu_count()
	gpus_label.text = "GPUs\nFree/Owned:\n%d / %d" % [free_gpus, total_gpus]

	# Color the label green if there are free GPUs, else white
	if free_gpus > 0:
		gpus_label.modulate = Color(0.2, 1.0, 0.2) # soft green
	else:
		gpus_label.modulate = Color(1, 1, 1)       # white

	for symbol in crypto_cards.keys():
		crypto_cards[symbol].update_display()
	_update_gpu_prices()




func _on_open_upgrades(symbol: String) -> void:
	print("Open upgrade panel for:", symbol)



func _on_add_gpu(symbol: String) -> void:
	if GPUManager.get_free_gpu_count() > 0:
		if GPUManager.assign_free_gpu(symbol):
			update_gpu_label()
		else:
			print("Failed to assign GPU to crypto.")
	else:
		print("No free GPUs available!")


func _on_remove_gpu(symbol: String) -> void:
	if GPUManager.get_gpu_count_for(symbol) > 0:
		GPUManager.remove_gpu_from(symbol, 1)  # removes and destroys GPU
		update_gpu_label()
	else:
		print("No GPUs assigned to remove.")


func _on_gpu_prices_changed() -> void:
	_update_gpu_prices()

func _update_gpu_prices() -> void:
	var new_price: float = GPUManager.get_new_gpu_price()
	var used_price: float = GPUManager.get_used_gpu_price()

	new_gpu_price_label.text = "New GPU: $" + NumberFormatter.format_commas(new_price)
	used_gpu_price_label.text = "Used GPU: $" + NumberFormatter.format_commas(used_price)	


func _on_resource_changed(resource_name: String, _value: float) -> void:
	if crypto_cards.has(resource_name):
		crypto_cards[resource_name].update_display()


func _on_crypto_updated(symbol: String, _crypto: Cryptocurrency) -> void:
	if crypto_cards.has(symbol):
		crypto_cards[symbol].update_display()


 

func _on_toggle_overclock(symbol: String) -> void:
	print("Toggle overclock for:", symbol)

func _on_buy_used_gpu_button_pressed() -> void:
	pass # Replace with function body.


func _on_buy_new_gpu_button_pressed() -> void:
	if GPUManager.buy_gpu():
		update_gpu_label()
	else:
		print("Could not purchase GPU (insufficient funds).")
