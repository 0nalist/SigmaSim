extends SceneTree

func _ready():
    var scene = preload("res://components/apps/tarot/tarot_card_view.tscn")
    var view = scene.instantiate()
    view.set_upside_down(true)
    add_child(view)
    view.texture_rect.rotation_degrees = 180
    await get_tree().process_frame
    assert(view.texture_rect.rotation_degrees == 180)
    print("tarot_rotation_restore_test passed")
    quit()
