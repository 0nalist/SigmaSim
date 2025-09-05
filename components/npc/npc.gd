@icon("res://assets/prof_pics/silhouette.png")
class_name NPC
extends Resource

signal player_broke_up

const BASE_GIFT_COST: float = 1.0
const BASE_DATE_COST: float = 10.0
# Maximum love cooldown duration (24 hours in minutes)
const MAX_LOVE_COOLDOWN: int = 24 * 60



# === Basic Info ===
@export var full_name: String
@export var first_name: String
@export var middle_initial: String
@export var last_name: String
@export var gender_vector: Vector3 = Vector3(0, 0, 1) # x: femme, y: masc, z: enby

@export var username: String
@export var profile_pic: Texture2D
@export var portrait_config: PortraitConfig
@export var occupation: String = "Funemployed"
@export var relationship_status: String = "Single"

@export var locked_in_connection: bool = false

@export var relationship_stage: int = NPCManager.RelationshipStage.STRANGER
@export_range(0, 1000000000, 1) var relationship_progress: float = 0.0

@export var exclusivity_core: int = NPCManager.ExclusivityCore.POLY

@export var claimed_exclusive_boost: bool = false
@export var claimed_serious_monog_boost: bool = false

# Relationship with Player

@export_range(-100, 100, 0.1) var affinity: float = 0.0 # 0–100

@export_range(0, 100, 0.1) var affinity_equilibrium: float = 100.0

@export_range(0, 100, 0.1) var rizz: int
@export_range(0, 100, 1) var attractiveness: int
@export var date_count: int = 0
@export var gift_count: int = 0
@export var love_cooldown: int = 0
var gift_cost: float = 0.0
var date_cost: float = 0.00
@export var proposal_cost: float = 25000.0

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
@export var dislikes: Array[String] = []

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
@export var zodiac_sun: String
@export var zodiac_moon: String
@export var zodiac_rising: String

# === Wall Posts / Social Feed ===
@export var wall_posts: Array[String] = ["hello world"]

# === HELPERS ===
static func _safe_string(val, fallback := ""):
	return val if typeof(val) == TYPE_STRING and val != null else fallback

static func _safe_int(val, fallback := 0):
	if val == null:
		return fallback
	match typeof(val):
		TYPE_INT, TYPE_FLOAT:
			return int(val)
		TYPE_STRING:
			return int(val) if String(val).is_valid_int() else fallback
		_:
			return fallback

static func _safe_float(val, fallback := 0.0):
	if val == null:
		return fallback
	match typeof(val):
		TYPE_FLOAT, TYPE_INT:
			return float(val)
		TYPE_STRING:
			return float(val) if String(val).is_valid_float() else fallback
		_:
			return fallback

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
		"locked_in_connection": locked_in_connection,
		"relationship_stage": relationship_stage,
		"relationship_progress": relationship_progress,
		"exclusivity_core": exclusivity_core,
		"claimed_exclusive_boost": claimed_exclusive_boost,
		"claimed_serious_monog_boost": claimed_serious_monog_boost,
		"affinity": affinity,
		"affinity_equilibrium": affinity_equilibrium,
		"rizz": rizz,
		"attractiveness": attractiveness,
		"date_count": date_count,
		"gift_count": gift_count,
		# Store remaining cooldown time rather than absolute game minutes
		# to avoid inflated values when reloading before the TimeManager
		# has restored the canonical clock. This value is re-expanded to
		# an absolute timestamp in `from_dict`.
		"love_cooldown": _get_love_cooldown(),
		"proposal_cost": proposal_cost,

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
				"dislikes": dislikes.duplicate(),
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
				"zodiac_sun": zodiac_sun,
				"zodiac_moon": zodiac_moon,
				"zodiac_rising": zodiac_rising,
				"wall_posts": wall_posts.duplicate(),
				"portrait_config": portrait_config.to_dict() if portrait_config != null else null,
}

static func from_dict(data: Dictionary) -> NPC:
	var npc = NPC.new()
	npc.full_name= _safe_string(data.get("full_name"))
	npc.first_name  = _safe_string(data.get("first_name"))
	npc.middle_initial = _safe_string(data.get("middle_initial"))
	npc.last_name= _safe_string(data.get("last_name"))

	var gv = data.get("gender_vector", {"x":0,"y":0,"z":1})
	if typeof(gv) == TYPE_DICTIONARY and gv.has("x") and gv.has("y") and gv.has("z"):
		npc.gender_vector = Vector3(float(gv.x), float(gv.y), float(gv.z))
	else:
		npc.gender_vector = Vector3(0,0,1)

	npc.username = _safe_string(data.get("username"))
	npc.occupation  = _safe_string(data.get("occupation"), "Funemployed")
	npc.relationship_status = _safe_string(data.get("relationship_status"), "Single")
	npc.locked_in_connection = _safe_int(data.get("locked_in_connection"), 0) != 0
	npc.relationship_stage = _safe_int(data.get("relationship_stage"), NPCManager.RelationshipStage.STRANGER)
	npc.relationship_progress = _safe_float(data.get("relationship_progress"))
	npc.exclusivity_core = _safe_int(data.get("exclusivity_core"), NPCManager.ExclusivityCore.POLY)
	if not data.has("exclusivity_core"):
		var legacy_ex: Variant = data.get("exclusivity")
		if legacy_ex != null:
			var legacy_val: String = _safe_string(legacy_ex)
			match legacy_val:
				"EXCLUSIVE", "MONOGAMOUS":
					npc.exclusivity_core = NPCManager.ExclusivityCore.MONOG
				"POLY", "OPEN":
					npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
				"CHEATING":
					npc.exclusivity_core = NPCManager.ExclusivityCore.CHEATING
				"UNMENTIONED", "DATING_AROUND":
					npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
				_:
					if npc.relationship_stage >= NPCManager.RelationshipStage.SERIOUS:
						npc.exclusivity_core = NPCManager.ExclusivityCore.MONOG
					else:
						npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
		else:
			if npc.relationship_stage >= NPCManager.RelationshipStage.SERIOUS:
				npc.exclusivity_core = NPCManager.ExclusivityCore.MONOG
			else:
				npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
	npc.claimed_exclusive_boost = _safe_int(data.get("claimed_exclusive_boost"), 0) != 0
	npc.claimed_serious_monog_boost = _safe_int(data.get("claimed_serious_monog_boost"), 0) != 0
	npc.affinity = _safe_float(data.get("affinity"), 0.0)
	npc.affinity_equilibrium = _safe_float(data.get("affinity_equilibrium"), 100.0)
	npc.rizz = _safe_int(data.get("rizz"), 0)
	npc.attractiveness = _safe_int(data.get("attractiveness"), 0)

	var saved_gift_cost: float = _safe_float(data.get("gift_cost"), BASE_GIFT_COST)
	var saved_date_cost: float = _safe_float(data.get("date_cost"), BASE_DATE_COST)
	npc.date_count = _safe_int(data.get("date_count"), -1)
	if npc.date_count < 0:
			npc.date_count = _safe_int(data.get("dates_paid"), -1)
	npc.gift_count = _safe_int(data.get("gift_count"), -1)
	if npc.date_count < 0:
			npc.date_count = int(log(max(saved_date_cost, BASE_DATE_COST) / BASE_DATE_COST) / log(2.0))
	if npc.gift_count < 0:
			npc.gift_count = int(log(max(saved_gift_cost, BASE_GIFT_COST) / BASE_GIFT_COST) / log(2.0))
	npc.gift_cost = (float(npc.attractiveness) / 10.0) * BASE_GIFT_COST * pow(2.0, npc.gift_count)
	npc.date_cost = (float(npc.attractiveness) / 10.0) * BASE_DATE_COST * pow(2.0, npc.date_count) ##TODO: Make this easier to tweak

	# Older saves stored the absolute game-minute when the cooldown ended.
	# Newer saves store only the remaining minutes. Detect which format was
	# used and reconstruct the proper absolute timestamp.
        var _saved_cd: int = _safe_int(data.get("love_cooldown"), 0)
        if Engine.has_singleton("TimeManager"):
                var _now: int = TimeManager.get_now_minutes()
                if _saved_cd > MAX_LOVE_COOLDOWN:
                        npc.love_cooldown = _saved_cd
                else:
                        npc.love_cooldown = _now + _saved_cd
                # Prevent values more than 24h into the future
                npc.love_cooldown = min(npc.love_cooldown, _now + MAX_LOVE_COOLDOWN)
        else:
                # Without a TimeManager, treat the stored value as relative minutes
                npc.love_cooldown = clamp(_saved_cd, 0, MAX_LOVE_COOLDOWN)

	npc.proposal_cost = _safe_float(data.get("proposal_cost"), 25000.0)
	npc.income= _safe_int(data.get("income"), 0)
	npc.wealth= _safe_int(data.get("wealth"), 0)

	_assign_string_array(npc.preferred_pet_names, data.get("preferred_pet_names"))
	_assign_string_array(npc.player_pet_names, data.get("player_pet_names"))
	npc.alpha = _safe_float(data.get("alpha"))
	npc.beta  = _safe_float(data.get("beta"))
	npc.gamma = _safe_float(data.get("gamma"))
	npc.delta = _safe_float(data.get("delta"))
	npc.omega = _safe_float(data.get("omega"))
	npc.sigma = _safe_float(data.get("sigma"))
	_assign_string_array(npc.tags, data.get("tags"), ["alive"])
	_assign_string_array(npc.likes, data.get("likes"))
	_assign_string_array(npc.dislikes, data.get("dislikes"))
	npc.fumble_bio  = _safe_string(data.get("fumble_bio"))
	npc.self_esteem = _safe_int(data.get("self_esteem"), 70)
	npc.apprehension= _safe_int(data.get("apprehension"), 50)
	npc.chemistry= _safe_int(data.get("chemistry"), 0)
	npc.chat_battle_type  = _safe_string(data.get("chat_battle_type"))
	npc.ocean = _safe_dict(data.get("ocean"))
	npc.openness = _safe_float(data.get("openness"))
	npc.conscientiousness = _safe_float(data.get("conscientiousness"))
	npc.extraversion= _safe_float(data.get("extraversion"))
	npc.agreeableness  = _safe_float(data.get("agreeableness"))
	npc.neuroticism = _safe_float(data.get("neuroticism"))
	npc.mbti  = _safe_string(data.get("mbti"))
	npc.zodiac_sun = _safe_string(data.get("zodiac_sun"))
	npc.zodiac_moon = _safe_string(data.get("zodiac_moon"))
	npc.zodiac_rising = _safe_string(data.get("zodiac_rising"))
	var pc_src = data.get("portrait_config")
	if typeof(pc_src) == TYPE_DICTIONARY and pc_src.size() > 0:
		npc.portrait_config = PortraitConfig.from_dict(pc_src)
	else:
		npc.portrait_config = null
	_assign_string_array(npc.wall_posts, data.get("wall_posts"), ["hello world"])
	return npc

# === Misc Methods ===
func get_full_name() -> String:
	return "%s %s. %s" % [first_name, middle_initial, last_name]

func _get_love_cooldown() -> float:
        if Engine.has_singleton("TimeManager"):
                var now_minutes: float = TimeManager.get_now_minutes()
                return clamp(love_cooldown - now_minutes, 0, MAX_LOVE_COOLDOWN)
        # If the TimeManager is unavailable, treat love_cooldown as already
        # relative and clamp it directly.
        return clamp(love_cooldown, 0, MAX_LOVE_COOLDOWN)



func describe_gender() -> String:
	var components = []
	if gender_vector.x > 0.5:
		components.append("feminine")
	if gender_vector.y > 0.5:
		components.append("masculine")
	if gender_vector.z > 0.5:
		components.append("enby")
	return ", ".join(components) if components.size() > 0 else "ambiguous"

func get_marriage_level() -> int:
	var n: int = int(floor(relationship_progress))
	if n < 100000:
		return 0
	var digits: int = 0
	var tmp: int = n
	while tmp > 0:
		tmp = tmp / 10
		digits += 1
	return digits - 5

func is_in_dating() -> bool:
	return relationship_stage == NPCManager.RelationshipStage.DATING

func is_serious_or_higher() -> bool:
	return relationship_stage >= NPCManager.RelationshipStage.SERIOUS
