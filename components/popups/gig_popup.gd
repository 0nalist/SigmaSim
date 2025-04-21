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


func _refresh_progress():
	progress_bar.value = gig.get_progress_percent() * 100.0
	#progress_bar.text = "%.1f / %.1f" % [gig.current_productivity, gig.productivity_required]

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
	else:
		selected_worker_label.text = "Selected: None"
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
