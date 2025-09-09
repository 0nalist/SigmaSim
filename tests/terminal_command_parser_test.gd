extends SceneTree


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
	var starting_cash = PortfolioManager.cash
	assert(terminal.process_command("add_cash 1.5"))
	assert(is_equal_approx(PortfolioManager.cash, starting_cash + 1.5))
	assert(terminal.process_command("set_stat cash 2.25"))
	assert(is_equal_approx(PortfolioManager.cash, 2.25))
	PortfolioManager.cash = starting_cash

	var starting_ex := StatManager.get_ex().to_float()
	assert(terminal.process_command("set_stat ex 3.5"))
	assert(is_equal_approx(StatManager.get_ex().to_float(), 3.5))
	StatManager.set_base_stat("ex", starting_ex)

	assert(terminal.process_command("set_stat foo 1.5"))
	assert(is_equal_approx(StatManager.get_stat("foo"), 1.5))
	assert(terminal.process_command("setstat foo 2.5"))
	assert(is_equal_approx(StatManager.get_stat("foo"), 2.5))

	print("terminal_command_parser_test passed")
	quit()
