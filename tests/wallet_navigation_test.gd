extends SceneTree

func _ready():
        var stack := WalletStack.new()
        add_child(stack)
        await stack.ready

        for id in ["a", "b", "c"]:
                var card := WalletCardBase.new()
                card.setup(id, id)
                stack.add_card(id, card)
                await get_tree().process_frame
                assert(card.mouse_filter == Control.MOUSE_FILTER_PASS)

        assert(stack.get_active_id() == "a")

        # Simulate mouse hovering over the stack so scroll events are processed
        stack._hovering = true

        var scroll_down := InputEventMouseButton.new()
        scroll_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
        scroll_down.pressed = true
        stack._gui_input(scroll_down)
        assert(stack.get_active_id() == "b")

        var scroll_up := InputEventMouseButton.new()
        scroll_up.button_index = MOUSE_BUTTON_WHEEL_UP
        scroll_up.pressed = true
        stack._gui_input(scroll_up)
        assert(stack.get_active_id() == "a")

        var key_right := InputEventKey.new()
        key_right.keycode = KEY_RIGHT
        key_right.pressed = true
        stack._unhandled_input(key_right)
        assert(stack.get_active_id() == "b")

        var key_left := InputEventKey.new()
        key_left.keycode = KEY_LEFT
        key_left.pressed = true
        stack._unhandled_input(key_left)
        assert(stack.get_active_id() == "a")

        print("wallet_navigation_test passed")
        quit()
