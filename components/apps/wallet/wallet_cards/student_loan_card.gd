extends WalletCardBase
class_name StudentLoanCard

var _pay_slider: HSlider
var _pay_label: Label
var _pay_button: Button
var _autopay_check: CheckBox

var _principal: float = 0.0
var _interest_rate: float = 0.0   # annual %
var _accrued_interest: float = 0.0
var _next_due: String = ""
var _min_due: float = 0.0
var _autopay: bool = false

func _ready() -> void:
		setup("student_loan", "Student Loan", "Long-Term Debt")
		_build()
		_refresh_from_sources()
		BillManager.student_loan_changed.connect(_on_changed)

func _build() -> void:
	var rows1: Array = []
	rows1.append({"label": "Principal", "value": "$" + NumberFormatter.smart_format(_principal)})
	rows1.append({"label": "Accrued Interest", "value": "$" + String.num(_accrued_interest, 2)})
	add_group("balance", rows1)

	var rows2: Array = []
	rows2.append({"label": "APR", "value": String.num(_interest_rate, 2) + "%"})
	rows2.append({"label": "Min Due", "value": "$" + String.num(_min_due, 2)})
	rows2.append({"label": "Next Due", "value": _next_due})
	add_group("billing", rows2)

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
	_pay_slider.max_value = _principal + _accrued_interest
	_pay_slider.step = 1.0
	_pay_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pay_slider.value_changed.connect(_on_slider_changed)
	controls.add_child(_pay_slider)

	_pay_label = Label.new()
	_pay_label.text = "$" + String.num(_pay_slider.value, 2)
	controls.add_child(_pay_label)

	_pay_button = Button.new()
	_pay_button.text = "Pay Early"
	_pay_button.focus_mode = Control.FOCUS_NONE
	_pay_button.pressed.connect(_on_pay_pressed)
	controls.add_child(_pay_button)

	if _content != null:
			_content.add_child(controls)

	set_footer_note("interest accrues daily")

func _refresh_from_sources() -> void:
		var d: Dictionary = BillManager.get_student_loan_summary()
		_principal = float(d.get("principal", 0.0))
		_interest_rate = float(d.get("interest_rate", 0.0))
		_accrued_interest = float(d.get("accrued_interest", 0.0))
		_next_due = String(d.get("next_due", ""))
		_min_due = float(d.get("min_due", 0.0))
		_autopay = bool(d.get("autopay", false))
		_rebuild_display()
		_d("refreshed student loan summary")

func _rebuild_display() -> void:
		if _content == null:
				return
		for child in _content.get_children():
				child.queue_free()
		_build()

func _on_changed() -> void:
	_refresh_from_sources()
	bump_value_color()

func _on_autopay_toggled(pressed: bool) -> void:
	BillManager.set_student_loan_autopay(pressed)
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
		BillManager.pay_student_loan(amount)
		_refresh_from_sources()
