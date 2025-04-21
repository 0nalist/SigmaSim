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

func create_new_profile(
	slot_id: int,
	profile_name: String,
	username: String,
	picture_path: String = "res://assets/profiles/default.png",
	background_path: String = "res://assets/Bliss_(Windows_XP) (2).png"
) -> void:
	var metadata = load_slot_metadata()
	metadata["slot_%d" % slot_id] = {
		"name": profile_name,
		"username": username,
		"profile_picture_path": picture_path,
		"background_path": background_path,
		"last_played": Time.get_datetime_string_from_system(),
		"cash": 0.0
	}
	save_slot_metadata(metadata)

	# Save initial data
	var data := {
		"portfolio": {},
		"time": TimeManager.get_default_save_data(),
		"windows": [],
		"player": PlayerManager.get_save_data() # If pre-creating full player state
	}
	var file := FileAccess.open(get_slot_path(slot_id), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# --- Save/Load Full Game State ---
func save_to_slot(slot_id: int) -> void:
	var data := {
		"portfolio": PortfolioManager.get_save_data(),
		"time": TimeManager.get_save_data(),
		
		"popups": WindowManager.get_popup_save_data(),
		"market": MarketManager.get_save_data(),
		"player": PlayerManager.get_save_data(),
		#"bills": BillManager.get_save_data(),
		#"npcs": NPCManager.get_save_data(),
		"windows": WindowManager.get_save_data(), # should ALWAYS be last
	}
	print("🧠 Windows to save:", WindowManager.get_save_data())

	var file := FileAccess.open(get_slot_path(slot_id), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	# Update metadata (last played time, cash)
	var metadata = load_slot_metadata()
	var slot_key = "slot_%d" % slot_id
	if not metadata.has(slot_key):
		metadata[slot_key] = {}
	metadata[slot_key]["last_played"] = Time.get_datetime_string_from_system()
	metadata[slot_key]["cash"] = PortfolioManager.cash
	save_slot_metadata(metadata)

func load_from_slot(slot_id: int) -> void:
	print("loading from slot")
	TimeManager.start_time() ## Should put this somewhere better. I need to initialize vars like time upon new profile creation
	var path = get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return

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
		
		print("told time manager to start")
	
	if data.has("bills"):
		BillManager.load_from_data(data["bills"])
	if data.has("popups"):
		WindowManager.load_popups_from_data(data["popups"])
	if data.has("market"):
		MarketManager.load_from_data(data.get("market", {}))
	if data.has("player"):
		PlayerManager.load_from_data(data["player"])
		PlayerManager.set_slot_id(slot_id)
	#if data.has("npcs"):
	#	NPCManager.load_from_data(data["npcs"])
	if data.has("windows"): # should ALWAYS be last
		WindowManager.load_from_data(data["windows"])

# --- Helper Functions ---
func vector2_to_dict(v: Vector2) -> Dictionary:
	return { "x": v.x, "y": v.y }

func dict_to_vector2(d: Dictionary, default := Vector2.ZERO) -> Vector2:
	if typeof(d) != TYPE_DICTIONARY:
		return default
	return Vector2(d.get("x", default.x), d.get("y", default.y))
