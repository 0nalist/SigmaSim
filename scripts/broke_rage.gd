#BrokeRage.gd
extends DesktopWindow

func _ready() -> void:
	MoneyManager.update_cash.connect(_on_cash_updated)
	MoneyManager.update_cash.emit(MoneyManager.cash)
	MoneyManager.update_passive_income.connect(_on_passive_income_updated)
	self.close_requested.connect(_on_close_requested)
	
	_on_cash_updated(MoneyManager.cash)
	_on_passive_income_updated(MoneyManager.get_passive_income())

func _on_close_requested():
	hide()

func _on_cash_updated(delta):
	%CashLabel.text = "Cash: $" + str(MoneyManager.cash)
	self.title = "BrokeRage - $" + str(MoneyManager.cash)
	%BalanceLabel.text = "Balance: $" + str(MoneyManager.get_balance())

func _on_passive_income_updated(amount):
	%PassiveIncomeLabel.text = "Passive Income: $" + str(MoneyManager.get_passive_income())
