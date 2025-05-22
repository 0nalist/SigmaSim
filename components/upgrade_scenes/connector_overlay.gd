extends Node2D

var card_dict: Dictionary = {}

func set_cards(dict: Dictionary) -> void:
	card_dict = dict
	queue_redraw()

func _draw():
	for upgrade_id in card_dict:
		var card = card_dict[upgrade_id]
		if not card.upgrade or not card.upgrade.prerequisites:
			continue
		var from_pos = card.global_position + card.size / 2
		for prereq_id in card.upgrade.prerequisites:
			if card_dict.has(prereq_id):
				var prereq_card = card_dict[prereq_id]
				var to_pos = prereq_card.global_position + prereq_card.size / 2
				draw_line(from_pos, to_pos, Color.WHITE, 4.0)
