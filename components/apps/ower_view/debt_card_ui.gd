extends PanelContainer
class_name DebtCardUI

@onready var name_label: Label = %NameLabel
@onready var amount_label: Label = %AmountLabel

var resource_name: String = ""
var amount: float = 0.0

func setup(resource_name_param: String, amount_param: float) -> void:
	resource_name = resource_name_param
	amount = amount_param
	name_label.text = resource_name
	amount_label.text = "$" + String.num(amount, 2)
