#MoneyManager
extends Node

var cash: int = 0
var employee_income: int = 0
var investments: int = 0
var interest: float = 0
var rent: int = 0
var debt: int = 0
var passive_income: int = 0

signal update_cash(delta: int)
signal update_passive_income(total)
signal update_investments(total)

func add_cash(amount: int):
	if amount < 0:
		print("Tried to add negative cash")
		return
	cash += amount
	update_cash.emit(amount)

func spend_cash(amount: int):
	if amount < 0:
		print("Tried to spend negative cash")
		return
	cash -= amount
	update_cash.emit(-amount)

func get_passive_income() -> int:
	return rent + employee_income + int(interest/365/24/60/60)

func get_balance() -> int:
	return cash + investments - debt 

func get_investments() -> int:
	return 0
 

func add_employee_income(amount):
	employee_income += amount
	update_passive_income.emit(get_passive_income())
