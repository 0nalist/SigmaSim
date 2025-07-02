@icon("res://assets/prof_pics/silhouette.png")

class_name NPC
extends Resource


# === Identity ===
@export var full_name: String
@export var first_name: String
@export var middle_initial: String
@export var last_name: String
@export var username: String
@export var profile_pic: Texture2D
@export var gender_vector: Vector3 = Vector3(0, 0, 1) # x: femme, y: masc, z: enby

# === Personality & Stats ===
@export_range(0, 100, 0.1) var alpha: float = 0.0
@export_range(0, 100, 0.1) var beta: float = 0.0
@export_range(0, 100, 0.1) var gamma: float = 0.0
@export_range(0, 100, 0.1) var delta: float = 0.0
@export_range(0, 100, 0.1) var omega: float = 0.0
@export_range(0, 100, 0.1) var sigma: float = 0.0

# === Relationship with Player ===
var relationship_status: String = "single af"
@export_range(-100, 100, 0.1) var affinity: float = 0.0
@export_range(0, 100, 0.1) var rizz: int
@export_range(0, 100, 0.1) var attractiveness: int
var _is_dating_player: bool = false

var is_dating_player: bool:
	get: return _is_dating_player
	set(value):
		_is_dating_player = value
		if value:
			add_status("dating_player")
		else:
			remove_status("dating_player")

# === Employment ===
@export var occupation: String = "Funemployed"
var _is_employee: bool = false

var is_employee: bool:
	get: return _is_employee
	set(value):
		_is_employee = value
		if value:
			add_status("employee")
		else:
			remove_status("employee")

# === Economics ===
var income: int
var wealth: int

# === Preferences ===
@export var preferred_pet_names: Array[String] = []
@export var player_pet_names: Array[String] = []
@export var likes: Array[String]

# === Tags ===
@export var tags: Array[String] = ["alive"]         # Intrinsic/archetypal tags
var status_tags := {}                               # Dynamic/boolean-synced status tags

# === Dialogue & Social ===
@export var fumble_bio: String
@export var wall_posts: Array[String] = ["hello world"]

# === Utility Methods ===
func get_full_name() -> String:
	return "%s %s. %s" % [first_name, middle_initial, last_name]

func describe_gender() -> String:
	var components = []
	if gender_vector.x > 0.5:
		components.append("feminine")
	if gender_vector.y > 0.5:
		components.append("masculine")
	if gender_vector.z > 0.5:
		components.append("enby")
	return ", ".join(components) if components.size() > 0 else "ambiguous"

# === Status Tag Sync ===
func has_status(tag: String) -> bool:
	return status_tags.has(tag)

func add_status(tag: String, meta = {}) -> void:
	status_tags[tag] = meta

func remove_status(tag: String) -> void:
	status_tags.erase(tag)
