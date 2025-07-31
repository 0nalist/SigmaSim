extends Node
# Autoload: FumbleManager

var active_battles: Array = [] # {npc_idx, battle_id, chatlog, stats, outcome}

func _ready():
        active_battles.clear()


func get_matches() -> Array:
	return NPCManager.get_fumble_matches()

func has_active_battle(npc_idx: int) -> bool:
	return active_battles.any(func(b): b.npc_idx == npc_idx)

func start_battle(npc_idx: int) -> String:
        if not has_active_battle(npc_idx):
                var battle_id = "%s_%d" % [str(Time.get_unix_time_from_system()), randi() % 1000000]
                var entry = { "npc_idx": npc_idx, "battle_id": battle_id, "chatlog": [], "stats": {}, "outcome": "active" }
                active_battles.append(entry)
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
        # Persisted via SaveManager when the profile is saved

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
        return {}


func get_save_data() -> Dictionary:
        var battles := []
        for b in active_battles:
                battles.append({
                        "npc_idx": b.npc_idx,
                        "battle_id": b.battle_id,
                        "chatlog": b.chatlog.duplicate(),
                        "stats": b.stats.duplicate(),
                        "outcome": b.outcome,
                })
        return { "active_battles": battles }


func load_from_data(data: Dictionary) -> void:
        reset()
        var battles = data.get("active_battles", [])
        if typeof(battles) != TYPE_ARRAY:
                return
        for entry in battles:
                var e = {
                        "npc_idx": int(entry.get("npc_idx", -1)),
                        "battle_id": str(entry.get("battle_id", "")),
                        "chatlog": entry.get("chatlog", []),
                        "stats": entry.get("stats", {}),
                        "outcome": entry.get("outcome", "active")
                }
                active_battles.append(e)


func reset() -> void:
        active_battles.clear()
