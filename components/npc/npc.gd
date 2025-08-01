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
@export var occupation: String = "Funemployed"
@export var relationship_status: String = "Single"

# Relationship with Player
@export_range(-100, 100, 0.1) var affinity: float = 0.0 # 0–100
@export_range(0, 100, 0.1) var rizz: int
@export_range(0, 100, 1) var attractiveness: int

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
@export var likes: Array[String] = []

@export var fumble_bio: String

# === Chat Battle Stats ===
@export var self_esteem: int = 70
@export var apprehension: int = 50
@export var chemistry: int = 0
@export var chat_battle_type: String

@export var ocean: Dictionary
@export var openness: float
@export var conscientiousness: float
@export var extraversion: float
@export var agreeableness: float
@export var neuroticism: float
@export var mbti: String
@export var zodiac: String

# === Wall Posts / Social Feed ===
@export var wall_posts: Array[String] = ["hello world"]

# === HELPERS ===
static func _safe_string(val, fallback := ""):
	return val if typeof(val) == TYPE_STRING and val != null else fallback

static func _safe_int(val, fallback := 0):
	return int(val) if typeof(val) in [TYPE_INT, TYPE_FLOAT] and val != null else fallback

static func _safe_float(val, fallback := 0.0):
	return float(val) if typeof(val) in [TYPE_FLOAT, TYPE_INT] and val != null else fallback

static func _safe_dict(val, fallback := {}):
			return val if typeof(val) == TYPE_DICTIONARY and val != null else fallback

static func _safe_string_array(val, fallback := []) -> Array:
	var arr: Array = []
	if val == null:
			return fallback.duplicate()
	match typeof(val):
		TYPE_ARRAY:
			for v in val:
				if typeof(v) == TYPE_STRING:
						arr.append(v)
				else:
						arr.append(str(v))
			return arr
		TYPE_STRING:
			if val.strip_edges() == "":
				return fallback.duplicate()
			var parsed = JSON.parse_string(val)
			if typeof(parsed) == TYPE_ARRAY:
				return _safe_string_array(parsed, fallback)
			for seg in val.split(","):
				var s = String(seg).strip_edges()
				if s != "":
					arr.append(s)
			return arr if arr.size() > 0 else fallback.duplicate()
		_:
			return [str(val)]


# Godot 4: Only fill arrays, never reassign!
static func _assign_string_array(target: Array, source, fallback := []) -> void:
	var arr := _safe_string_array(source, fallback)
	target.clear()
	for v in arr:
		target.append(v)

# === CONVERSION ===

func to_dict() -> Dictionary:
	return {
		"full_name": full_name,
		"first_name": first_name,
		"middle_initial": middle_initial,
		"last_name": last_name,
		"gender_vector": { "x": gender_vector.x, "y": gender_vector.y, "z": gender_vector.z },
		"username": username,
		"occupation": occupation,
		"relationship_status": relationship_status,
		"affinity": affinity,
		"rizz": rizz,
		"attractiveness": attractiveness,
		"income": income,
		"wealth": wealth,
		"preferred_pet_names": preferred_pet_names.duplicate(),
		"player_pet_names": player_pet_names.duplicate(),
		"alpha": alpha,
		"beta": beta,
		"gamma": gamma,
		"delta": delta,
		"omega": omega,
		"sigma": sigma,
		"tags": tags.duplicate(),
		"likes": likes.duplicate(),
		"fumble_bio": fumble_bio,
		"self_esteem": self_esteem,
		"apprehension": apprehension,
		"chemistry": chemistry,
		"chat_battle_type": chat_battle_type,
		"ocean": ocean,
		"openness": openness,
		"conscientiousness": conscientiousness,
		"extraversion": extraversion,
		"agreeableness": agreeableness,
		"neuroticism": neuroticism,
		"mbti": mbti,
		"zodiac": zodiac,
		"wall_posts": wall_posts.duplicate(),
	}

static func from_dict(data: Dictionary) -> NPC:
	var npc = NPC.new()
	npc.full_name      = _safe_string(data.get("full_name"))
	npc.first_name        = _safe_string(data.get("first_name"))
	npc.middle_initial    = _safe_string(data.get("middle_initial"))
	npc.last_name         = _safe_string(data.get("last_name"))

	var gv = data.get("gender_vector", {"x":0,"y":0,"z":1})
	if typeof(gv) == TYPE_DICTIONARY and gv.has("x") and gv.has("y") and gv.has("z"):
		npc.gender_vector = Vector3(float(gv.x), float(gv.y), float(gv.z))
	else:
		npc.gender_vector = Vector3(0,0,1)

	npc.username          = _safe_string(data.get("username"))
	npc.occupation        = _safe_string(data.get("occupation"), "Funemployed")
	npc.relationship_status = _safe_string(data.get("relationship_status"), "Single")
	npc.affinity          = _safe_float(data.get("affinity"), 0.0)
	npc.rizz              = _safe_int(data.get("rizz"), 0)
	npc.attractiveness    = _safe_int(data.get("attractiveness"), 0)
	npc.income            = _safe_int(data.get("income"), 0)
	npc.wealth            = _safe_int(data.get("wealth"), 0)

	_assign_string_array(npc.preferred_pet_names, data.get("preferred_pet_names"))
	_assign_string_array(npc.player_pet_names, data.get("player_pet_names"))
	npc.alpha             = _safe_float(data.get("alpha"))
	npc.beta              = _safe_float(data.get("beta"))
	npc.gamma             = _safe_float(data.get("gamma"))
	npc.delta             = _safe_float(data.get("delta"))
	npc.omega             = _safe_float(data.get("omega"))
	npc.sigma             = _safe_float(data.get("sigma"))
	_assign_string_array(npc.tags, data.get("tags"), ["alive"])
	_assign_string_array(npc.likes, data.get("likes"))
	npc.fumble_bio        = _safe_string(data.get("fumble_bio"))
	npc.self_esteem       = _safe_int(data.get("self_esteem"), 70)
	npc.apprehension      = _safe_int(data.get("apprehension"), 50)
	npc.chemistry         = _safe_int(data.get("chemistry"), 0)
	npc.chat_battle_type  = _safe_string(data.get("chat_battle_type"))
	npc.ocean             = _safe_dict(data.get("ocean"))
	npc.openness          = _safe_float(data.get("openness"))
	npc.conscientiousness = _safe_float(data.get("conscientiousness"))
	npc.extraversion      = _safe_float(data.get("extraversion"))
	npc.agreeableness     = _safe_float(data.get("agreeableness"))
	npc.neuroticism       = _safe_float(data.get("neuroticism"))
	npc.mbti              = _safe_string(data.get("mbti"))
	npc.zodiac            = _safe_string(data.get("zodiac"))
	_assign_string_array(npc.wall_posts, data.get("wall_posts"), ["hello world"])
	return npc

# === Misc Methods ===
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
