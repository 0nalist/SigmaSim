extends SceneTree

func _ready():
        var bm = Engine.get_singleton("BillManager")
        bm.reset()
        assert(not bm.lifestyle_categories.is_empty())
        print("bill_manager_reset_test passed")
        quit()
