extends PanelContainer
class_name TaskCard

signal task_pressed(task: WorkerTask)

@onready var short_task_name_label: Label = %ShortTaskNameLabel
@onready var progress_label: Label = %ProgressLabel
@onready var payout_label: Label = %PayoutLabel
@onready var worker_label: Label = %WorkoutLabel
@onready var button: Button = %Button

var task: WorkerTask

func setup(t: WorkerTask):
	task = t
	_refresh()

	# Reactively update when task changes
	if not task.task_updated.is_connected(_refresh):
		task.task_updated.connect(_refresh)

	button.pressed.connect(func():
		task_pressed.emit(task)
	)

func _refresh():
	short_task_name_label.text = _shorten_name(task.title)
	progress_label.text = "%.0f / %.0f" % [task.current_productivity, task.productivity_required]
	payout_label.text = "💰 $%.2f" % task.payout_amount
	worker_label.text = "👷 %d" % task.assigned_workers.size()

func _shorten_name(name: String) -> String:
	return name if name.length() <= 18 else name.substr(0, 15) + "..."
