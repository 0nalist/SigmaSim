extends PanelContainer

class_name GigCard

@export var gig_popup_scene: PackedScene

signal open_gig(gig: WorkerTask)

@onready var title_label = %TitleLabel
@onready var progress_label = %ProgressLabel
@onready var payout_label = %PayoutLabel
@onready var limit_label = %LimitLabel
@onready var workers_label = %WorkersLabel
@onready var open_button = %OpenButton

var gig: WorkerTask

func setup(gig_ref: WorkerTask):
	gig = gig_ref
	_update_display()

	# Connect to changes in productivity or worker assignments
	gig.task_updated.connect(_on_gig_updated)

	open_button.pressed.connect(func():
		WindowManager.launch_gig_popup(gig)
	)

func _update_display():
	title_label.text = gig.title
	progress_label.text = "every %s (%.1f productivity)" % [gig.unit_name, gig.productivity_required]
	payout_label.text = "Payout: $%.2f" % gig.payout_amount
	workers_label.text = "Workers: %d" % gig.assigned_workers.size()

	if gig.completion_limit == -1:
		limit_label.text = "Unlimited Repeats"
	else:
		var remaining = max(gig.completion_limit - gig.completions_done, 0)
		limit_label.text = "Repeats Remaining: %d" % remaining


func _on_gig_updated():
	_update_display()

	# Check if we hit the completion limit
	if gig.completion_limit != -1 and gig.completions_done >= gig.completion_limit:
		queue_free()
