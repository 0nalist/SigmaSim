extends Node

func _init() -> void:
    _ready()

class DummyStatManager:
    var stats: Dictionary = {}
    func get_stat(name: String) -> float:
        return stats.get(name, 0.0)
    func set_base_stat(name: String, value: float) -> void:
        stats[name] = value
    func connect_to_stat(name: String, target: Object, method: String) -> void:
        pass

class DummyEvents:
    func focus_wallet_card(category: String) -> void:
        pass
    func flash_wallet_value(category: String, amount: float) -> void:
        pass

class DummyWindowManager:
    var launched_apps: Array = []
    func launch_app_by_name(app_name: String) -> void:
        launched_apps.append(app_name)

func _ready() -> void:
    var stat_manager: DummyStatManager = DummyStatManager.new()
    Engine.register_singleton("StatManager", stat_manager)
    var events: DummyEvents = DummyEvents.new()
    Engine.register_singleton("Events", events)
    var window_manager: DummyWindowManager = DummyWindowManager.new()
    Engine.register_singleton("WindowManager", window_manager)

    var pm_script: Script = load("res://autoloads/portfolio_manager.gd")
    var pm: Node = pm_script.new()
    pm.set_credit_limit(100.0)
    pm.set_credit_used(0.0)
    pm.set_credit_interest_rate(0.0)

    pm.add_cash(100.0)
    assert(stat_manager.get_stat("cash") == 100.0)
    pm.add_cash(-50.0)
    assert(stat_manager.get_stat("cash") == 100.0)

    pm.spend_cash(30.0)
    assert(stat_manager.get_stat("cash") == 70.0)
    pm.spend_cash(-5.0)
    assert(stat_manager.get_stat("cash") == 70.0)

    var success: bool = pm.attempt_spend(50.0, 0, true)
    assert(success)
    assert(stat_manager.get_stat("cash") == 20.0)
    assert(stat_manager.get_stat("credit_used") == 0.0)

    success = pm.attempt_spend(30.0, 0, true)
    assert(success)
    assert(stat_manager.get_stat("cash") == 0.0)
    assert(stat_manager.get_stat("credit_used") == 10.0)

    success = pm.attempt_spend(200.0, 0, true)
    assert(not success)
    assert(stat_manager.get_stat("credit_used") == 10.0)
    assert(window_manager.launched_apps.size() == 1)

    print("portfolio_manager_test passed")
