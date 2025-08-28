extends PanelContainer
class_name DebtCardUI

@onready var name_label: Label = %NameLabel
@onready var amount_label: Label = %AmountLabel
@onready var limit_label: Label = %LimitLabel
@onready var limit_bar: ProgressBar = %LimitBar
@onready var interest_label: Label = %InterestLabel
@onready var compound_label: Label = %CompoundLabel
@onready var due_label: Label = %DueLabel
@onready var pay_slider: HSlider = %PaySlider
@onready var slider_label: Label = %SliderLabel
@onready var pay_button: Button = %PayButton
@onready var borrow_hbox: HBoxContainer = %BorrowHBox
@onready var borrow_slider: HSlider = %BorrowSlider
@onready var borrow_label: Label = %BorrowLabel
@onready var borrow_button: Button = %BorrowButton

var resource_data: Dictionary = {}
var _is_ready: bool = false

func _ready() -> void:
	# Hook signals only when children are guaranteed to exist
	pay_slider.value_changed.connect(_on_slider_changed)
	pay_button.pressed.connect(_on_pay_pressed)
	borrow_slider.value_changed.connect(_on_borrow_slider_changed)
	borrow_button.pressed.connect(_on_borrow_pressed)
	_is_ready = true

	# If data was provided before _ready, reflect it now
	if not resource_data.is_empty():
		update_display()

func init(resource: Dictionary) -> void:
	# Store data immediately; render if already ready
	resource_data = resource
	if _is_ready:
		update_display()

func update_display() -> void:
	# Guard: if someone calls manually before ready, bail gracefully
	if not _is_ready:
		return

	name_label.text = resource_data.get("name", "")
	var balance: float = float(resource_data.get("balance", 0.0))
	amount_label.text = "$" + NumberFormatter.format_commas(balance)

	var rate: float = float(resource_data.get("interest_rate", 0.0)) * 100.0
	interest_label.text = "Interest: %.2f%%" % rate

	var period: String = String(resource_data.get("compound_period", "Monthly"))
	compound_label.text = "Compounds: %s" % period

	var due_days: int = int(resource_data.get("days_until_due", 0))
	due_label.text = "Due in: %d days" % due_days

	var credit_limit = resource_data.get("credit_limit")
	var has_limit = credit_limit != null and float(credit_limit) > 0.0
	if has_limit:
		var limit: float = float(credit_limit)
		limit_bar.max_value = limit
		limit_bar.value = balance
		limit_bar.visible = true
		limit_label.text = "Limit: $" + NumberFormatter.format_commas(limit)
		limit_label.visible = true
	else:
		limit_bar.visible = false
		limit_label.visible = false

	var can_borrow: bool = bool(resource_data.get("can_borrow", false))
	borrow_hbox.visible = can_borrow
	borrow_button.visible = can_borrow
	update_slider()
	update_borrow_slider()

func update_slider() -> void:
	if not _is_ready:
		return

	var cash: float = float(PortfolioManager.cash)
	var balance: float = float(resource_data.get("balance", 0.0))
	var max_pay: float = min(balance, cash)
	pay_slider.max_value = max_pay
	if pay_slider.value > max_pay:
		pay_slider.value = max_pay
		slider_label.text = "$%.2f" % pay_slider.value
		pay_button.disabled = max_pay <= 0.0

func update_borrow_slider() -> void:
		if not _is_ready or not bool(resource_data.get("can_borrow", false)):
				return
		var limit: float = float(resource_data.get("borrow_limit", 0.0))
		borrow_slider.max_value = limit
		if borrow_slider.value > limit:
				borrow_slider.value = limit
		borrow_label.text = "$%.2f" % borrow_slider.value

func _on_slider_changed(value: float) -> void:
		if not _is_ready:
				return
		slider_label.text = "$%.2f" % value

func _on_borrow_slider_changed(value: float) -> void:
		if not _is_ready:
				return
		borrow_label.text = "$%.2f" % value

func _on_pay_pressed() -> void:
		if not _is_ready:
				return
		var amount: float = float(pay_slider.value)
		if amount <= 0.0:
				return
		BillManager.pay_debt(String(resource_data.get("name", "")), amount)
		update_display()

func _on_borrow_pressed() -> void:
		if not _is_ready:
				return
		var amount: float = float(borrow_slider.value)
		if amount <= 0.0:
				return
		BillManager.take_payday_loan(amount)
		update_display()
