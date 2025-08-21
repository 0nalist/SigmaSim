extends SceneTree

func _ready():
    var npc := NPC.new()
    npc.affinity = 0.0
    var logic := SuitorLogic.new()
    logic.setup(npc)
    logic.apply_love()
    assert(npc.affinity == 5.0)
    print("suitor_love_test passed")
    quit()
