extends SceneTree

func _ready() -> void:
        var topbar := Control.new()
        topbar.size = Vector2(0, 40)
        WindowManager.topbar_container = topbar

        var window_scene: PackedScene = preload("res://components/ui/window_frame.tscn")
        var window := window_scene.instantiate() as WindowFrame
        root.add_child(window)
        await get_tree().process_frame

        window.position = Vector2.ZERO
        await window._clamp_to_screen()
        var expected_y = topbar.size.y + window.SNAP_MARGIN
        assert(window.position.y == expected_y)
        print("window_frame_ticker_clamp_test passed")
        quit()

