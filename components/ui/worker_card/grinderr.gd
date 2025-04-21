extends BaseAppUI
class_name Grinderr

@onready var tab_container: TabContainer = %TabContainer
@onready var hire_list: VBoxContainer = %HireList



func _ready() -> void:
	#default_window_size = Vector2(350, 420)
	app_title = "Grinderr"
	app_icon = preload("res://assets/Tralalero_tralala.png")
	emit_signal("title_updated", app_title)
	_populate_hire_tab()

func _populate_hire_tab():
	print("populate hire tab")
	for child in hire_list.get_children():
		child.queue_free()
	for worker in WorkerManager.available_workers:
		
		var row := _create_hire_row(worker)
		hire_list.add_child(row)

func _create_hire_row(worker: Worker) -> Control:
	var card = preload("res://components/ui/worker_card/worker_card.tscn").instantiate()
	card.show_cost = true
	card.button_label = "Hire"
	card.setup(worker)
	card.action_pressed.connect(func(w):
		var cost = w.sign_on_bonus + w.day_rate
		if PortfolioManager.attempt_spend(cost):
			WorkerManager.hire_worker(w)
			WorkerManager.available_workers.erase(w)
			_populate_hire_tab()
		else:
			print("Not enough funds!")
	)
	return card
