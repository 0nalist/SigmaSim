extends Pane
class_name BillPopupUI

var bill_name: String = ""
var amount: float = 0.0
var interest_rate: float = 0.0
var total_with_interest: float = 0.0

var popup_type := "BillPopupUI"

@onready var bill_label: Label = %BillLabel
@onready var interest_label: Label = %InterestLabel

func _ready() -> void:
	user_movable = true
	window_title = "Bill: " + str(bill_name)
	#window_can_close = false
	#window_can_minimize = false
	# If the popup was restored after data load, manually refresh UI
	_update_display()

func init(name: String) -> void:
	bill_name = name
	amount = BillManager.get_bill_amount(name)
	interest_rate = PortfolioManager.credit_interest_rate
	total_with_interest = amount * (1.0 + interest_rate)
	_update_display()

func _update_display() -> void:
	if is_instance_valid(bill_label):
		bill_label.text = "%s\n$%.2f" % [bill_name, amount]
	if is_instance_valid(interest_label):
		interest_label.text = "Paying with credit will cost $%.2f total at %.0f%% interest" % [
			amount * (1.0 + PortfolioManager.credit_interest_rate),
			PortfolioManager.credit_interest_rate * 100
		]


func update_amount_display() -> void:
	_update_display()

func close() -> void:
	WindowManager.close_window(get_parent().get_parent().get_parent())

func _on_pay_now_button_pressed() -> void:
	if PortfolioManager.pay_with_cash(amount):
		close()
	else:
		print("❌ Not enough cash")

func _on_pay_by_credit_button_pressed() -> void:
	if PortfolioManager.pay_with_credit(amount):
		close()
	else:
		print("❌ Not enough credit")
	WindowManager.launch_app_by_name("OwerView")

# --- SAVE SUPPORT ---

func get_custom_save_data() -> Dictionary:
	return {
		"bill_name": bill_name,
		"amount": amount
	}

func load_custom_save_data(data: Dictionary) -> void:
	bill_name = data.get("bill_name", "")
	amount = data.get("amount", 0.0)
	interest_rate = PortfolioManager.credit_interest_rate
	total_with_interest = amount * (1.0 + interest_rate)
	_update_display()

	var window = get_parent().get_parent().get_parent() as WindowFrame
	if window:
		window.window_can_close = false
		window.refresh_window_controls()
		window.set_size(Vector2(400,480))
