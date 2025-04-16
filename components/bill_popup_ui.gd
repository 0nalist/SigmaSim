extends BasePopupUI

var bill_name: String = ""
var amount: int = 0


func init(name: String) -> void:
	bill_name = name
	amount = BillManager.get_bill_amount(name)
	%BillLabel.text = "Bill Due: %s — $%.2f" % [bill_name, amount]


func _ready() -> void:
	window_can_close = false
	window_can_minimize = false
	


func _on_pay_now_button_pressed() -> void:
	print("pay now")


func _on_pay_by_credit_button_pressed() -> void:
	print("pay credit")
