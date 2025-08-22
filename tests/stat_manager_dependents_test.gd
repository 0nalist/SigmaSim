extends SceneTree

func _ready():
    var sm = Engine.get_singleton("StatManager")
    sm._build_dependents_map()
    for dep in sm._dependents.keys():
        var arr = sm._dependents[dep]
        for item in arr:
            assert(arr.count(item) == 1, "%s appears multiple times in dependents for %s" % [item, dep])
    print("stat_manager_dependents_test passed")
    quit()
