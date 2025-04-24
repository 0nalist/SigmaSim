extends Node
## Autload name GameManager

# Game state variables
var god_mode: bool = false
var is_paused: bool = false
var current_profile_name: String = ""
var last_save_path: String = "user://saves/default_save.save" # Adjust path as needed

var pause_screen_instance: PauseScreen = null


# Signals for communicating with other parts of the game
signal game_over_triggered(reason: String)

# On ready, we can hook into time or UI systems
func _ready():
	# Set up any necessary listeners or defaults here
	#print("Game Manager initialized")
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.toggle_pause_screen()


# Trigger Game Over with a reason
func trigger_game_over(reason: String) -> void:
	if god_mode:
		print("Game Over skipped due to god_mode")
		return

	# Pause the game
	is_paused = true
	TimeManager.set_time_paused(true)

	# Launch the GameOver screen
	var popup = preload("res://components/popups/game_over.tscn").instantiate()
	get_tree().get_root().add_child(popup)
	popup.reason = reason
	popup.connect("delete_save_pressed", _on_delete_save)
	popup.connect("reload_save_pressed", _on_reload_save)
	popup.connect("continue_pressed", _on_continue_with_infinite_credit)
	
	

# Handle delete save action
func _on_delete_save():
	SaveManager.delete_save(PlayerManager.get_slot_id())
	load_main_menu()

# Handle reload save action
func _on_reload_save():
	SaveManager.load_profile(current_profile_name)
	# Could also add a state to reset UI or re-initialize game objects

# Handle infinite credit mode
func _on_continue_with_infinite_credit():
	god_mode = true
	is_paused = false
	TimeManager.set_time_paused(false)
	# You might want to show a confirmation that this is a cheating mode
	print("Continuing with infinite credit...")

## Pause menu actions

func toggle_pause_screen():
	if pause_screen_instance and is_instance_valid(pause_screen_instance):
		# Pause screen is open, so close it and resume time
		TimeManager.set_time_paused(false)
		pause_screen_instance.queue_free()
		pause_screen_instance = null
	else:
		# Show and pause
		TimeManager.set_time_paused(true)
		pause_screen_instance = preload("res://components/popups/pause_screen.tscn").instantiate()
		get_tree().get_root().add_child(pause_screen_instance)

		pause_screen_instance.connect("sleep_pressed", _on_pause_sleep)
		pause_screen_instance.connect("logout_pressed", _on_pause_logout)
		pause_screen_instance.connect("shutdown_pressed", _on_pause_shutdown)
		pause_screen_instance.connect("resume_pressed", _on_pause_resume)
		pause_screen_instance.connect("save_pressed", _on_pause_save)


func _on_pause_resume():
	TimeManager.set_time_paused(false)
	_close_pause_screen()

func _on_pause_save():
	SaveManager.save_to_slot(PlayerManager.get_slot_id())
	print("💾 Game saved from pause menu")


func _on_pause_sleep():
	TimeManager.set_time_paused(false)
	TimeManager.sleep_for(8 * 60)  # 8 hours
	_close_pause_screen()

func _on_pause_logout():
	TimeManager.set_time_paused(false)
	load_main_menu()

func _on_pause_shutdown():
	get_tree().quit()

func _close_pause_screen():
	if pause_screen_instance and is_instance_valid(pause_screen_instance):
		pause_screen_instance.queue_free()
		pause_screen_instance = null





# Scene transition helpers
func load_main_menu():
	# Switch to main menu scene
	var main_menu_scene: PackedScene = preload("res://components/ui/log_in_ui.tscn")
	get_tree().change_scene_to_packed(main_menu_scene)

func load_new_game():
	# Start a new game with a clean slate
	SaveManager.create_new_profile("NewPlayer")  # Or handle logic for new game
	load_main_menu()  # Or switch directly to game world scene if needed

# Save and load functionality (optional, depends on how you handle it)
func save_game():
	SaveManager.save_profile(current_profile_name)

func load_game():
	SaveManager.load_profile(current_profile_name)
