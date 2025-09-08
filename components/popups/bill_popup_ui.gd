extends Pane
class_name BillPopupUI

var bill_name: String = ""
var amount: float = 0.0
var interest_rate: float = 0.0
var total_with_interest: float = 0.0
var date_key: String = ""

var popup_type := "BillPopupUI"

@onready var bill_label: Label = %BillLabel
@onready var interest_label: Label = %InterestLabel
@onready var autopay_checkbox: CheckBox = %AutopayCheckBox

func _ready() -> void:
		user_movable = true
		window_title = "Bill: " + str(bill_name)
		#window_can_close = false
		#window_can_minimize = false
		# If the popup was restored after data load, manually refresh UI
		_update_display()
		autopay_checkbox.set_pressed_no_signal(BillManager.autopay_enabled)
		BillManager.autopay_changed.connect(_on_autopay_changed)

func init(name: String) -> void:
	bill_name = name
	amount = BillManager.get_bill_amount(name)
	interest_rate = PortfolioManager.credit_interest_rate
	total_with_interest = amount * (1.0 + interest_rate)
	_update_display()

func _update_display() -> void:
	if is_instance_valid(bill_label):
			bill_label.text = "%s\n$%s" % [bill_name, NumberFormatter.format_commas(amount)]
	if is_instance_valid(interest_label):
			var total := amount * (1.0 + PortfolioManager.credit_interest_rate)
			interest_label.text = "Paying with credit will cost $%s total at %.0f%% interest" % [
					NumberFormatter.format_commas(total),
					PortfolioManager.credit_interest_rate * 100
			]


func update_amount_display() -> void:
	_update_display()

func close() -> void:
	WindowManager.close_window(window_frame)

func _on_pay_now_button_pressed() -> void:
	if PortfolioManager.pay_with_cash(amount):
		if bill_name == "Payday Loan":
				BillManager.reduce_debt_balance("Payday Loan", amount)
		BillManager.mark_bill_paid(bill_name, date_key)
		close()
	else:
		print("❌ Not enough cash")

func _on_pay_by_credit_button_pressed() -> void:
	var required_score = PortfolioManager.CREDIT_REQUIREMENTS.get("bills", 0)
	if PortfolioManager.credit_score < required_score:
		print("❌ Credit score too low")
		WindowManager.focus_window(window_frame)
		WindowManager.launch_app_by_name("OwerView")
		return

	if PortfolioManager.pay_with_credit(amount):
		if bill_name == "Payday Loan":
			BillManager.reduce_debt_balance("Payday Loan", amount)
		BillManager.mark_bill_paid(bill_name, date_key)
		close()
	else:
		print("❌ Not enough credit")
		WindowManager.focus_window(window_frame)
		WindowManager.launch_app_by_name("OwerView")

func _on_autopay_check_box_toggled(toggled_on: bool) -> void:
		BillManager.autopay_enabled = toggled_on

func _on_autopay_changed(enabled: bool) -> void:
		autopay_checkbox.set_pressed_no_signal(enabled)


# --- SAVE SUPPORT ---

func get_custom_save_data() -> Dictionary:
	return {
			"bill_name": bill_name,
			"amount": amount,
			"date_key": date_key
	}

func load_custom_save_data(data: Dictionary) -> void:
	bill_name = data.get("bill_name", "")
	amount = data.get("amount", 0.0)
	date_key = data.get("date_key", TimeManager.get_formatted_date())
	interest_rate = PortfolioManager.credit_interest_rate
	total_with_interest = amount * (1.0 + interest_rate)
	_update_display()

	BillManager.register_popup(self, date_key)
	await ready
	var window: WindowFrame = window_frame
	if window:
		window.window_can_close = false
		window.refresh_window_controls()
		window.set_size(Vector2(400,480))
