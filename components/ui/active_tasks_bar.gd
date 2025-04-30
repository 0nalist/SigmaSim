extends Control
class_name ActiveTasksBar

@export var task_source_category: String = "grinderr"  # default to "grinderr"
@export var gig_popup_scene: PackedScene
@export var task_card_scene: PackedScene

@onready var task_list: HFlowContainer = %TaskList

var task_to_button: Dictionary = {}  # Map each WorkerTask to its button

func _ready() -> void:
	_refresh_tasks()

	TimeManager.minute_passed.connect(_on_minute_passed)
	WorkerManager.worker_assigned.connect(func(_worker: Worker, _task: WorkerTask):
		_refresh_tasks()
	)
	WorkerManager.worker_idle.connect(func(_worker: Worker):
		_refresh_tasks()
	)

func _on_minute_passed(_in_game_minutes: int) -> void:
	_refresh_tasks()

func _refresh_tasks() -> void:
	task_to_button.clear()

	for child in task_list.get_children():
		child.queue_free()

	var tasks = TaskManager.get_tasks(task_source_category)

	for task in tasks:
		if task.assigned_workers.is_empty():
			continue  # Skip tasks without workers assigned

		var button = _create_task_button(task)
		task_list.add_child(button)
		task_to_button[task] = button

	_update_button_states()
	#_update_button_texts()

func _create_task_button(task: WorkerTask) -> TaskCard:
	var card = task_card_scene.instantiate() as TaskCard
	card.call_deferred("setup", task)

	#card.button.toggle_mode = true
	#card.button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	#card.button.focus_mode = Control.FOCUS_NONE

	card.task_pressed.connect(func(t):
		TaskManager.set_assignment_target(t)
		_open_task_popup(t)
	)

	return card



func _open_task_popup(task: WorkerTask) -> void:
	if not gig_popup_scene:
		push_error("ActiveTasksBar: No gig_popup_scene assigned!")
		return

	var key := "task_" + task.title

	var existing := WindowManager.find_popup_by_key(key)
	if existing:
		WindowManager.focus_window(existing)
		return

	var popup_pane := gig_popup_scene.instantiate() as Pane
	popup_pane.unique_popup_key = key  # Needed for WindowManager tracking

	var window := WindowFrame.instantiate_for_pane(popup_pane)
	WindowManager.register_window(window, popup_pane.show_in_taskbar)

	call_deferred("setup_gig_popup", popup_pane, task)
	WindowManager.call_deferred("autoposition_window", window)


func setup_gig_popup(pane: Pane, task: WorkerTask) -> void:
	if is_instance_valid(pane) and pane.has_method("setup"):
		pane.setup(task)



func _on_assignment_target_changed(new_target: Node) -> void:
	_update_button_states()

func _update_button_states() -> void:
	for task in task_to_button.keys():
		var card = task_to_button[task]
		if not is_instance_valid(card):
			continue
		card.set_selected(TaskManager.active_assignment_target == task)
		card.button.set_pressed_no_signal(TaskManager.active_assignment_target == task)



func _update_button_texts() -> void:
	for task in task_to_button.keys():
		var button = task_to_button[task]
		if not is_instance_valid(button):
			continue
		#button.text = "%.2f / %.2f" % [task.current_productivity, task.productivity_required]
		button.text = "%.2f / %.2f" % [round(task.current_productivity), round(task.productivity_required)]
