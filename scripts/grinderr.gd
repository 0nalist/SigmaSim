extends Window

var subcontract_price: int = 10
var subcontractor_dps: int = 1
var subcontractors: int = 0
@onready var subcontractor_timer: Timer = $SubcontractorTimer


func _ready() -> void:
	self.close_requested.connect(_on_close_requested)

func _on_close_requested():
	hide()


func _on_grind_button_pressed() -> void:
	MoneyManager.add_cash(1)


func _on_subcontract_third_world_grinder_button_pressed() -> void:
	if MoneyManager.cash < subcontract_price:
		print("insufficient cash!")
		return
	MoneyManager.spend_cash(10)
	add_subcontractor(subcontractor_dps)

func add_subcontractor(dps):
	subcontractors += 1
	%SubcontractorLabel.text = "Subcontractors: " + str(subcontractors)
	subcontract_price *= 1.5
	%SubcontractThirdWorldGrinderButton.text = "Subcontract Third World Grinder
$" + str(subcontractor_dps) + "/s for $" + str(subcontract_price)
	MoneyManager.add_passive_income(dps)

func _on_subcontractor_timer_timeout() -> void:
	if subcontractor_dps < 1:
		return
	MoneyManager.add_cash(subcontractors*subcontractor_dps)
	
