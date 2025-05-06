extends Panel
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

@onready var block_label: Label = %BlockLabel
@onready var countdown_label: Label = %CountdownLabel

@onready var overclock_button: Button = %OverclockButton


var crypto: Cryptocurrency

var countdown_timer: Timer

func setup(crypto_data: Cryptocurrency) -> void:
	await self.ready  # Ensures all nodes are initialized

	crypto = crypto_data
	
	TimeManager.minute_passed.connect(update_countdown_display)
	GPUManager.gpus_changed.connect(update_block_chance_display)
	update_display()

	sell_button.pressed.connect(func(): emit_signal("sell_pressed", crypto.symbol))
	add_gpu_button.pressed.connect(func(): emit_signal("add_gpu_pressed", crypto.symbol))
	remove_gpu_button.pressed.connect(func(): emit_signal("remove_gpu_pressed", crypto.symbol))
	
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.autostart = true
	countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	add_child(countdown_timer)

	update_display()
	
func update_display() -> void:
	if not crypto:
		return
	# Update the token label text
	token_label.text = "%s  $%.2f" % [crypto.symbol, crypto.price]

	# Color the price based on change since last tick
	if crypto.price > crypto.last_price:
		token_label.add_theme_color_override("font_color", Color.GREEN)
	elif crypto.price < crypto.last_price:
		token_label.add_theme_color_override("font_color", Color.RED)
	else:
		token_label.add_theme_color_override("font_color", Color.WHITE)  # Or whatever your default is

	# Update ownership label
	var owned: float = PortfolioManager.get_crypto_amount(crypto.symbol)
	var value: float = crypto.price * owned
	owned_label.text = "%.4f owned ($%.2f)" % [owned, value]

	# Update GPU label
	var gpu_count: int = GPUManager.get_gpu_count_for(crypto.symbol)
	gpus_label.text = "GPUs: %d" % gpu_count
	
	update_block_chance_display()
	update_countdown_display()

func update_block_chance_display() -> void:
	if not crypto:
		return
	var total_power = GPUManager.get_power_for(crypto.symbol)
	var chance_percent = clampf(float(total_power) / float(crypto.power_required) * 100.0, 0.0, 100.0)
	print("Crypto %s - power: %d / required: %d" % [crypto.symbol, total_power, crypto.power_required])
	block_label.text = "%.2f%% chance to mine %s" % [chance_percent, crypto.symbol]


func update_countdown_display(_minute_passed: int = 1) -> void:
	var time_left: int = (round(GPUManager.get_time_until_next_block(crypto.symbol)))
	countdown_label.text = "%ds" % max(time_left, 0)

func _on_countdown_timer_timeout() -> void:
	update_countdown_display()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		emit_signal("selected", crypto.symbol)
