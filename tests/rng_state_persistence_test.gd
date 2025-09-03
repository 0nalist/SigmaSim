extends SceneTree

func _ready():
	var rng_manager = Engine.get_singleton("RNGManager")
	rng_manager.init_seed(123)
	var global_stream = rng_manager.global
	var gpu_stream = rng_manager.gpu

	var global_rng = global_stream.get_rng()
	global_rng.randi()
	var global_state = global_stream.get_state()
	var expected_global = global_rng.randi()
	global_stream.set_state(global_state)

	var gpu_rng = gpu_stream.get_rng()
	gpu_rng.randi()
	var gpu_state = gpu_stream.get_state()
	var expected_gpu = gpu_rng.randi()
	gpu_stream.set_state(gpu_state)

	var saved = rng_manager.get_save_data()
	rng_manager.init_seed(123)
	rng_manager.load_from_data(saved)

	assert(rng_manager.global.get_rng().randi() == expected_global)
	assert(rng_manager.gpu.get_rng().randi() == expected_gpu)
	print("rng_state_persistence_test passed")
	quit()
