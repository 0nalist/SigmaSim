extends Node
# Autoload name SaveManager

const SAVE_DIR := "user://saves/"
const INDEX_PATH := SAVE_DIR + "save_index.json"

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
	
	PlayerManager.user_data = user_data.duplicate(true)
	PlayerManager.set_slot_id(slot_id)

	var background = user_data.get("background", "")
	if background != "":
		PlayerManager.apply_background_effects(background)

	''' Not sure if this is needed
	BillManager.load_from_data({
			"autopay_enabled": false,
			"lifestyle_categories": BillManager.lifestyle_categories,
			"lifestyle_indices": BillManager.lifestyle_indices,
			"pane_data": []
		})
	'''

	save_to_slot(slot_id)


# --- Save/Load Full Game State ---
func save_to_slot(slot_id: int) -> void:
	if slot_id <= 0:
		push_error("❌ Invalid slot_id: %d" % slot_id)
		return

	var data := {
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
	metadata[slot_key]["profile_picture_path"] = player_data.get("profile_picture_path", "res://assets/profiles/default.png")
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
	reset_managers()
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		push_error("Save file was malformed or corrupted.")
		return

	var data: Dictionary = result

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
	if data.has("player"):
		PlayerManager.load_from_data(data["player"])
		PlayerManager.set_slot_id(slot_id)
	if data.has("workers"):
		WorkerManager.load_from_data(data["workers"])
	
	if data.has("gpus"):
		GPUManager.load_from_data(data["gpus"])
	if data.has("bills"):
		BillManager.load_from_data(data["bills"])


	if data.has("windows"): ##Always load windows last (I think)
		WindowManager.load_from_data(data["windows"])

func reset_game_state() -> void:
	# Reset all relevant managers to blank state
	PortfolioManager.reset()
	PlayerManager.reset()
	WindowManager.reset()
	TimeManager.reset()
	TaskManager.reset()
	EffectManager.reset()
	WorkerManager.reset()
	MarketManager.reset()
	GPUManager.reset()
	#BillManager.reset()
	#UpgradeManager.reset()



func reset_managers():
	PortfolioManager.reset()
	PlayerManager.reset()
	WindowManager.reset()
	TimeManager.reset()
	WorkerManager.reset()
	EffectManager.reset()
	TaskManager.reset()
	GPUManager.reset()
	EffectManager.reset()

func delete_save(slot_id: int) -> void:
	var path := get_slot_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var metadata = load_slot_metadata()
	metadata.erase("slot_%d" % slot_id)
	save_slot_metadata(metadata)

# --- Helper Functions ---
func vector2_to_dict(v: Vector2) -> Dictionary:
	return { "x": v.x, "y": v.y }

func dict_to_vector2(d: Dictionary, default := Vector2.ZERO) -> Vector2:
	if typeof(d) != TYPE_DICTIONARY:
		return default
	return Vector2(d.get("x", default.x), d.get("y", default.y))
