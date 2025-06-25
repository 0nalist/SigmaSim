class_name FumbleProfileUI
extends PanelContainer


@onready var profile_pic: TextureRect = %ProfilePic
@onready var attractiveness_label: Label = %AttractivenessLabel
@onready var name_label: Label = %NameLabel

@onready var tags_container: HBoxContainer = %TagsHBoxContainer

@onready var bio_label: Label = %BioLabel


func load_npc(npc: NPC) -> void:
	# Core info
	name_label.text = npc.full_name
	attractiveness_label.text = "%0.1f/10" % (float(npc.attractiveness) / 10.0)

	# Tags
	_clear_container(tags_container)
	for tag in npc.tags:
		var tag_label = Label.new()
		tag_label.text = tag.capitalize()
		tags_container.add_child(tag_label)

	# Bio lines
	var lines := []
	lines.append("Occupation: %s" % npc.occupation)
	lines.append("Relationship: %s" % npc.relationship_status)
	lines.append("Affinity: %d"  % int(npc.affinity))
	lines.append("Rizz: %d"      % npc.rizz)
	lines.append("Wealth: $%s"   % str(npc.wealth))
	lines.append("Gender: %s"    % npc.describe_gender())

	# Find and display primary greek stat
	var greek_stats = ["alpha", "beta", "gamma", "delta", "omega", "sigma"]
	var max_stat = ""
	var max_val = -9999
	for stat in greek_stats:
		var val = int(npc.get(stat))
		if val > max_val:
			max_val = val
			max_stat = stat
	lines.append("Greek: %s (%d)" % [max_stat.capitalize(), max_val])

	# Pet names if any
	if npc.preferred_pet_names.size() > 0:
		lines.append("Pref. Pets: [%s]" % ", ".join(npc.preferred_pet_names.map(func(p): return str(p))))
	if npc.player_pet_names.size() > 0:
		lines.append("Player Pets: [%s]" % ", ".join(npc.player_pet_names.map(func(p): return str(p))))
	# Bio text
	lines.append("Bio: %s" % npc.bio)

	bio_label.text = "\n".join(lines.map(func(line): return str(line)))

func _clear_container(c: Control) -> void:
	for child in c.get_children():
		child.queue_free()


func animate_swipe_left(on_complete: Callable) -> void:
	self.pivot_offset = self.size / 2
	var duration = 0.35
	var final_rotation = -18
	var target_x = -self.size.x - 50  # Always works (off left edge)
	
	var tween1 = create_tween()
	tween1.tween_property(self, "position:x", target_x, duration)
	var tween2 = create_tween()
	tween2.tween_property(self, "rotation_degrees", final_rotation, duration)
	tween1.tween_callback(on_complete)
	tween1.tween_callback(queue_free)

func animate_swipe_right(on_complete: Callable) -> void:
	self.pivot_offset = self.size / 2
	var duration = 0.35
	var final_rotation = 18

	# Use the parent size if available, fallback to own size
	var parent = get_parent()
	var parent_width = parent.size.x if parent and parent.has_method("get_size") else self.size.x
	var target_x = parent_width + self.size.x + 50

	var tween1 = create_tween()
	tween1.tween_property(self, "position:x", target_x, duration)
	var tween2 = create_tween()
	tween2.tween_property(self, "rotation_degrees", final_rotation, duration)
	tween1.tween_callback(on_complete)
	tween1.tween_callback(queue_free)
