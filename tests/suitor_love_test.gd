extends SceneTree

func _ready() -> void:
	var npc: NPC = NPC.new()
	npc.affinity = 0.0
	var logic: SuitorLogic = SuitorLogic.new()
	logic.setup(npc)
	logic.apply_love()
	assert(npc.affinity == 5.0)
	print("suitor_love_test passed")
	quit()
