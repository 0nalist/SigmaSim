extends WalletCardBase
class_name BragCard

func _ready() -> void:
	setup("brag", "Sigma Wallet", "High Score")
	_build()
	_connect_signals()
	_refresh_all()

func _build() -> void:
	var rows1: Array = []
	rows1.append({"label": "Cash", "value": "$" + NumberFormatter.format_number(PortfolioManager.cash)})
	rows1.append({"label": "Net Worth", "value": "$" + NumberFormatter.format_number(PortfolioManager.get_balance())})
	add_group("totals", rows1)

	var rows2: Array = []
	rows2.append({"label": "e^x Factor", "value": String.num(_get_ex_factor_score(), 2)})
	rows2.append({"label": "Time Played", "value": _fmt_minutes(TimeManager.get_total_minutes_played())})
	add_group("bragging rights", rows2)

	set_footer_note("screenshot ready")

func _connect_signals() -> void:
	PortfolioManager.cash_updated.connect(_on_cash)
	PortfolioManager.investments_updated.connect(_on_investments)
	PortfolioManager.resource_changed.connect(_on_resource_changed)

func _refresh_all() -> void:
	# Rebuild content so numbers are fresh
	_clear_content()
	_build()

func _clear_content() -> void:
	var content: VBoxContainer = get_node("Root/Content") as VBoxContainer
	if content == null:
		return
	for child in content.get_children():
		child.queue_free()

func _on_cash(_v: float) -> void:
	_refresh_all()
	bump_value_color()

func _on_investments(_v: float) -> void:
	_refresh_all()
	bump_value_color()

func _on_resource_changed(name: String, _value: float) -> void:
	if name == "cash" or name == "debt":
		_refresh_all()

func _get_ex_factor_score() -> float:
	
	return PlayerManager.get_var("ex")

func _fmt_minutes(total: int) -> String:
	# D:HH:MM
	var days: int = total / (60 * 24)
	var rem: int = total % (60 * 24)
	var hours: int = rem / 60
	var mins: int = rem % 60
	return str(days) + "d " + _pad2(hours) + ":" + _pad2(mins)

func _pad2(v: int) -> String:
	if v < 10:
		return "0" + str(v)
	return str(v)
