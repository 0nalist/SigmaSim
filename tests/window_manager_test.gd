extends Node

func _init() -> void:
    _ready()

var wm_script: Script = preload("res://autoloads/window_manager.gd")
var pane_script: Script = preload("res://components/windows/pane.gd")

class DummyPane extends pane_script:
    pass

class TestWindowManager extends wm_script:
    func launch_pane(scene: PackedScene) -> void:
        var pane: Node = scene.instantiate()
        add_child(pane)

func _ready() -> void:
    var wm: TestWindowManager = TestWindowManager.new()
    var ps: PackedScene = PackedScene.new()
    var pane_instance: DummyPane = DummyPane.new()
    ps.pack(pane_instance)
    wm.app_registry["TestApp"] = ps
    wm.launch_app_by_name("TestApp")
    assert(wm.get_child_count() == 1)
    assert(wm.get_child(0) is Pane)
    wm.launch_app_by_name("MissingApp")
    assert(wm.get_child_count() == 1)
    print("window_manager_test passed")
