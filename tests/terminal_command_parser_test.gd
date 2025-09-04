extends SceneTree

class_name StatManager
extends RefCounted
static var stats = {"foo": 0}
static func get_stat(name):
    return stats.get(name, null)
static func set_base_stat(name, value):
    stats[name] = value
static func get_all_stats():
    return stats

func _ready() -> void:
    var terminal := Terminal.new()
    terminal.command_list_parent_container = VBoxContainer.new()
    terminal.command_list_container = VBoxContainer.new()
    terminal.command_log_container = VBoxContainer.new()
    terminal.feedback_label = Label.new()

    assert(terminal.process_command("clear_log"))
    assert(terminal.process_command("clearlog"))
    assert(terminal.process_command("set_stat foo 1"))
    assert(terminal.process_command("setstat foo 2"))
    assert(StatManager.get_stat("foo") == 2)

    print("terminal_command_parser_test passed")
    quit()

