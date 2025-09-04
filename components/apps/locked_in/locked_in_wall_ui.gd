class_name LockedInWallUI
extends VBoxContainer

@export var wall_post_scene: PackedScene

func set_posts(posts: Array[String]) -> void:
	clear()
	for post in posts:
		var ui = wall_post_scene.instantiate()
		add_child(ui)
		ui.set_text(post)


func clear() -> void:
	for child in get_children():
		child.queue_free()
