extends Panel
class_name CryptoCard

signal add_gpu(symbol: String)
signal remove_gpu(symbol: String)
signal overclock_toggled(symbol: String)
signal click_boost(symbol: String)
signal open_upgrades(symbol: String)
signal selected(symbol: String)

@onready var symbol_label = %SymbolLabel
@onready var display_name_label = %DisplayNameLabel
@onready var price_label = %PriceLabel
@onready var block_chance_label = %BlockChanceLabel
@onready var block_time_label = %BlockTimeLabel
@onready var block_size_label = %BlockSizeLabel
@onready var miner_sprite = %MinerSprite
@onready var click_boost_area = %ClickBoostArea
@onready var gpus_label = %GPUsLabel
@onready var add_gpu_button = %AddGPUButton
@onready var remove_gpu_button = %RemoveGPUButton
@onready var overclock_button = %OverclockToggleButton
@onready var upgrade_button = %UpgradeButton

var crypto: Cryptocurrency

func setup(crypto_data: Cryptocurrency) -> void:
	await self.ready
	crypto = crypto_data
	update_display()

	add_gpu_button.pressed.connect(func(): emit_signal("add_gpu", crypto.symbol))
	remove_gpu_button.pressed.connect(func(): emit_signal("remove_gpu", crypto.symbol))
	overclock_button.pressed.connect(func(): emit_signal("overclock_toggled", crypto.symbol))
	upgrade_button.pressed.connect(func(): emit_signal("open_upgrades", crypto.symbol))
	click_boost_area.pressed.connect(func(): emit_signal("click_boost", crypto.symbol))
	self.gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: emit_signal("selected", crypto.symbol))

func update_display() -> void:
	if not crypto: return
	symbol_label.text = crypto.symbol
	display_name_label.text = crypto.display_name
	price_label.text = "$%.2f" % crypto.price
	block_chance_label.text = "%.2f%% to mine" % calculate_block_chance()
	block_time_label.text = "Next block: %ds" % get_time_to_block()
	block_size_label.text = "Block size: %.1f" % crypto.block_size
	gpus_label.text = "GPUs: %d" % GPUManager.get_gpu_count_for(crypto.symbol)

func calculate_block_chance() -> float:
	var total_power = GPUManager.get_power_for(crypto.symbol)
	return clampf(float(total_power) / float(crypto.power_required) * 100.0, 0.0, 100.0)

func get_time_to_block() -> int:
	return max(0, round(GPUManager.get_time_until_next_block(crypto.symbol)))
