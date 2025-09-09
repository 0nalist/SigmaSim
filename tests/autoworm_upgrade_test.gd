extends Node

func _ready() -> void:
	var id := "earlybird_autoworm"
	var prev_level := UpgradeManager.get_level(id)
	var prev_cash = PortfolioManager.cash
	UpgradeManager.player_levels[id] = 10
	PortfolioManager.cash = 0
	StatManager.recalculate_all_stats_once()

	var worm := Area2D.new()
	worm.set_script(load("res://components/apps/early_bird/worm.gd"))
	var sprite := Sprite2D.new(); sprite.name = "Sprite2D"; worm.add_child(sprite)
	var tex := TextureRect.new(); tex.name = "WormTexture"; worm.add_child(tex)
	var timer := Timer.new(); timer.name = "Timer"; timer.autostart = true; worm.add_child(timer)
	add_child(worm)
	await get_tree().process_frame
	worm.show()

	await get_tree().create_timer(1.2).timeout
	assert(PortfolioManager.cash >= 1.0)

	UpgradeManager.player_levels[id] = prev_level
	PortfolioManager.cash = prev_cash
	print("autoworm_upgrade_test passed")
