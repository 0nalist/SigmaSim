# Stock.gd
extends Resource
class_name Stock

@export var symbol: String
@export var price: int
@export var volatility: float
@export var owned: int = 0
