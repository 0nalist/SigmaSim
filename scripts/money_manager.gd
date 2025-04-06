extends Node

var cash: int = 0
var investments: int = 0
var debt: int = 0
var passive_income: int = 0

signal update_cash(amount)
signal update_passive_income(amount)

func add_cash(amount):
	if amount < 0:
		print("tried to add negative cash")
		return
	cash += amount
	update_cash.emit(cash)

func spend_cash(amount):
	if amount < 0:
		print("tried to spend negative cash")
		return
	cash -= amount
	update_cash.emit(cash)

func add_passive_income(amount):
	passive_income += amount
	update_passive_income.emit(amount)
