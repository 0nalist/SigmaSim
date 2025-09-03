extends Node
## Autload name GameManager

# Game state variables
var god_mode: bool = false
var is_paused: bool = false
#var current_profile_slot: int = -1
var last_save_path: String = "user://saves/default_save.save" # Adjust path as needed
var in_game: bool = false


var pause_screen_instance: PauseScreen = null

# Signals for communicating with other parts of the game
signal game_over_triggered(reason: String)

# On ready, we can hook into time or UI systems
func _ready():
		NPCFactory.load_tag_data("res://data/npc_data/traits/tags.json")
		NPCFactory.load_like_data("res://data/npc_data/traits/likes.json")
		NPCFactory.load_fumble_bios("res://data/npc_data/traits/fumble_bios.json")
		NPCFactory.load_job_data("res://data/npc_data/traits/jobs.json")

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
	SaveManager.delete_save(SaveManager.current_slot_id)
	SaveManager.current_slot_id = -1
	#TODO: Shift other save slots to fill gaps (eg. if slot 1 is deleted, slot 2 becomes slot 1)
	reset_managers()

	load_login_screen()

func reset_managers() -> void:
	StatManager.reset()
	PortfolioManager.reset()
	PlayerManager.reset()
	WindowManager.reset()
	TaskManager.reset()
	UpgradeManager.reset()
	# Add more as systems grow
	# Add more as systems grow

func _on_reload_save():
	# Avoid errors if there's no active save slot to reload
	if SaveManager.current_slot_id <= 0:
			return
	SaveManager.load_from_slot(SaveManager.current_slot_id)

	# Close Game Over screen
	for child in get_tree().get_root().get_children():
		if child is GameOverPopup:
			child.queue_free()
			break

func _on_continue_with_infinite_credit():
	god_mode = true
	is_paused = false
	TimeManager.set_time_paused(false)

	# Grant near-infinite credit
	PortfolioManager.credit_limit = 9999999999999999

	print("Continuing with infinite credit...")

	# Close Game Over screen
	for child in get_tree().get_root().get_children():
		if child is GameOverPopup:
			child.queue_free()
			break


## Pause menu actions

func toggle_pause_screen():
	if not in_game:
		get_tree().quit()
		return
	
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
	SaveManager.save_to_slot(SaveManager.current_slot_id)
	print("Game saved from pause menu")


func _on_pause_sleep():
	TimeManager.set_time_paused(false)
	TimeManager.sleep_for(8 * 60)  # 8 hours
	_close_pause_screen()

func _on_pause_logout():
	TimeManager.set_time_paused(true)
	load_login_screen()
	_close_pause_screen()

func _on_pause_shutdown():
	get_tree().quit()

func _close_pause_screen():
	if pause_screen_instance and is_instance_valid(pause_screen_instance):
		pause_screen_instance.queue_free()
		pause_screen_instance = null





# Scene transition helpers

func load_login_screen():
	reset_managers()
	in_game = false
	TimeManager.set_time_paused(true)
	# Ensure all app and popup windows are closed when returning to the login screen
	WindowManager.close_all_windows()
	var main = get_tree().current_scene
	if main and main.has_method("show_login_ui"):
		main.show_login_ui()


func load_desktop_env(slot_id: int = SaveManager.current_slot_id):
	in_game = true
	SaveManager.current_slot_id = slot_id
	var main = get_tree().current_scene
	if main and main.has_method("show_desktop_env"):
		main.show_desktop_env(slot_id)


# Save and load functionality (optional, depends on how you handle it)
func save_game():
	SaveManager.save_profile(PlayerManager.get_slot_id())

func load_game():
	SaveManager.load_profile(PlayerManager.get_slot_id())
