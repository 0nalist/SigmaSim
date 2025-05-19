extends PanelContainer
class_name CryptoCard

signal add_gpu(symbol: String)
signal remove_gpu(symbol: String)
signal overclock_toggled(symbol: String)
signal open_upgrades(symbol: String)
signal selected(symbol: String)

@onready var symbol_label = %SymbolLabel
@onready var display_name_label = %DisplayNameLabel
@onready var price_label = %PriceLabel
@onready var block_chance_label = %BlockChanceLabel
@onready var block_time_label = %BlockTimeLabel
@onready var block_size_label = %BlockSizeLabel
@onready var owned_label: Label = %OwnedLabel
@onready var sell_button: Button = %SellButton
@onready var miner_sprite = %MinerSprite
@onready var click_boost_area = %ClickBoostArea
@onready var gpus_label = %GPUsLabel
@onready var add_gpu_button = %AddGPUButton
@onready var remove_gpu_button = %RemoveGPUButton
@onready var overclock_button = %OverclockButton
@onready var upgrade_button = %UpgradeButton
@onready var power_bar: ProgressBar = %PowerBar  # Optional but recommended

var crypto: Cryptocurrency
var extra_power: float = 0.0
var power_draw_down: float = 1.0
var displayed_chance: float = 0.0
var lerp_speed: float = 5.0

func setup(crypto_data: Cryptocurrency) -> void:
	await self.ready
	crypto = crypto_data

	add_gpu_button.pressed.connect(func(): emit_signal("add_gpu", crypto.symbol))
	remove_gpu_button.pressed.connect(func(): emit_signal("remove_gpu", crypto.symbol))
	overclock_button.pressed.connect(func(): emit_signal("overclock_toggled", crypto.symbol))
	upgrade_button.pressed.connect(func(): emit_signal("open_upgrades", crypto.symbol))
	sell_button.pressed.connect(_on_sell_pressed)
	click_boost_area.pressed.connect(_on_click_boost)
	self.gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: emit_signal("selected", crypto.symbol))

	TimeManager.minute_passed.connect(_on_time_tick)
	GPUManager.gpus_changed.connect(update_display)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	MarketManager.crypto_price_updated.connect(_on_price_updated)

	update_display()

func _process(delta: float) -> void:
	# Decay boost power
	if extra_power > 0.0:
		extra_power = max(0.0, extra_power - power_draw_down * delta)

	# Smooth update
	var target_chance = calculate_block_chance()
	if abs(displayed_chance - target_chance) > 0.1:
		displayed_chance = lerpf(displayed_chance, target_chance, delta * lerp_speed)
	else:
		displayed_chance = target_chance

	block_chance_label.text = "%.2f%% to mine" % displayed_chance
	if power_bar:
		power_bar.value = displayed_chance

func calculate_block_chance() -> float:
	var gpu_power = GPUManager.get_power_for(crypto.symbol)
	var total_power = gpu_power + extra_power
	return clampf(total_power / float(crypto.power_required) * 100.0, 0.0, 100.0)

func get_time_to_block() -> int:
	return max(0, round(GPUManager.get_time_until_next_block(crypto.symbol)))

func update_display() -> void:
	if not crypto:
		return

	symbol_label.text = crypto.symbol
	display_name_label.text = crypto.display_name
	price_label.text = "$%.2f" % crypto.price
	block_time_label.text = "Next block: %ds" % get_time_to_block()
	block_size_label.text = "Block size: %.1f" % crypto.block_size

	var owned = PortfolioManager.get_crypto_amount(crypto.symbol)
	var value = owned * crypto.price
	owned_label.text = "%.4f owned" % owned
	#owned_label.text = "%.4f owned ($%.2f)" % [owned, value]

	gpus_label.text = "GPUs: %d" % GPUManager.get_gpu_count_for(crypto.symbol)

func _on_click_boost() -> void:
	extra_power += 1.0  # Or scale with upgrade later
	# Optional: animate miner_sprite or play feedback

func _on_sell_pressed() -> void:
	PortfolioManager.sell_crypto(crypto.symbol, 1.0)
	update_display()

func _on_price_updated(symbol: String, _crypto: Cryptocurrency) -> void:
	if symbol == crypto.symbol:
		update_display()

func _on_resource_changed(resource_name: String, _value: float) -> void:
	if resource_name == crypto.symbol:
		update_display()

func _on_time_tick(_mins: int) -> void:
	update_display()
