extends Pane
class_name Grinderr

@export var gig_popup_scene: PackedScene
@export var hire_popup_scene: PackedScene

var sort_property: String = "payout_amount"
var sort_descending := true
@onready var high_low_button: Button = %HighLowButton
@onready var sort_dropdown: OptionButton = %SortDropdown

var max_daily_gigs := 3

var daily_gigs: Array[WorkerTask] = []

func _ready() -> void:

	sort_dropdown.item_selected.connect(_on_sort_property_changed)

	_init_dropdown()

	_load_or_initialize_gigs()
	_populate_work_tab()
	sort_gigs_by("payout_amount", true)

# --- WORK TAB --- #

func _load_or_initialize_gigs() -> void:
	var existing_gigs = TaskManager.get_tasks("grinderr")

	if existing_gigs.is_empty():
		var dir := DirAccess.open("res://resources/worker_tasks/grinderr_gigs/")
		if dir == null:
			printerr("Could not open gig directory.")
			return

		dir.list_dir_begin()
		var all_tasks: Array[WorkerTask] = []
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://resources/worker_tasks/grinderr_gigs/" + file_name
				var base_task: WorkerTask = load(path)
				var task := base_task.duplicate(true)
				if task is WorkerTask and task.show_in_grinderr and task.payout_type == "cash":
					all_tasks.append(task)
			file_name = dir.get_next()
		dir.list_dir_end()

		all_tasks.shuffle()
		daily_gigs = all_tasks.slice(0, max_daily_gigs)

		for task in daily_gigs:
			TaskManager.register_task("grinderr", task)
	else:
		# Only treat saved tasks as daily_gigs
		daily_gigs = existing_gigs
		

func _populate_work_tab() -> void:
	for child in %GigList.get_children():
		child.queue_free()

	var sorted_gigs = sort_gigs_by(sort_property, sort_descending)
	for gig in sorted_gigs:
		if gig.completion_limit != -1 and gig.completions_done >= gig.completion_limit:
			continue  # skip gigs that are completed to their limit
		var card = _create_gig_card(gig)
		%GigList.add_child(card)
		card.setup(gig)

func _create_gig_card(gig: WorkerTask) -> Control:
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
