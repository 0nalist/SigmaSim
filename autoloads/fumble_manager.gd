extends Node
#Autoload: FumbleManager

var active_battles: Array = [] # {npc_idx, battle_id}

func _ready():
	active_battles = DBManager.get_active_fumble_battles()


func get_matches() -> Array:
	return NPCManager.get_fumble_matches()

func has_active_battle(npc_idx: int) -> bool:
	return active_battles.any(func(b): b.npc_idx == npc_idx)

func start_battle(npc_idx: int) -> String:
	if not has_active_battle(npc_idx):
		var battle_id = "%s_%d" % [str(Time.get_unix_time_from_system()), randi() % 1000000]
		var entry = { "npc_idx": npc_idx, "battle_id": battle_id, "chatlog": [], "stats": {}, "outcome": "active" }
		active_battles.append(entry)
		DBManager.save_fumble_battle(battle_id, npc_idx, [], {}, "active")
		NPCManager.promote_to_persistent(npc_idx)
		return battle_id
	return active_battles.filter(func(b): b.npc_idx == npc_idx)[0].battle_id

func get_active_battles():
	return active_battles

func save_battle_state(battle_id: String, chatlog: Array, stats: Dictionary, outcome: String) -> void:
	var npc_idx := -1
	for b in active_battles:
			if b.battle_id == battle_id:
					npc_idx = b.npc_idx
					b.chatlog = chatlog.duplicate()
					b.stats = stats.duplicate()
					b.outcome = outcome
					break
	if npc_idx != -1:
			DBManager.save_fumble_battle(battle_id, npc_idx, chatlog, stats, outcome)

func load_battle_state(battle_id: String) -> Dictionary:
        # Prefer in-memory data first
        for b in active_battles:
                if b.battle_id == battle_id:
                        return {
                                "npc_idx": b.npc_idx,
                                "chatlog": b.chatlog.duplicate(),
                                "stats": b.stats.duplicate(),
                                "outcome": b.outcome
                        }

        var data = DBManager.load_fumble_battle(battle_id)
        if data.size() == 0:
                return {}
        var parsed_chatlog = DBManager.from_json(data.chatlog)
        if parsed_chatlog == null:
                parsed_chatlog = []
        var parsed_stats = DBManager.from_json(data.stats)
        if parsed_stats == null:
                parsed_stats = {}
        return {
                "npc_idx": int(data.npc_id),
                "chatlog": parsed_chatlog,
                "stats": parsed_stats,
                "outcome": data.outcome
        }
