extends BasePopupUI
class_name BillPopupUI

var bill_name: String = ""
var amount: int = 0
var interest_rate: float = 0.0
var total_with_interest: float = 0.0



func init(name: String) -> void:
	set_meta("class_name", "BillPopupUI")
	bill_name = name
	amount = BillManager.get_bill_amount(name)
	interest_rate = PortfolioManager.credit_interest_rate
	total_with_interest = amount * (1.0 + interest_rate)
	%BillLabel.text = "%s \n $%.2f" % [bill_name, amount]
	%InterestLabel.text = "Paying with credit will cost $%.2f total at %.0f%% interest" % [
		total_with_interest,
		interest_rate * 100
	]


func _ready() -> void:
	window_can_close = false
	window_can_minimize = false
	

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
