extends Node
# Autoload: FumbleManager

class BattleEntry:
	var npc_idx: int
	var battle_id: String
	var chatlog: Array = []
	var stats: Dictionary = {}
	var outcome: String = "active"

	func _init(_npc_idx: int = -1, _battle_id: String = "", _chatlog := [], _stats := {}, _outcome := "active"):
		npc_idx = _npc_idx
		battle_id = _battle_id
		chatlog = _chatlog.duplicate()
		stats = _stats.duplicate()
		outcome = _outcome

	func to_dict() -> Dictionary:
		return {
			"npc_idx": npc_idx,
			"battle_id": battle_id,
			"chatlog": chatlog.duplicate(),
			"stats": stats.duplicate(),
			"outcome": outcome
		}

var active_battles: Array[BattleEntry] = []

func _ready():
	for data in DBManager.get_active_fumble_battles():
		var idx = -1
		if data.has("npc_idx"):
			idx = int(data["npc_idx"])
		elif data.has("npc_id"):
			idx = int(data["npc_id"])
		else:
			push_error("Missing 'npc_idx' or 'npc_id' in DBManager.get_active_fumble_battles result.")
			continue

		var battle_id = ""
		if data.has("battle_id"):
			battle_id = str(data["battle_id"])

		var chatlog = []
		if data.has("chatlog"):
			chatlog = data["chatlog"]
			if typeof(chatlog) == TYPE_STRING:
				chatlog = DBManager.from_json(chatlog)
			if chatlog == null:
				chatlog = []

		var stats = {}
		if data.has("stats"):
			stats = data["stats"]
			if typeof(stats) == TYPE_STRING:
				stats = DBManager.from_json(stats)
			if stats == null:
				stats = {}

		var outcome = "active"
		if data.has("outcome"):
			outcome = str(data["outcome"])

		var b = BattleEntry.new(idx, battle_id, chatlog, stats, outcome)
		active_battles.append(b)

func get_matches() -> Array:
	return NPCManager.get_fumble_matches()

func has_active_battle(npc_idx: int) -> bool:
	for b in active_battles:
		if b.npc_idx == npc_idx:
			return true
	return false

func start_battle(npc_idx: int) -> String:
	if not has_active_battle(npc_idx):
		var battle_id = "%s_%d" % [str(Time.get_unix_time_from_system()), randi() % 1000000]
		var entry = BattleEntry.new(npc_idx, battle_id)
		active_battles.append(entry)
		DBManager.save_fumble_battle(battle_id, npc_idx, [], {}, "active")
		NPCManager.promote_to_persistent(npc_idx)
		return battle_id
	for b in active_battles:
		if b.npc_idx == npc_idx:
			return b.battle_id
	return ""

func get_active_battles() -> Array[BattleEntry]:
	return active_battles

func save_battle_state(battle_id: String, chatlog: Array, stats: Dictionary, outcome: String) -> void:
	for b in active_battles:
		if b.battle_id == battle_id:
			b.chatlog = chatlog.duplicate()
			b.stats = stats.duplicate()
			b.outcome = outcome
			DBManager.save_fumble_battle(battle_id, b.npc_idx, chatlog, stats, outcome)
			break

func load_battle_state(battle_id: String) -> Dictionary:
	for b in active_battles:
		if b.battle_id == battle_id:
			return b.to_dict()

	var data = DBManager.load_fumble_battle(battle_id)
	if data.size() == 0:
		return {}

	var idx = -1
	if data.has("npc_idx"):
		idx = int(data["npc_idx"])
	elif data.has("npc_id"):
		idx = int(data["npc_id"])

	var parsed_chatlog = []
	if data.has("chatlog"):
		parsed_chatlog = data["chatlog"]
		if typeof(parsed_chatlog) == TYPE_STRING:
			parsed_chatlog = DBManager.from_json(parsed_chatlog)
		if parsed_chatlog == null:
			parsed_chatlog = []

	var parsed_stats = {}
	if data.has("stats"):
		parsed_stats = data["stats"]
		if typeof(parsed_stats) == TYPE_STRING:
			parsed_stats = DBManager.from_json(parsed_stats)
		if parsed_stats == null:
			parsed_stats = {}

	var battle_id_out = ""
	if data.has("battle_id"):
		battle_id_out = str(data["battle_id"])

	var outcome = "active"
	if data.has("outcome"):
		outcome = str(data["outcome"])

	return {
		"npc_idx": idx,
		"battle_id": battle_id_out,
		"chatlog": parsed_chatlog,
		"stats": parsed_stats,
		"outcome": outcome
	}
