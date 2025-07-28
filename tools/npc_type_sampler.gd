# res://tools/npc_type_sampler.gd
@tool
extends Node

const SAMPLE_SIZE := 10000

func _ready() -> void:
	var counts: Dictionary = {}

	for i in SAMPLE_SIZE:
		var npc := NPCFactory.create_npc(i)
		var t := npc.chat_battle_type
		counts[t] = counts.get(t, 0) + 1

	# --- pretty print, alphabetically ---
	var keys := counts.keys()   # returns Array
	keys.sort()                 # in‑place; no return value
	for t in keys:
		var pct = 100.0 * counts[t] / SAMPLE_SIZE
		print("%s\t%d\t%.2f%%" % [t, counts[t], pct])
 
