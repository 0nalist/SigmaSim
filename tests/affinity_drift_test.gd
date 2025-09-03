extends SceneTree

const NPC = preload("res://components/npc/npc.gd")

func _ready() -> void:
	var npc_idx := 999
	var npc := NPC.new()
	npc.affinity = 50.0
	npc.affinity_equilibrium = 60.0
	var npc_manager = Engine.get_singleton("NPCManager")
	npc_manager.npcs[npc_idx] = npc
	npc_manager.persistent_npcs[npc_idx] = {}
	npc_manager.daterbase_npcs = [npc_idx]

	var triggered := false
	npc_manager.affinity_changed.connect(func(idx, _v):
		if idx == npc_idx:
			triggered = true
	)

	npc_manager._on_hour_passed(0, 0)
	assert(abs(npc.affinity - 51.0) < 0.01)
	assert(triggered)
	print("affinity_drift_test passed")
	quit()
