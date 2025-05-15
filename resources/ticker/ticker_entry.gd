# res://resources/ticker/TickerEntry.gd
class_name TickerEntry
extends Resource

@export var text: String
@export var categories: Array[String] = []   # e.g. ["finance", "crypto", "tip"]
@export var conditions: Array[String] = []   # e.g. ["player_has_stocks", "debt_over_1000"]
@export var weight: float = 1.0              # For weighted random selection
@export var once_only: bool = false          # Show once, ever (for tips or jokes)
