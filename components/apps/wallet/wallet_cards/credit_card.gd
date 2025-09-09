extends WalletCardBase
class_name CreditCardFull

var _util_bar: ProgressBar
var _pay_slider: HSlider
var _pay_label: Label
var _pay_button: Button
var _autopay_check: CheckBox

var _balance: float = 0.0
var _limit: float = 0.0
var _apr: float = 0.0
var _min_due: float = 0.0
var _next_due: String = ""
var _autopay: bool = false

func _ready() -> void:
	# Ensure the base builds its shell first.
	super._ready()
	setup("credit", "Credit Card", "Credit Line")
	_build()
	_refresh_from_sources()

	# Signals
	BillManager.debt_resources_changed.connect(_on_changed)
	if BillManager.has_signal("credit_txn_occurred"):
		BillManager.credit_txn_occurred.connect(_on_credit_txn)

func _build() -> void:
	# Guard in case someone calls before base shell exists
	if _content == null:
		return

	# Section: account
	var rows1: Array = []
	rows1.append({"label": "Balance", "value": "$" + NumberFormatter.smart_format(_balance)})
	rows1.append({"label": "Limit", "value": "$" + NumberFormatter.smart_format(_limit)})
	add_group("account", rows1)

	# Utilization meter
	_util_bar = add_meter("Utilization", _utilization_percent())
	_util_bar.name = "UtilBar"

	# Section: billing
	var rows2: Array = []
	rows2.append({"label": "APR", "value": String.num(_apr, 2) + "%"})
	rows2.append({"label": "Min Due", "value": "$" + String.num(_min_due, 2)})
	rows2.append({"label": "Next Due", "value": _next_due})
	add_group("billing", rows2)

	# Controls row (autopay + pay slider/button)
	var controls: HBoxContainer = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_autopay_check = CheckBox.new()
	_autopay_check.text = "Autopay"
	_autopay_check.button_pressed = _autopay
	_autopay_check.focus_mode = Control.FOCUS_NONE
	_autopay_check.toggled.connect(_on_autopay_toggled)
	controls.add_child(_autopay_check)

	_pay_slider = HSlider.new()
	_pay_slider.min_value = 0.0
	_pay_slider.max_value = _balance
	_pay_slider.step = 1.0
	_pay_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pay_slider.value_changed.connect(_on_slider_changed)
	controls.add_child(_pay_slider)

	_pay_label = Label.new()
	_pay_label.text = "$" + String.num(_pay_slider.value, 2)
	controls.add_child(_pay_label)

	_pay_button = Button.new()
	_pay_button.text = "Pay"
	_pay_button.focus_mode = Control.FOCUS_NONE
	_pay_button.pressed.connect(_on_pay_pressed)
	controls.add_child(_pay_button)

	_content.add_child(controls)

	set_footer_note("recent txn: " + BillManager.get_last_credit_txn_ago())

func _refresh_from_sources() -> void:
	var d: Dictionary = BillManager.get_credit_summary()
	_balance = float(d.get("balance", 0.0))
	_limit = float(d.get("limit", 0.0))
	_apr = float(d.get("apr", 0.0))
	_min_due = float(d.get("min_due", 0.0))
	_next_due = String(d.get("next_due", ""))
	_autopay = bool(d.get("autopay", false))
	_rebuild_display()

func _rebuild_display() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.queue_free()
	_build()

func _on_changed() -> void:
	_refresh_from_sources()
	bump_value_color()

func _on_credit_txn(_amount: float) -> void:
	_refresh_from_sources()
	bump_value_color()

func _utilization_percent() -> float:
	if _limit <= 0.0:
		return 0.0
	return (_balance / _limit) * 100.0

func _on_autopay_toggled(pressed: bool) -> void:
	BillManager.set_credit_autopay(pressed)
	_autopay = pressed

func _on_slider_changed(v: float) -> void:
	_pay_label.text = "$" + String.num(v, 2)

func _on_pay_pressed() -> void:
	var amount: float = float(_pay_slider.value)
	if amount <= 0.0:
		return

	var max_afford: float = 0.0
	if Engine.has_singleton("PortfolioManager"):
		max_afford = PortfolioManager.cash
	if amount > max_afford:
		amount = max_afford

	BillManager.pay_credit(amount)
	_refresh_from_sources()
	var util: float = _utilization_percent()
	tween_bar_to(_util_bar, util, 0.35)

func animate_to_util(to_value: float) -> void:
	tween_bar_to(_util_bar, to_value, 0.5)
