extends BaseAppUI
class_name Grinderr

@onready var subcontractor_timer: Timer = %SubcontractorTimer
var subcontractor_template := preload("res://resources/subcontractors/subcontractor.tres")

func _ready() -> void:
	#default_window_size = Vector2(350, 420)
	app_title = "Grinderr"
	app_icon = preload("res://assets/Tralalero_tralala.png")
	emit_signal("title_updated", app_title)

	update_ui()

func _on_window_close():
	print("closegrinder")
	hide()

func _on_grind_button_pressed() -> void:
	PortfolioManager.add_cash(1)

func _on_subcontract_third_world_grinder_button_pressed() -> void:
	var cost = subcontractor_template.hire_price
	if PortfolioManager.cash < cost:
		print("insufficient cash!")
		return

	PortfolioManager.spend_cash(cost)
	PortfolioManager.hire_subcontractor(subcontractor_template)
	update_ui()

func update_ui():
	var count = PortfolioManager.get_subcontractor_count()
	var dps = PortfolioManager.get_total_dps()
	var price = subcontractor_template.hire_price

	%SubcontractorLabel.text = "Subcontractors: %d" % count
	%SubcontractThirdWorldGrinderButton.text = "Subcontract Third World Grinder\n$%.2f/s for $%.2f" % [subcontractor_template.dollar_per_second, price]

func _on_subcontractor_timer_timeout() -> void:
	PortfolioManager.update_subcontractors(subcontractor_timer.wait_time)
	PortfolioManager.add_cash(PortfolioManager.get_total_dps() * subcontractor_timer.wait_time)
	update_ui()
