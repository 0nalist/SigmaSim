extends Pane
class_name Minerr

#@export var crypto_list: Array[Cryptocurrency]
@export var crypto_card_scene: PackedScene
var crypto_cards: Dictionary = {}

@onready var crypto_container: HBoxContainer = %CryptoContainer
@onready var gpus_label: Label = %GPUsLabel
@onready var sort_property_option: OptionButton = %SortPropertyOption
@onready var sort_direction_button: Button = %SortDirectionButton

@onready var new_gpu_price_label: Label = %NewGPUPriceLabel
@onready var used_gpu_price_label: Label = %UsedGPUPriceLabel

@onready var mine_tab_button: Button = %MineTabButton
@onready var charts_tab_button: Button = %ChartsTabButton
@onready var mine_view: VBoxContainer = %MineView
@onready var charts_view: VBoxContainer = %ChartsView
@onready var charts_mine_tab_button: Button = %MineTabButtonCharts
@onready var charts_charts_tab_button: Button = %ChartsTabButtonCharts
@onready var charts_cash_label: Label = %ChartsCashLabel
@onready var charts_crypto_label: Label = %ChartsCryptoLabel
@onready var charts_content: Control = _ensure_charts_content()
var crypto_popup_scene: PackedScene = preload("res://components/popups/crypto_popup_ui.tscn")

func _ensure_charts_content() -> Control:
        var existing: Node = charts_view.get_node_or_null("ChartsContent")
        if existing != null and existing is Control:
                return existing as Control
        var content: VBoxContainer = VBoxContainer.new()
        content.name = "ChartsContent"
        content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        content.size_flags_vertical = Control.SIZE_EXPAND_FILL
        content.add_theme_constant_override("separation", 16)
        charts_view.add_child(content)
        return content


var sort_property: String = "name"
var sort_ascending: bool = true
var _active_tab: StringName = &"Mine"


func _ready() -> void:
        MarketManager.crypto_market_ready.connect(refresh_cards_from_market)
        if not MarketManager.crypto_market.is_empty():
                refresh_cards_from_market()

        MarketManager.crypto_price_updated.connect(_on_crypto_updated)
        PortfolioManager.resource_changed.connect(_on_resource_changed)
        PortfolioManager.cash_updated.connect(_on_cash_updated)
        GPUManager.gpus_changed.connect(update_gpu_label)
        #GPUManager.crypto_mined.connect(_on_crypto_mined)
        GPUManager.gpu_prices_changed.connect(_on_gpu_prices_changed)
        sort_property_option.add_item("Name")
        sort_property_option.add_item("Price")
        sort_property_option.add_item("Power Required")
        sort_property_option.add_item("GPUs")
        sort_property_option.add_item("Chance")
        sort_property_option.add_item("Owned")
        sort_property_option.item_selected.connect(_on_sort_property_selected)
        sort_direction_button.pressed.connect(_on_sort_direction_button_pressed)
        mine_tab_button.pressed.connect(_on_mine_tab_pressed)
        charts_tab_button.pressed.connect(_on_charts_tab_pressed)
        charts_mine_tab_button.pressed.connect(_on_mine_tab_pressed)
        charts_charts_tab_button.pressed.connect(_on_charts_tab_pressed)
        sort_direction_button.text = "\u2191"
        update_gpu_label()
        _build_charts_view()
        _update_charts_labels()
        _activate_tab(&"Mine")

func refresh_cards_from_market() -> void:
	# Clear out any old cards
	for child: Node in crypto_container.get_children():
		child.queue_free()
	crypto_cards.clear()

	# Spawn new cards for each crypto in the market
	for crypto: Cryptocurrency in MarketManager.crypto_market.values():
		print("Minerr.refresh: crypto symbol=", crypto.symbol, " name=", crypto.display_name, " price=", crypto.price, " id=", str(crypto.get_instance_id()))
		var card: CryptoCard = crypto_card_scene.instantiate()
		crypto_container.add_child(card)
		print("Minerr.refresh: calling setup for id=", str(crypto.get_instance_id()))
		card.setup(crypto)
		# Connect card signals to Minerr handlers so buttons work.
		card.add_gpu.connect(_on_add_gpu)
		card.remove_gpu.connect(_on_remove_gpu)
		card.overclock_toggled.connect(_on_toggle_overclock)
		crypto_cards[crypto.symbol] = card
		debug_dump_cards()
		_sort_cards()



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
		_sort_cards()




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
                _sort_cards()
        _update_charts_labels()


func _on_crypto_updated(symbol: String, _crypto: Cryptocurrency) -> void:
        if crypto_cards.has(symbol):
                crypto_cards[symbol].update_display()
                _sort_cards()
        _update_charts_labels()




func _on_toggle_overclock(symbol: String) -> void:
	print("Toggle overclock for:", symbol)

func _on_buy_used_gpu_button_pressed() -> void:
	pass # Replace with function body.


func _on_buy_new_gpu_button_pressed() -> void:
		if GPUManager.buy_gpu():
				update_gpu_label()
		else:
				print("Could not purchase GPU (insufficient funds).")

func _on_sort_property_selected(index: int) -> void:
		match index:
				0:
						sort_property = "name"
				1:
						sort_property = "price"
				2:
						sort_property = "power_required"
				3:
						sort_property = "gpus"
				4:
						sort_property = "chance"
				5:
						sort_property = "owned"
		_sort_cards()

func _on_sort_direction_button_pressed() -> void:
	sort_ascending = not sort_ascending
	if sort_ascending:
		sort_direction_button.text = "\u2191"
	else:
		sort_direction_button.text = "\u2193"
	_sort_cards()


func _sort_cards() -> void:
	var cards: Array = crypto_cards.values()
	cards.sort_custom(_compare_cards)
	for i in range(cards.size()):
		crypto_container.move_child(cards[i], i)


func _compare_cards(a: CryptoCard, b: CryptoCard) -> bool:
		var val_a
		var val_b
		match sort_property:
				"name":
						val_a = a.crypto.display_name
						val_b = b.crypto.display_name
				"price":
						val_a = a.crypto.price
						val_b = b.crypto.price
				"power_required":
						val_a = a.crypto.power_required
						val_b = b.crypto.power_required
				"gpus":
						val_a = GPUManager.get_gpu_count_for(a.crypto.symbol)
						val_b = GPUManager.get_gpu_count_for(b.crypto.symbol)
				"chance":
						val_a = a.calculate_block_chance()
						val_b = b.calculate_block_chance()
				"owned":
						val_a = PortfolioManager.get_crypto_amount(a.crypto.symbol)
						val_b = PortfolioManager.get_crypto_amount(b.crypto.symbol)
				_:
						val_a = 0
						val_b = 0
		if sort_ascending:
				return val_a < val_b
		else:
				return val_a > val_b

func debug_dump_cards() -> void:
        print("-- Minerr cards --")
        for symbol in crypto_cards.keys():
                var card: CryptoCard = crypto_cards[symbol]
                if card.crypto != null:
                        var c: Cryptocurrency = card.crypto
                        print(symbol, ",", c.display_name, ", price=", c.price, ", id=", str(c.get_instance_id()))
                else:
                        print(symbol, ", card without crypto, id=", str(card.get_instance_id()))

func _on_cash_updated(_cash: float) -> void:
        _update_charts_labels()

func _update_charts_labels() -> void:
        charts_cash_label.text = "Cash: $" + NumberFormatter.format_number(PortfolioManager.cash)
        charts_crypto_label.text = "Crypto: $" + NumberFormatter.format_number(PortfolioManager.get_crypto_total())

func _activate_tab(tab_name: StringName) -> void:
        if tab_name == &"Mine":
                if is_instance_valid(mine_tab_button):
                        mine_tab_button.set_pressed(true)
                if is_instance_valid(charts_tab_button):
                        charts_tab_button.set_pressed(false)
                if is_instance_valid(charts_mine_tab_button):
                        charts_mine_tab_button.set_pressed(true)
                if is_instance_valid(charts_charts_tab_button):
                        charts_charts_tab_button.set_pressed(false)
                mine_view.visible = true
                charts_view.visible = false
        else:
                if is_instance_valid(mine_tab_button):
                        mine_tab_button.set_pressed(false)
                if is_instance_valid(charts_tab_button):
                        charts_tab_button.set_pressed(true)
                if is_instance_valid(charts_mine_tab_button):
                        charts_mine_tab_button.set_pressed(false)
                if is_instance_valid(charts_charts_tab_button):
                        charts_charts_tab_button.set_pressed(true)
                mine_view.visible = false
                charts_view.visible = true
        _active_tab = tab_name

func _on_mine_tab_pressed() -> void:
        _activate_tab(&"Mine")

func _on_charts_tab_pressed() -> void:
        _activate_tab(&"Charts")

func _build_charts_view() -> void:
        for child: Node in charts_content.get_children():
                child.queue_free()
        var symbols := MarketManager.crypto_market.keys()
        for i in range(symbols.size()):
                var symbol: String = symbols[i]
                var crypto: Cryptocurrency = MarketManager.crypto_market.get(symbol)
                var popup: CryptoPopupUI = crypto_popup_scene.instantiate()
                popup.custom_minimum_size = Vector2(350, 150)
                popup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                popup.size_flags_vertical = Control.SIZE_EXPAND_FILL
                popup.setup(crypto)
                charts_content.add_child(popup)
                if i < symbols.size() - 1:
                        var spacer: Control = Control.new()
                        spacer.custom_minimum_size = Vector2(0, 12)
                        charts_content.add_child(spacer)
