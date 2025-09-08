extends SceneTree
const WindowFrameClass = preload("res://components/ui/window_frame.gd")
const PaneClass = preload("res://components/windows/pane.gd")

func _ready() -> void:
        var frame := WindowFrameClass.new()
        var pane := PaneClass.new()
        frame.load_pane(pane)
        TraumaManager.hit_window_frame(pane, 0.5)
        var id := frame.get_instance_id()
        assert(TraumaManager._pane_states.has(id))
        var state = TraumaManager._pane_states[id]
        assert(state.rotation_deg == 0.0)
        assert(state.rotation_mult == 0.0)
        print("trauma_window_frame_test passed")
        quit()
