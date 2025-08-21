extends SceneTree

func _ready() -> void:
	var pm: Node = Engine.get_singleton("PortfolioManager")
	pm.add_cash(1000.0)
	var npc: NPC = NPC.new()
	npc.full_name = "Test NPC"
	npc.first_name = "Test"
	var scene: PackedScene = load("res://components/popups/suitor_popup.tscn")
	var sv: SuitorView = scene.instantiate()
	add_child(sv)
	await get_tree().process_frame
	sv.setup_custom({"npc": npc})
	sv._on_gift_pressed()
	sv._on_date_pressed()
	sv.setup_custom({"npc": npc})
	assert(sv.gift_cost == 50.0)
	assert(sv.date_cost == 400.0)
	print("suitor_cost_persistence_test passed")
	quit()
