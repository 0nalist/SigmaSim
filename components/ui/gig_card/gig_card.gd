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
	title_label.text = gig.title
	progress_label.text = "every %s (%.1f productivity)" % [gig.unit_name, gig.productivity_required]
	payout_label.text = "Payout: $%.2f" % gig.payout_amount
	if gig.completion_limit == -1:
		limit_label.text = "Unlimited Repeats"
	else:
		limit_label.text = "Limit: %d" % gig.completion_limit
	workers_label.text = "Workers: %d" % gig.assigned_workers.size()
	open_button.pressed.connect(func():
		WindowManager.launch_popup(gig_popup_scene, "task_" + gig.title, gig)
	)
