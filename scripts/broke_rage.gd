extends Window

func _ready() -> void:
	MoneyManager.update_cash.connect(_on_cash_updated)
	MoneyManager.update_cash.emit(MoneyManager.cash)
	MoneyManager.update_passive_income.connect(_on_passive_income_updated)
	self.close_requested.connect(_on_close_requested)

func _on_close_requested():
	hide()

func _on_cash_updated(amount):
	%CashLabel.text = "Cash: $" + str(amount)
	%BalanceLabel.text = "Balance: $" + str(MoneyManager.cash + MoneyManager.investments - MoneyManager.debt)

func _on_passive_income_updated(amount):
	%PassiveIncomeLabel.text = "Passive Income: $" + str(MoneyManager.passive_income)
