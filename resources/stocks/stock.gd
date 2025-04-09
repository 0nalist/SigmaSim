# Stock.gd
extends Resource
class_name Stock

@export var symbol: String
@export var price: float
@export var volatility: float
@export var shares_outstanding: int
@export var sentiment: float = 0.0
@export var momentum: int = 0
