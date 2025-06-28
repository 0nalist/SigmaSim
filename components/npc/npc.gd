@icon("res://assets/prof_pics/silhouette.png")

class_name NPC
extends Resource

# === Basic Info ===
@export var full_name: String
@export var first_name: String
@export var middle_initial: String
@export var last_name: String
@export var gender_vector: Vector3 = Vector3(0, 0, 1) # x: femme, y: masc, z: enby

@export var username: String
@export var profile_pic: Texture2D

#@export_multiline var bio: String

@export var occupation: String = "Funemployed"

@export var relationship_status: String = "Single"

# Relationship with Player
@export_range(-100, 100, 0.1) var affinity: float = 0.0 # 0–100
@export_range(0, 100, 0.1) var rizz: int
@export_range(0, 100, 0.1) var attractiveness: int


# === Economics ===
var income: int
var wealth: int

# Pet Names
@export var preferred_pet_names: Array[String] = []
@export var player_pet_names: Array[String] = []

# === Stats (Greek) ===
@export_range(0, 100, 0.1) var alpha: float = 0.0
@export_range(0, 100, 0.1) var beta: float = 0.0
@export_range(0, 100, 0.1) var gamma: float = 0.0
@export_range(0, 100, 0.1) var delta: float = 0.0
@export_range(0, 100, 0.1) var omega: float = 0.0
@export_range(0, 100, 0.1) var sigma: float = 0.0


# === Tags / Attributes ===
@export var tags: Array[String] = ["alive"] 
@export var likes: Array[String]

@export var fumble_bio: String


# === Wall Posts / Social Feed ===
@export var wall_posts: Array[String] = ["hello world"]


# === M E T H O D S === #
func get_full_name() -> String:
	return "%s %s. %s" % [first_name, middle_initial, last_name]

func describe_gender() -> String:
	# Returns a descriptive label for the gender vector
	var components = []
	if gender_vector.x > 0.5:
		components.append("feminine")
	if gender_vector.y > 0.5:
		components.append("masculine")
	if gender_vector.z > 0.5:
		components.append("enby")
	return ", ".join(components) if components.size() > 0 else "ambiguous"
