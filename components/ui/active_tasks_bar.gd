extends Control
class_name ActiveTasksBar

@export var task_source_category: String = "grinderr"  # default to "grinderr"
@export var gig_popup_scene: PackedScene

@onready var task_list: HFlowContainer = %TaskList

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
	for child in task_list.get_children():
		child.queue_free()

	var tasks = TaskManager.get_tasks(task_source_category)

	for task in tasks:
		if task.assigned_workers.is_empty():
			continue  # Skip tasks without workers assigned

		var button = _create_task_button(task)
		task_list.add_child(button)

func _create_task_button(task: WorkerTask) -> Button:
	var btn := Button.new()
	btn.text = task.title
	btn.custom_minimum_size = Vector2(100, 32)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.clip_text = true
	btn.focus_mode = Control.FOCUS_NONE

	btn.pressed.connect(func():
		_open_task_popup(task)
	)

	return btn

func _open_task_popup(task: WorkerTask) -> void:
	if not gig_popup_scene:
		push_error("ActiveTasksBar: No gig_popup_scene assigned!")
		return

	var key = "task_" + task.title

	var existing_window = WindowManager.find_popup_by_key(key)
	if existing_window:
		WindowManager.focus_window(existing_window)
		return

	var popup_pane := gig_popup_scene.instantiate() as GigPopup
	popup_pane.unique_popup_key = key

	var window := WindowFrame.instantiate_for_pane(popup_pane)
	WindowManager.register_window(window, popup_pane.show_in_taskbar)

	popup_pane.call_deferred("setup", task)
	WindowManager.call_deferred("autoposition_window", window)
