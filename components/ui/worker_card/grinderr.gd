extends Pane
class_name Grinderr

@export var gig_popup_scene: PackedScene
@export var hire_popup_scene: PackedScene

#@export var available_gig_files: Array[WorkerTask] = []

var task_pools: Dictionary = {}  # category → Array[WorkerTask]

var sort_property: String = "payout_amount"
var sort_descending := true
@onready var high_low_button: Button = %HighLowButton
@onready var sort_dropdown: OptionButton = %SortDropdown




var max_daily_gigs := 3

var daily_gigs: Array[WorkerTask] = []

func _ready() -> void:

	sort_dropdown.item_selected.connect(_on_sort_property_changed)
	
	TimeManager.day_passed.connect(_on_day_passed)
	
	_init_dropdown()

	_load_or_initialize_gigs()
	_populate_work_tab()
	sort_gigs_by("current_productivity", true)

# --- WORK TAB --- #

func _load_or_initialize_gigs() -> void:
	var day_seed := TimeManager.current_year * 10000 + TimeManager.current_month * 100 + TimeManager.current_day
	daily_gigs = TaskManager.get_daily_gigs("grinderr", max_daily_gigs, day_seed)




func _on_day_passed(_d, _m, _y) -> void:
	_load_or_initialize_gigs()
	_populate_work_tab()





func _populate_work_tab() -> void:
	print("populating work tab")
	for child in %GigList.get_children():
		child.queue_free()

	var sorted_gigs = daily_gigs.duplicate()
	sorted_gigs.sort_custom(func(a: WorkerTask, b: WorkerTask) -> bool:
		var a_value = get_sort_value(a, sort_property)
		var b_value = get_sort_value(b, sort_property)
		return a_value > b_value if sort_descending else a_value < b_value
	)

	for gig in sorted_gigs:
		if gig.completion_limit != -1 and gig.completions_done >= gig.completion_limit:
			continue  # skip gigs that are completed to their limit
		var card = _create_gig_card(gig)
		%GigList.add_child(card)
		card.setup(gig)

func _create_gig_card(_gig: WorkerTask) -> Control:
	var card = preload("res://components/ui/gig_card/gig_card.tscn").instantiate()
	card.open_gig.connect(_on_open_gig)
	return card

func _on_open_gig(gig: WorkerTask) -> void:
	WindowManager.launch_gig_popup(gig)

func setup_gig_popup(pane: Pane, gig: WorkerTask) -> void:
	if is_instance_valid(pane):
		pane.setup(gig)

func sort_gigs_by(property: String, descending := true) -> Array[WorkerTask]:
	var gigs = TaskManager.get_tasks("grinderr")
	print("Sorting grinderr gigs by: ", property)

	gigs.sort_custom(func(a: WorkerTask, b: WorkerTask) -> bool:
		var a_value = get_sort_value(a, property)
		var b_value = get_sort_value(b, property)
		return a_value > b_value if descending else a_value < b_value
	)

	return gigs

func get_sort_value(task: WorkerTask, property: String) -> float:
	match property:
		"payout_amount": return task.payout_amount
		"productivity_required": return task.productivity_required
		"current_productivity": return task.current_productivity
		"payout_per_productivity":
			return task.payout_amount / max(task.productivity_required, 0.01)
		_: 
			print("invalid sort property")
			return 0.0

# --- DROPDOWNS --- #

func _init_dropdown():
	%SortDropdown.clear()
	%SortDropdown.add_item("Payout Amount", 0)
	%SortDropdown.add_item("Productivity Required", 1)
	%SortDropdown.add_item("Current Productivity", 2)
	%SortDropdown.add_item("Payout / Productivity", 3)

	var popup = %SortDropdown.get_popup()
	popup.add_theme_font_size_override("font_size", 12)

func _on_sort_property_changed(index: int) -> void:
	match index:
		0: sort_property = "payout_amount"
		1: sort_property = "productivity_required"
		2: sort_property = "current_productivity"
		3: sort_property = "payout_per_productivity"
	_populate_work_tab()

func _on_high_low_button_pressed() -> void:
	sort_descending = !sort_descending
	high_low_button.text = "High → Low" if sort_descending else "Low → High"
	_populate_work_tab()


func _on_hire_button_pressed() -> void:
	WindowManager.launch_pane(hire_popup_scene)
