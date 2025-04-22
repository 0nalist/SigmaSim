extends BasePopupUI
class_name GigPopup

@onready var title_label = %TitleLabel
@onready var progress_bar = %ProgressBar
@onready var payout_label = %PayoutLabel
@onready var limit_label = %LimitLabel
@onready var completions_label = %CompletionsLabel
@onready var selected_worker_label: Label = %SelectedWorkerLabel
@onready var worker_list = %WorkerList
@onready var assign_button: Button = %AssignButton
@onready var grind_button: Button = %GrindButton

var gig: WorkerTask

#var last_displayed_progress: float = 0.0
#var last_completions: int = 0
var last_productivity: float = 0.0
var pending_reset: bool = false

func setup(gig_ref: WorkerTask) -> void:
	gig = gig_ref

	title_label.text = gig.title
	payout_label.text = "Payout: $%.2f" % gig.payout_amount
	completions_label.text = "Completed: %d" % gig.completions_done

	if gig.completion_limit == -1:
		limit_label.text = "Unlimited completions"
	else:
		limit_label.text = "Limit: %d" % gig.completion_limit

	_refresh_progress()
	_refresh_workers()
	_refresh_selected_worker()
	gig.productivity_applied.connect(_on_productivity_applied)
	assign_button.pressed.connect(_on_assign_worker_pressed)
	grind_button.pressed.connect(_on_grind_button_pressed)
	WorkerManager.worker_selected.connect(_on_worker_selected)

func _on_productivity_applied(_amount: float, _new_total: float) -> void:
	_refresh_progress()


var active_tween: Tween = null
func _refresh_progress():
	var percent := gig.get_progress_percent() * 100.0
	var completions := gig.completions_done
	var current_prod := gig.current_productivity

	# Cancel any in-progress tween
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

	# 1. If we were holding at 100 from last frame, now reset to 0 and tween up
	if pending_reset:
		progress_bar.value = 0.0
		active_tween = get_tree().create_tween()
		active_tween.tween_property(progress_bar, "value", percent, 0.3)
		pending_reset = false

	# 2. If productivity wrapped, tween to 100 and hold
	elif current_prod < last_productivity:
		if progress_bar.value < 100.0:
			active_tween = get_tree().create_tween()
			active_tween.tween_property(progress_bar, "value", 100.0, 0.25)
		else:
			progress_bar.value = 100.0
		pending_reset = true

	# 3. Normal forward progress
	else:
		active_tween = get_tree().create_tween()
		active_tween.tween_property(progress_bar, "value", percent, 0.3)

	# Completion label
	var limit_text := "∞" if gig.completion_limit == -1 else str(gig.completion_limit)
	completions_label.text = "Completions: %d / %s" % [completions, limit_text]

	last_productivity = current_prod







func _refresh_workers():
	for child in worker_list.get_children():
		child.queue_free()
	for worker in gig.assigned_workers:
		var row = HBoxContainer.new()
		var name = Label.new()
		name.text = worker.name
		var remove_button = Button.new()
		remove_button.text = "Unassign"
		remove_button.pressed.connect(func():
			gig.assigned_workers.erase(worker)
			WorkerManager.unassign_worker(worker)
			_refresh_workers()
		)
		row.add_child(name)
		row.add_child(remove_button)
		worker_list.add_child(row)


func _on_worker_selected(worker: Worker) -> void:
	_refresh_selected_worker()

func _refresh_selected_worker():
	var worker = WorkerManager.currently_selected_worker
	if worker != null:
		selected_worker_label.text = "Selected: " + worker.name
		assign_button.text = "Assign " + worker.name
	else:
		selected_worker_label.text = "Selected: None"
		assign_button.text = "Assign Worker"
	#assign_button.disabled = false


func _on_assign_worker_pressed():
	var worker = WorkerManager.currently_selected_worker
	if worker == null:
		# Open WorkForce to let the user select one
		WindowManager.launch_app_by_name("WorkForce")
		return

	if gig.assigned_workers.has(worker):
		print("Worker already assigned to this gig")
		return

	gig.assigned_workers.append(worker)
	WorkerManager.assign_worker(worker, gig)
	_refresh_selected_worker()
	_refresh_workers()



func _on_grind_button_pressed():
	gig.apply_productivity(1.0)
	_refresh_progress()
