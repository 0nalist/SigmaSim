extends Node
#Autoload: FumbleManager
# "res://autoloads/fumble_manager.gd"

var active_battles: Array = [] # {npc_idx, battle_id}


enum FumbleStatus {
	LIKED,
	MATCHED,
	ACTIVE_CHAT,
	BLOCKED_PLAYER,
	VICTORY,
}

const FUMBLE_STATUS_STRINGS := {
	FumbleStatus.LIKED: "liked",
	FumbleStatus.MATCHED: "matched",
	FumbleStatus.ACTIVE_CHAT: "active_chat",
	FumbleStatus.BLOCKED_PLAYER: "blocked_player",
	FumbleStatus.VICTORY: "victory",
}
const FUMBLE_STATUS_LOOKUP := {
	"liked": FumbleStatus.LIKED,
	"matched": FumbleStatus.MATCHED,
	"active_chat": FumbleStatus.ACTIVE_CHAT,
	"blocked_player": FumbleStatus.BLOCKED_PLAYER,
	"victory": FumbleStatus.VICTORY,
}







func _ready():
	#active_battles = DBManager.get_active_fumble_battles(SaveManager.current_slot_id)
	pass

func get_matches() -> Array:
	return NPCManager.get_fumble_matches()

func get_active_battles() -> Array:
	return DBManager.get_active_fumble_battles(SaveManager.current_slot_id)

func has_active_battle(npc_idx: int) -> bool:
	for b in get_active_battles():
		if b.npc_idx == npc_idx:
			return true
	return false

func start_battle(npc_idx: int) -> String:
	if not has_active_battle(npc_idx):
		var battle_id = "%s_%d" % [str(Time.get_unix_time_from_system()), randi() % 1000000]
		DBManager.save_fumble_battle(
			battle_id,
			npc_idx,
			[],
			{},
			"active"
		)
		NPCManager.promote_to_persistent(npc_idx)
		DBManager.save_fumble_relationship(npc_idx, "active_chat") # This MUST be set
		return battle_id
	# If already in a battle, forcibly set status to active_chat as well:
	for b in get_active_battles():
		if b.npc_idx == npc_idx:
			DBManager.save_fumble_relationship(npc_idx, "active_chat")
			return b.battle_id
	return ""




func save_battle_state(battle_id: String, chatlog: Array, stats: Dictionary, outcome: String) -> void:
	var data = DBManager.load_fumble_battle(battle_id, SaveManager.current_slot_id)
	var npc_idx = int(data.npc_id) if data.size() > 0 else -1
	if npc_idx != -1:
		DBManager.save_fumble_battle(
			battle_id,
			npc_idx,
			chatlog,
			stats,
			outcome
		)



func load_battle_state(battle_id: String) -> Dictionary:
	var data = DBManager.load_fumble_battle(battle_id, SaveManager.current_slot_id)
	if data.size() == 0:
		return {}
	return {
		"npc_idx": int(data.npc_id),
		"chatlog": DBManager.from_json(data.chatlog),
		"stats": DBManager.from_json(data.stats),
		"outcome": data.outcome
	}
