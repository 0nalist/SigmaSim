# Stock.gd
extends Resource
class_name Stock

@export var symbol: String
@export var price: int
@export var volatility: float
@export var shares_outstanding: int
@export var sentiment: float 

@export var owned: int = 0
