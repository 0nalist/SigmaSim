extends PanelContainer
class_name CryptoCard

signal add_gpu(symbol: String)
signal remove_gpu(symbol: String)
signal overclock_toggled(symbol: String)
signal open_upgrades(symbol: String)
signal selected(symbol: String)

@onready var symbol_label: Label = %SymbolLabel
@onready var display_name_label: Label = %DisplayNameLabel
@onready var price_label: Label = %PriceLabel
@onready var block_chance_label: Label = %BlockChanceLabel
@onready var block_time_label: Label = %BlockTimeLabel
@onready var block_size_label: Label = %BlockSizeLabel
@onready var owned_label: Label = %OwnedLabel
@onready var sell_button: Button = %SellButton
@onready var miner_sprite: TextureRect = %MinerSprite
@onready var gpus_label: Label = %GPUsLabel
@onready var add_gpu_button: Button = %AddGPUButton
@onready var remove_gpu_button: Button = %RemoveGPUButton
@onready var overclock_button: Button = %OverclockButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var power_bar: ProgressBar = %PowerBar

@onready var block_sprite: TextureRect = %BlockSprite
@onready var miner_animation_player: AnimationPlayer = %MinerAnimationPlayer
@onready var block_animation_player: AnimationPlayer = %BlockAnimationPlayer

var crypto: Cryptocurrency = null
var extra_power: float = 0.0
var power_draw_down: float = 1.0
var displayed_chance: float = 0.0
var lerp_speed: float = 5.0

func _ready() -> void:
	# Start disabled; enable in setup() when crypto is assigned.
	set_process(false)
	# Safe default UI so labels don't show nonsense before setup.
	_reset_ui_placeholders()
	# Optional: connect hover/cursor signals that don't need crypto
	block_sprite.gui_input.connect(_on_block_sprite_gui_input)
	block_sprite.mouse_entered.connect(_on_block_sprite_mouse_entered)
	block_sprite.mouse_exited.connect(_on_block_sprite_mouse_exited)

func setup(crypto_data: Cryptocurrency) -> void:
	await ready
	crypto = crypto_data

	# Connect signals that depend on crypto being non-null
	add_gpu_button.pressed.connect(func() -> void:
		if crypto != null:
			emit_signal("add_gpu", crypto.symbol)
	)

	remove_gpu_button.pressed.connect(func() -> void:
		if crypto != null:
			emit_signal("remove_gpu", crypto.symbol)
	)

	overclock_button.pressed.connect(func() -> void:
		if crypto != null:
			emit_signal("overclock_toggled", crypto.symbol)
	)

	upgrade_button.pressed.connect(func() -> void:
		if crypto != null:
			emit_signal("open_upgrades", crypto.symbol)
	)

	self.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if crypto != null:
				emit_signal("selected", crypto.symbol)
	)

	sell_button.pressed.connect(_on_sell_pressed)

	TimeManager.minute_passed.connect(_on_time_tick)
	GPUManager.gpus_changed.connect(update_display)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	MarketManager.crypto_price_updated.connect(_on_price_updated)
	GPUManager.crypto_mined.connect(_on_crypto_mined)
	GPUManager.block_attempted.connect(_on_block_attempted)

	update_display()
	set_process(true)

func _process(delta: float) -> void:
	if crypto == null:
		return

	# Decay boost power
	if extra_power > 0.0:
		extra_power = max(0.0, extra_power - power_draw_down * delta)

	# Smooth update of displayed chance
	var target_chance: float = calculate_block_chance()
	if abs(displayed_chance - target_chance) > 0.1:
		displayed_chance = lerpf(displayed_chance, target_chance, delta * lerp_speed)
	else:
		displayed_chance = target_chance

	block_chance_label.text = "%d%% chance to mine" % int(round(displayed_chance))
	if power_bar != null:
		power_bar.value = displayed_chance

	var time_left: float = GPUManager.get_time_until_next_block(crypto.symbol)
	var seconds: int = int(floor(time_left))
	block_time_label.text = "Next block: %ds" % seconds

func calculate_block_chance() -> float:
	if crypto == null:
		return 0.0
	var gpu_power: int = GPUManager.get_power_for(crypto.symbol)
	var total_power: float = float(gpu_power) + extra_power
	var chance: float = float(total_power + 1.0) / float(crypto.power_required + 1.0)
	chance = clampf(chance * 100.0, 0.0, 100.0)
	return chance

func get_time_to_block() -> int:
	if crypto == null:
		return 0
	var secs: float = GPUManager.get_time_until_next_block(crypto.symbol)
	return max(0, int(floor(secs)))

func update_display() -> void:
	if crypto == null:
		return

	symbol_label.text = crypto.symbol
	display_name_label.text = crypto.display_name
	price_label.text = "$" + NumberFormatter.format_number(crypto.price)
	block_size_label.text = "Block size: %.1f" % crypto.block_size

	var owned: float = PortfolioManager.get_crypto_amount(crypto.symbol)
	owned_label.text = "%.4f owned" % owned

	var active_gpus: int = GPUManager.get_gpu_count_for(crypto.symbol)
	gpus_label.text = "GPUs: %d" % active_gpus

	if active_gpus > 0:
		animate_mining()
	else:
		animate_stop_mining()

	# Update power bar immediately from current calc
	var chance_now: float = calculate_block_chance()
	displayed_chance = chance_now
	if power_bar != null:
		power_bar.value = displayed_chance
	block_chance_label.text = "%d%% chance to mine" % int(round(displayed_chance))

func _on_click_boost() -> void:
	extra_power += 1.0
	displayed_chance = calculate_block_chance()
	if power_bar != null:
		power_bar.value = displayed_chance

func _on_sell_pressed() -> void:
	if crypto == null:
		return
	var statpop_pos: Vector2 = sell_button.global_position
	var success: bool = PortfolioManager.sell_crypto(crypto.symbol, 1.0)
	if success:
		StatpopManager.spawn("+$" + NumberFormatter.format_commas(crypto.price, 0), statpop_pos, "click", Color.GREEN)
	else:
		StatpopManager.spawn("DECLINED", statpop_pos, "click", Color.RED)
	update_display()

func _on_price_updated(symbol: String, _crypto: Cryptocurrency) -> void:
	if crypto == null:
		return
	if symbol == crypto.symbol:
		update_display()

func _on_resource_changed(resource_name: String, _value: float) -> void:
	if crypto == null:
		return
	if resource_name == crypto.symbol:
		update_display()

func _on_time_tick(_mins: int) -> void:
	if crypto == null:
		return
	update_display()

func _on_block_attempted(symbol: String) -> void:
	if crypto == null:
		return
	if symbol == crypto.symbol:
		animate_new_block()

func animate_mining() -> void:
	miner_animation_player.play("mining")

func animate_stop_mining() -> void:
	miner_animation_player.stop()

func animate_new_block() -> void:
	block_animation_player.play("new_block")

func _on_crypto_mined(mined_crypto: Cryptocurrency) -> void:
	if crypto == null:
		return
	if mined_crypto.symbol != crypto.symbol:
		return
	var block_global_pos: Vector2 = block_sprite.get_global_position()
	var stat_text: String = "+" + str(mined_crypto.block_size) + " " + mined_crypto.symbol
	StatpopManager.spawn(stat_text, block_global_pos, "passive", Color.GREEN)
	block_animation_player.play("new_block")

func _on_block_sprite_gui_input(event: InputEvent) -> void:
	if crypto == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			CursorManager.set_pickaxe_click_cursor()
			extra_power += 1.0
			displayed_chance = calculate_block_chance()
			if power_bar != null:
				power_bar.value = displayed_chance
		else:
			CursorManager.set_pickaxe_cursor()

func _on_block_sprite_mouse_entered() -> void:
	CursorManager.set_pickaxe_cursor()

func _on_block_sprite_mouse_exited() -> void:
	CursorManager.set_default_cursor()

func _reset_ui_placeholders() -> void:
	symbol_label.text = ""
	display_name_label.text = ""
	price_label.text = "$0"
	block_chance_label.text = "0% chance to mine"
	block_time_label.text = "Next block: --"
	block_size_label.text = "Block size: --"
	owned_label.text = "0.0000 owned"
	gpus_label.text = "GPUs: 0"
	if power_bar != null:
		power_bar.value = 0.0
