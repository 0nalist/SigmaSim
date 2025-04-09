extends BaseAppUI
class_name MinerrUI

@onready var gpus_label: Label = %GPUsLabel

func _ready() -> void:
	# Connect to a custom GPUManager signal (we'll add this in a moment)
	GPUManager.gpus_changed.connect(update_gpu_label)

	# Initial update
	update_gpu_label()

func update_gpu_label() -> void:
	var total_gpus: int = GPUManager.get_total_gpu_count()
	var free_gpus: int = GPUManager.get_free_gpu_count()
	gpus_label.text = "GPUs: %d / %d" % [free_gpus, total_gpus]
