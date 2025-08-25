extends SceneTree

func _ready() -> void:
	var npc: NPC = NPC.new()
	npc.affinity = 0.0
	var logic: ExFactorLogic = ExFactorLogic.new()
	logic.setup(npc)
	logic.apply_love()
	assert(npc.affinity == 5.0)
	print("ex_factor_love_test passed")
	quit()
