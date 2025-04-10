extends GridContainer
class_name CryptoRow

signal sell_pressed(symbol: String)
signal add_gpu_pressed(symbol: String)
signal remove_gpu_pressed(symbol: String)
signal selected(symbol: String)

@onready var token_label: Label = %TokenLabel
@onready var owned_label: Label = %OwnedLabel
@onready var sell_button: Button = %SellButton
@onready var gpus_label: Label = %GPUsLabel
@onready var add_gpu_button: Button = %AddGPUButton
@onready var remove_gpu_button: Button = %RemoveGPUButton

var crypto: Cryptocurrency

func setup(crypto_data: Cryptocurrency) -> void:
	await self.ready  # Ensures all nodes are initialized

	crypto = crypto_data
	update_display()

	sell_button.pressed.connect(func(): emit_signal("sell_pressed", crypto.symbol))
	add_gpu_button.pressed.connect(func(): emit_signal("add_gpu_pressed", crypto.symbol))
	remove_gpu_button.pressed.connect(func(): emit_signal("remove_gpu_pressed", crypto.symbol))

func update_display() -> void:
	token_label.text = "%s  $%.2f" % [crypto.symbol, crypto.price]

	var owned: float = PortfolioManager.get_crypto_amount(crypto.symbol)
	var value: float = crypto.price * owned
	owned_label.text = "%.4f owned ($%.2f)" % [owned, value]

	var count: int = GPUManager.get_gpu_count_for(crypto.symbol)
	gpus_label.text = "GPUs: %d" % count

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		emit_signal("selected", crypto.symbol)
