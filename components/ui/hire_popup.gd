extends Pane
class_name HirePopup

@onready var hire_list: VBoxContainer = %HireList
@onready var hire_sort_dropdown: OptionButton = %HireSortDropdown
@onready var hire_high_low_button: Button = %HireHighLowButton

var hire_sort_property: String = "productivity"
var hire_sort_descending: bool = true

func _ready() -> void:
	WorkerManager.available_workers_updated.connect(_populate_hire_tab)
	hire_sort_dropdown.item_selected.connect(_on_hire_sort_property_changed)
	hire_high_low_button.pressed.connect(_on_hire_high_low_button_pressed)

	_init_dropdown()
	_populate_hire_tab()

func _populate_hire_tab() -> void:
	for child in hire_list.get_children():
		child.queue_free()

	var sorted_workers = WorkerManager.sort_workers_by(hire_sort_property, hire_sort_descending)
	for worker in sorted_workers:
		var card := preload("res://components/ui/worker_card/worker_card_redux.tscn").instantiate()
		card.show_cost = true
		card.show_status = false
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
		hire_list.add_child(card)

func _init_dropdown() -> void:
	hire_sort_dropdown.add_item("Productivity", 0)
	hire_sort_dropdown.add_item("Day Rate", 1)
	hire_sort_dropdown.add_item("Productivity / Day Rate", 2)
	hire_sort_dropdown.add_item("Type (Employee/Contractor)", 3)

func _on_hire_sort_property_changed(index: int) -> void:
	match index:
		0: hire_sort_property = "productivity"
		1: hire_sort_property = "day_rate"
		2: hire_sort_property = "productivity_per_day_rate"
		3: hire_sort_property = "type"
	_populate_hire_tab()

func _on_hire_high_low_button_pressed() -> void:
	hire_sort_descending = !hire_sort_descending
	_populate_hire_tab()
