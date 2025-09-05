extends SceneTree

# Tests saving/loading of love cooldown with and without TimeManager
func _ready() -> void:
        const MAX_CD := 24 * 60
        var tm = Engine.get_singleton("TimeManager")
        var now = TimeManager.get_now_minutes()


        # Saving and loading while the TimeManager is present keeps the exact
        # remaining minutes.

        var npc := NPC.new()
        npc.love_cooldown = now + MAX_CD + 100
        var saved := npc.to_dict()
        assert(saved["love_cooldown"] == MAX_CD)
        var loaded := NPC.from_dict(saved)

        assert(loaded._get_love_cooldown() == MAX_CD)

        # If the TimeManager is missing when loading, the cooldown is stored as a
        # negative sentinel and later expanded once the TimeManager returns.

        Engine.unregister_singleton("TimeManager")
        var npc2 := NPC.new()
        npc2.love_cooldown = MAX_CD + 100
        var saved2 := npc2.to_dict()
        assert(saved2["love_cooldown"] == MAX_CD)
        var loaded2 := NPC.from_dict(saved2)

        assert(loaded2.love_cooldown == -MAX_CD)
        Engine.register_singleton("TimeManager", tm)
        assert(loaded2._get_love_cooldown() == MAX_CD)
        assert(loaded2.love_cooldown > MAX_CD)


        print("npc_love_cooldown_persistence_test passed")
        quit()
