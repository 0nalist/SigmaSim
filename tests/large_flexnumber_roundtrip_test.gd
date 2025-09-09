extends SceneTree

func _ready() -> void:
        var save_mgr = Engine.get_singleton("SaveManager")
        var stat_mgr = Engine.get_singleton("StatManager")

        save_mgr.reset_managers()
        save_mgr.current_slot_id = 1

        var big := FlexNumber.new()
        big._is_big = true
        big._mantissa = 9.99
        big._exponent = 400
        big._normalize()
        stat_mgr.set_base_stat("cash", big)
        stat_mgr.set_base_stat("ex", big)

        save_mgr.save_to_slot(save_mgr.current_slot_id)

        var path = save_mgr.get_slot_path(save_mgr.current_slot_id)
        var text := FileAccess.get_file_as_string(path)
        var parsed = JSON.parse_string(text)
        assert(typeof(parsed) == TYPE_DICTIONARY)
        assert(typeof(parsed["stats"]["cash"]) == TYPE_DICTIONARY)
        assert(parsed["stats"]["cash"]["exponent"] == 400)

        stat_mgr.set_base_stat("cash", FlexNumber.new(0.0))
        stat_mgr.set_base_stat("ex", FlexNumber.new(0.0))

        save_mgr.load_from_slot(save_mgr.current_slot_id)

        var loaded_cash: FlexNumber = stat_mgr.get_cash()
        assert(loaded_cash._is_big)
        assert(loaded_cash._exponent == 400)
        assert(abs(loaded_cash._mantissa - 9.99) < 0.001)

        print("large_flexnumber_roundtrip_test passed")
        quit()

