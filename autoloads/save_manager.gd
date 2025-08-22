extends Node
# Autoload name SaveManager

const SAVE_DIR := "user://saves/"
const INDEX_PATH := SAVE_DIR + "save_index.json"

var current_slot_id: int = -1


func _ready():
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")


# --- Slot Path ---
func get_slot_path(slot_id: int) -> String:
	return SAVE_DIR + "save_slot_%d.json" % slot_id


# --- Metadata Storage ---
func save_slot_metadata(metadata: Dictionary) -> void:
	var file := FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "\t"))
	file.close()


func load_slot_metadata() -> Dictionary:
	if not FileAccess.file_exists(INDEX_PATH):
		return {}
	var file := FileAccess.open(INDEX_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	return parsed if parsed != null else {}


func get_profile_metadata(slot_id: int) -> Dictionary:
	var metadata = load_slot_metadata()
	return metadata.get("slot_%d" % slot_id, {})


func get_next_available_slot() -> int:
	var metadata = load_slot_metadata()
	var i := 1
	while metadata.has("slot_%d" % i):
		i += 1
	return i


func initialize_new_profile(slot_id: int, user_data: Dictionary) -> void:
	if slot_id <= 0:
		push_error("❌ Invalid slot_id: %d" % slot_id)
		return

	reset_managers()
	BillManager.is_loading = true
	current_slot_id = slot_id

		# Respect an existing seed when creating a new profile. If no seed is
		# provided (or it's 0), derive one from the user's password using the
		# djb2 hash. Only fall back to the current Unix time when a password is
		# unavailable. This avoids overwriting the deterministic seed generated
		# during profile creation.
	var seed_val: int = user_data.get("global_rng_seed", 0)
	print("initialize_new_profile: existing seed", seed_val)
	if seed_val == 0:
		var password = user_data.get("password", "")
		if password != "":
			seed_val = PlayerManager.djb2(password)
			print("Derived seed from password", password, "->", seed_val)
		else:
			seed_val = int(Time.get_unix_time_from_system())
			print("No password; using unix time seed", seed_val)
		user_data["global_rng_seed"] = seed_val
	else:
		print("Using provided global_rng_seed", seed_val)

	RNGManager.init_seed(int(seed_val))
	print("RNGManager initialized in new profile with seed", seed_val)
	PlayerManager.user_data = user_data.duplicate(true)
	PlayerManager.ensure_default_stats()

	var background = user_data.get("background", "")
	if background != "":
		PlayerManager.apply_background_effects(background)

	var starting_debt = user_data.get("starting_student_debt", 0.0)
	PortfolioManager.set_student_loans(starting_debt)

	var starting_credit_limit = user_data.get("starting_credit_limit", 0.0)
	PortfolioManager.set_credit_limit(starting_credit_limit)

	BillManager.add_debt_resource({
		"name": "Credit Card",
		"balance": 0.0,
		"has_credit_limit": true,
		"credit_limit": starting_credit_limit
	})
	if starting_debt > 0.0:
		BillManager.add_debt_resource({
			"name": "Student Loan",
			"balance": starting_debt,
			"has_credit_limit": false,
			"credit_limit": 0.0
		})

	save_to_slot(slot_id)


# --- Save/Load Full Game State ---
func save_to_slot(slot_id: int) -> void:
	if slot_id <= 0:
		push_error("❌ Invalid slot_id: %d" % slot_id)
		return


# Ensure any pending NPC updates (like gift/date cost changes) are written to the database before saving the slot.
	if NPCManager != null:
			NPCManager._flush_save_queue()


	var data := {
		"stats": StatManager.get_save_data(),
		"portfolio": PortfolioManager.get_save_data(),
		"time": TimeManager.get_save_data(),
		"market": MarketManager.get_save_data(),
		"tasks": TaskManager.get_save_data(),
		"player": PlayerManager.get_save_data(),
		"workers": WorkerManager.get_save_data(),
		"bills": BillManager.get_save_data(),
		"gpus": GPUManager.get_save_data(),
		"upgrades": UpgradeManager.get_save_data(),
		"windows": WindowManager.get_save_data(),
		"desktop": DesktopLayoutManager.get_save_data(),
	}

	var file := FileAccess.open(get_slot_path(slot_id), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	var metadata = load_slot_metadata()
	var slot_key = "slot_%d" % slot_id
	if not metadata.has(slot_key):
		metadata[slot_key] = {}

	var player_data = PlayerManager.get_save_data()
	metadata[slot_key]["name"] = player_data.get("name", "Unnamed")
	metadata[slot_key]["username"] = player_data.get("username", "user")
	metadata[slot_key]["password"] = player_data.get("password", "")
	metadata[slot_key]["portrait_config"] = player_data.get("portrait_config", {})
	metadata[slot_key]["background_path"] = player_data.get("background_path", "")
	metadata[slot_key]["last_played"] = Time.get_datetime_string_from_system()
	metadata[slot_key]["cash"] = PortfolioManager.cash

	save_slot_metadata(metadata)


func load_from_slot(slot_id: int) -> void:
	if slot_id <= 0:
		push_error("❌ Invalid slot_id: %d" % slot_id)
		return

	var path = get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return

	# Flush NPC save queue so dynamic fields aren't lost when switching slots.
	if NPCManager != null:
			NPCManager._flush_save_queue()

	reset_managers()
	BillManager.is_loading = true
	current_slot_id = slot_id

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		push_error("Save file was malformed or corrupted.")
		return

	var data: Dictionary = result

	if data.has("player"):
		PlayerManager.load_from_data(data["player"])
		var seed_val: int = PlayerManager.user_data.get("global_rng_seed", 0)
		print("load_from_slot: stored seed", seed_val)
		if seed_val == 0:
			var password = PlayerManager.user_data.get("password", "")
			if password != "":
				seed_val = PlayerManager.djb2(password)
				print("Derived seed from password", password, "->", seed_val)
			else:
				seed_val = int(Time.get_unix_time_from_system())
				print("No seed or password; using unix time seed", seed_val)
			PlayerManager.user_data["global_rng_seed"] = seed_val
		else:
			print("Using saved global_rng_seed", seed_val)
		RNGManager.init_seed(seed_val)
		print("RNGManager initialized from save with seed", seed_val)

	if data.has("stats"):
			StatManager.load_from_data(data["stats"])
	if data.has("portfolio"):
			PortfolioManager.load_from_data(data["portfolio"])
	if data.has("time"):
			TimeManager.load_from_data(data["time"])
			TimeManager.start_time()
	if data.has("upgrades"):
			UpgradeManager.load_from_data(data["upgrades"])
	if data.has("tasks"):
			TaskManager.load_from_data(data["tasks"])
	if data.has("market"):
			MarketManager.load_from_data(data["market"])

	if data.has("workers"):
			WorkerManager.load_from_data(data["workers"])
	if data.has("gpus"):
			GPUManager.load_from_data(data["gpus"])
	if data.has("bills"):
			BillManager.load_from_data(data["bills"])
	if data.has("desktop"):
			DesktopLayoutManager.load_from_data(data["desktop"])
	if data.has("windows"):  # Always load windows last
			WindowManager.load_from_data(data["windows"])
	BillManager.is_loading = false
	BillManager.show_due_popups()


func reset_game_state() -> void:
	# Reset all relevant managers to blank state
	PlayerManager.reset()
	StatManager.reset()
	PortfolioManager.reset()
	WindowManager.reset()
	TimeManager.reset()
	TaskManager.reset()
	UpgradeManager.reset()
	WorkerManager.reset()
	MarketManager.reset()
	GPUManager.reset()
	BillManager.reset()
	NPCManager.reset()
	DesktopLayoutManager.reset()

func reset_managers():
	PlayerManager.reset()
	StatManager.reset()
	PortfolioManager.reset()
	WindowManager.reset()
	TimeManager.reset()
	WorkerManager.reset()
	TaskManager.reset()
	UpgradeManager.reset()
	GPUManager.reset()
	BillManager.reset()
	NPCManager.reset()
	DesktopLayoutManager.reset()

func delete_save(slot_id: int) -> void:
	if slot_id == current_slot_id:
		reset_managers()
		current_slot_id = -1
	var path := get_slot_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DBManager != null:
		DBManager.delete_slot_data(slot_id)
	var metadata = load_slot_metadata()
	metadata.erase("slot_%d" % slot_id)
	save_slot_metadata(metadata)


# --- Helper Functions ---
func vector2_to_dict(v: Vector2) -> Dictionary:
	return {"x": v.x, "y": v.y}


func dict_to_vector2(d: Dictionary, default := Vector2.ZERO) -> Vector2:
	if typeof(d) != TYPE_DICTIONARY:
		return default
	return Vector2(d.get("x", default.x), d.get("y", default.y))
