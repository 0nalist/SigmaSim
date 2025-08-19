extends SceneTree

func _ready():
    var popup_scene = load("res://components/popups/suitor_popup.tscn")
    var popup = popup_scene.instantiate()
    get_root().add_child(popup)
    await get_tree().process_frame
    var npc = NPC.new()
    npc.full_name = "Test NPC"
    npc.first_name = "Test"
    npc.relationship_stage = NPC.RelationshipStage.EX
    popup.setup(npc)
    PlayerManager.set_var("ex", 100.0)
    popup.apologize_button.visible = true
    popup._update_action_buttons_text()
    assert(popup.apologize_button.text == "Apologize (10 EX)")
    popup._on_apologize_pressed()
    assert(int(PlayerManager.get_var("ex", 0.0)) == 90)
    popup.apologize_button.visible = true
    popup._update_action_buttons_text()
    assert(popup.apologize_button.text == "Apologize (15 EX)")
    popup._on_apologize_pressed()
    assert(int(PlayerManager.get_var("ex", 0.0)) == 75)
    popup.apologize_button.visible = true
    popup._update_action_buttons_text()
    assert(popup.apologize_button.text == "Apologize (23 EX)")
    print("apologize_cost_test passed")
    quit()
