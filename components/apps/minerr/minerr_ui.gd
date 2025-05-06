extends Pane
class_name Minerr

#@export var crypto_list: Array[Cryptocurrency]
@export var crypto_row_scene: PackedScene

var crypto_rows: Dictionary = {}
var selected_symbol: String = ""

var extra_power: Dictionary = {}  # symbol: int
var power_draw_down: float = 1.0  # power decay rate per second

var target_power_percent: float = 0.0
var displayed_power_percent: float = 0.0
var power_bar_lerp_speed: float = 5.0



@onready var selected_crypto_label: Label = %SelectedCryptoLabel
@onready var crypto_container: VBoxContainer = %CryptoContainer
@onready var gpus_label: Label = %GPUsLabel
@onready var selected_crypto_texture: TextureRect = %SelectedCryptoTexture
@onready var power_bar: ProgressBar = %PowerBar

func _ready() -> void:
	refresh_rows_from_market()

	MarketManager.crypto_price_updated.connect(_on_crypto_updated)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	GPUManager.gpus_changed.connect(update_gpu_label)
	GPUManager.crypto_mined.connect(_on_crypto_mined)
	selected_crypto_texture.gui_input.connect(_on_selected_texture_clicked)

	update_gpu_label()
	

func refresh_rows_from_market():
	# Clear existing rows
	for row in crypto_rows.values():
		row.queue_free()
	crypto_rows.clear()

	# Create UI from current market state
	for symbol in MarketManager.crypto_market.keys():
		var crypto = MarketManager.crypto_market[symbol]
		extra_power[symbol] = 0  # or load/preserve if needed

		var row = crypto_row_scene.instantiate() as CryptoRow
		row.setup(crypto)
		row.sell_pressed.connect(_on_sell_pressed)
		row.add_gpu_pressed.connect(_on_add_gpu)
		row.remove_gpu_pressed.connect(_on_remove_gpu)
		row.selected.connect(_on_crypto_selected)

		crypto_container.add_child(row)
		crypto_rows[symbol] = row


func _process(delta: float) -> void:
	var changed := false
	var to_remove: Array[String] = []
	update_power_bar()
	# Decay all entries
	for symbol in extra_power.keys():
		extra_power[symbol] = max(0.0, extra_power[symbol] - power_draw_down * delta)
		if extra_power[symbol] <= 0.01:
			to_remove.append(symbol)
			extra_power[symbol] = 0.0
		else:
			changed = true

	# Clean up zero entries
	for symbol in to_remove:
		extra_power.erase(symbol)

	# Only recalculate if power actually changed
	if changed or to_remove.has(selected_symbol):
		update_power_bar()

	# Smooth power bar animation
	if abs(displayed_power_percent - target_power_percent) > 0.1:
		displayed_power_percent = lerpf(displayed_power_percent, target_power_percent, delta * power_bar_lerp_speed)
	else:
		displayed_power_percent = target_power_percent

	power_bar.value = displayed_power_percent



func update_gpu_label() -> void:
	var total_gpus: int = GPUManager.get_total_gpu_count()
	var free_gpus: int = GPUManager.get_free_gpu_count()
	gpus_label.text = "GPUs\nFree/Owned:\n%d / %d" % [free_gpus, total_gpus]

	for symbol in crypto_rows.keys():
		crypto_rows[symbol].update_display()

	update_power_bar()



func update_power_bar() -> void:
	if selected_symbol == "":
		target_power_percent = 0.0
		print("no selected symbol")
		return

	var crypto = MarketManager.crypto_market.get(selected_symbol)
	if crypto == null:
		target_power_percent = 0.0
		print("crypto null")
		return

	var gpu_power = GPUManager.get_power_for(selected_symbol)
	var boost = int(extra_power.get(selected_symbol, 0))
	var total_power = gpu_power + boost
	var required_power = float(crypto.power_required)

	target_power_percent = clampf(total_power / required_power * 100.0, 0.0, 100.0)





func _on_selected_texture_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if selected_symbol != "":
			extra_power[selected_symbol] = extra_power.get(selected_symbol, 0) + 1
			update_power_bar()

			displayed_power_percent = target_power_percent
			power_bar.value = displayed_power_percent



func _on_sell_pressed(symbol: String) -> void:
	PortfolioManager.sell_crypto(symbol)


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



func _on_crypto_selected(symbol: String) -> void:
	selected_symbol = symbol
	selected_crypto_label.text = "Selected: %s" % symbol
	update_power_bar()


func _on_crypto_updated(symbol: String, _crypto: Cryptocurrency) -> void:
	if crypto_rows.has(symbol):
		crypto_rows[symbol].update_display()

	# Directly update if this is the selected crypto
	if symbol == selected_symbol:
		update_power_bar()


func _on_resource_changed(resource_name: String, _value: float) -> void:
	if crypto_rows.has(resource_name):
		crypto_rows[resource_name].update_display()
	update_power_bar()


func _on_selected_crypto_texture_mouse_entered() -> void:
	CursorManager.set_pickaxe_cursor()

func _on_selected_crypto_texture_mouse_exited() -> void:
	CursorManager.set_default_cursor()

func _on_selected_crypto_texture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		CursorManager.set_pickaxe_click_cursor()
	else:
		CursorManager.set_pickaxe_cursor()

func _on_crypto_mined(crypto: Cryptocurrency):
	print("on crypto mined")
	##TODO Make this work
	var window: WindowFrame
	if get_parent().get_parent().get_parent() is WindowFrame:
		window = get_parent().get_parent().get_parent()
	else:
		return
	StatpopManager.spawn("+" + str(crypto.block_size) + " " + str(crypto.symbol), window.header.global_position, "passive", Color.GREEN)



func _on_buy_used_gpu_button_pressed() -> void:
	pass # Replace with function body.


func _on_buy_new_gpu_button_pressed() -> void:
	if GPUManager.buy_gpu():
		update_gpu_label()
	else:
		print("Could not purchase GPU (insufficient funds).")
