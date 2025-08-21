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
@onready var gpus_label = %GPUsLabel
@onready var add_gpu_button = %AddGPUButton
@onready var remove_gpu_button = %RemoveGPUButton
@onready var overclock_button = %OverclockButton
@onready var upgrade_button = %UpgradeButton
@onready var power_bar: ProgressBar = %PowerBar

var crypto: Cryptocurrency
var extra_power: float = 0.0
var power_draw_down: float = 1.0
var displayed_chance: float = 0.0
var lerp_speed: float = 5.0

func setup(crypto_data: Cryptocurrency) -> void:
	await ready
	crypto = crypto_data

	add_gpu_button.pressed.connect(func(): emit_signal("add_gpu", crypto.symbol))
	remove_gpu_button.pressed.connect(func(): emit_signal("remove_gpu", crypto.symbol))
	overclock_button.pressed.connect(func(): emit_signal("overclock_toggled", crypto.symbol))
	upgrade_button.pressed.connect(func(): emit_signal("open_upgrades", crypto.symbol))
	sell_button.pressed.connect(_on_sell_pressed)
	#block_sprite.gui_input.connect(_on_block_sprite_gui_input) #already in editor, but keep this 
	self.gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: emit_signal("selected", crypto.symbol))

	TimeManager.minute_passed.connect(_on_time_tick)
	GPUManager.gpus_changed.connect(update_display)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	MarketManager.crypto_price_updated.connect(_on_price_updated)
	GPUManager.crypto_mined.connect(_on_crypto_mined)
	GPUManager.block_attempted.connect(_on_block_attempted)
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

	block_chance_label.text = "%.f%% chance to mine" % displayed_chance
	if power_bar:
		power_bar.value = displayed_chance
	
	if crypto:
		var time_left: int = GPUManager.get_time_until_next_block(crypto.symbol)
		block_time_label.text = "Next block: %ds" % time_left

func calculate_block_chance() -> float:
	var gpu_power = GPUManager.get_power_for(crypto.symbol)
	var total_power = gpu_power + extra_power
	#print("DEBUG: gpu_power=", gpu_power, " extra_power=", extra_power, " power_required=", crypto.power_required)
	var chance = float(total_power + 1) / float(crypto.power_required + 1)
	return clampf(chance * 100.0, 0.0, 100.0)



func get_time_to_block() -> int:
	return max(0, GPUManager.get_time_until_next_block(crypto.symbol))

func update_display() -> void:
	if not crypto:
		return

	symbol_label.text = crypto.symbol
	display_name_label.text = crypto.display_name
	price_label.text = "$" + NumberFormatter.format_number(crypto.price)
	#block_time_label.text = "Next block: %ds" % get_time_to_block()
	block_size_label.text = "Block size: %.1f" % crypto.block_size

	var owned = PortfolioManager.get_crypto_amount(crypto.symbol)
	var value = owned * crypto.price
	owned_label.text = "%.4f owned" % owned
	#owned_label.text = "%.4f owned ($%.2f)" % [owned, value]
	
	var active_gpus = GPUManager.get_gpu_count_for(crypto.symbol)
	gpus_label.text = "GPUs: %d" % active_gpus
	
	if active_gpus > 0:
		animate_mining()
	else:
		animate_stop_mining()


func _on_click_boost() -> void:
	extra_power += 1.0  # Or scale with upgrade later
	# Optional: animate miner_sprite or play feedback

func _on_sell_pressed() -> void:
	var statpop_pos = sell_button.global_position
	
	if PortfolioManager.sell_crypto(crypto.symbol, 1.0):
		StatpopManager.spawn("+$" + NumberFormatter.format_commas(crypto.price, 0), statpop_pos, "click", Color.GREEN)
	else:
		StatpopManager.spawn("DECLINED", statpop_pos, "click", Color.RED)
	
	update_display()

func _on_price_updated(symbol: String, _crypto: Cryptocurrency) -> void:
	if symbol == crypto.symbol:
		update_display()

func _on_resource_changed(resource_name: String, _value: float) -> void:
	if resource_name == crypto.symbol:
		update_display()

func _on_time_tick(_mins: int) -> void:
	update_display()

func _on_block_attempted(symbol: String) -> void:
	if symbol == crypto.symbol:
		animate_new_block()


@onready var block_sprite: TextureRect = %BlockSprite
#@onready var miner_sprite: TextureRect = %MinerSprite
@onready var miner_animation_player: AnimationPlayer = %MinerAnimationPlayer
@onready var block_animation_player: AnimationPlayer = %BlockAnimationPlayer

func animate_mining() -> void:
	miner_animation_player.play("mining")

func animate_stop_mining() -> void:
	miner_animation_player.stop()

func animate_new_block() -> void:
	block_animation_player.play("new_block")


func _on_crypto_mined(mined_crypto: Cryptocurrency) -> void:
	if mined_crypto.symbol != crypto.symbol:
		return

	# Show statpop on top of the BlockSprite
	var block_global_pos = block_sprite.get_global_position()
	var stat_text = "+" + str(mined_crypto.block_size) + " " + mined_crypto.symbol
	StatpopManager.spawn(stat_text, block_global_pos, "passive", Color.GREEN)

	# Optional: play block animation again or a flash?
	block_animation_player.play("new_block")



func _on_block_sprite_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Mouse down — apply boost and change cursor
			CursorManager.set_pickaxe_click_cursor()
			extra_power += 1.0

			#var stat_text = "+1 Power"
			#var stat_pos = block_sprite.get_global_position()
			#StatpopManager.spawn(stat_text, stat_pos, "active", Color.YELLOW)

			displayed_chance = calculate_block_chance()
			power_bar.value = displayed_chance
		else:
			# Mouse released — return to idle pickaxe cursor
			CursorManager.set_pickaxe_cursor()


func _on_block_sprite_mouse_entered() -> void:
	CursorManager.set_pickaxe_cursor()

func _on_block_sprite_mouse_exited() -> void:
	CursorManager.set_default_cursor()
