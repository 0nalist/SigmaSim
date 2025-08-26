class_name FumbleProfileUI
extends PanelContainer

@onready var portrait: PortraitView = %Portrait
@onready var dime_status_label: Label = %DimeStatusLabel
@onready var name_label: Label = %NameLabel
@onready var type_label: Label = %TypeLabel
@onready var likes_container: Control = %LikesContainer
@onready var likes_label: Label = %LikesLabel
@onready var tags_container: Control = %TagsContainer
@onready var tags_label: Label = %TagsLabel
@onready var bio_text: RichTextLabel = %BioText
@onready var astrology_value: Label = %AstrologyValue
@onready var greek_stats_ui: Node = %GreekStatsUI
@onready var wealth_value: Label = %WealthValue

@onready var likes_section: VBoxContainer = %LikesSection
@onready var tags_section: VBoxContainer = %TagsSection
@onready var bio_panel: PanelContainer = %BioPanel
@onready var astrology_row: HBoxContainer = %AstrologyRow
@onready var greek_panel: PanelContainer = %GreekPanel
@onready var wealth_row: HBoxContainer = %WealthRow

@onready var sections: Array[Control] = [
		dime_status_label,
		name_label,
		type_label,
		likes_section,
		tags_section,
		bio_panel,
		astrology_row,
		greek_panel,
		wealth_row
]

func load_npc(npc: NPC, npc_idx: int = -1) -> void:
	portrait.apply_config(npc.portrait_config)
	portrait.portrait_creator_enabled = true
	portrait.subject_npc_idx = npc_idx

	var dime_status: String
	if Engine.has_singleton("NPCManager"):
		var mgr: Object = Engine.get_singleton("NPCManager")
		if mgr.has_method("get_dime_status"):
			dime_status = str(mgr.call("get_dime_status", npc))
		else:
			dime_status = "🔥 %0.1f/10" % (float(npc.attractiveness) / 10.0)
	else:
		dime_status = "🔥 %0.1f/10" % (float(npc.attractiveness) / 10.0)
	dime_status_label.text = dime_status

	name_label.text = npc.full_name
	type_label.text = str(npc.chat_battle_type)

	_populate_likes(npc)
	_populate_tags(npc)
	_populate_bio(npc)
	_populate_astrology(npc)
	_populate_greek(npc)
	_populate_wealth(npc)

	_run_entrance_animation()

func _populate_likes(npc: NPC) -> void:
	likes_label.text = "Likes"
	_clear_children(likes_container)
	if npc.likes != null and npc.likes.size() > 0:
		for like in npc.likes:
			var pill: Control = _make_like_pill(_safe_str(like))
			likes_container.add_child(pill)
	else:
		var none_label: Label = Label.new()
		none_label.text = "No likes listed"
		none_label.modulate = Color(1.0, 1.0, 1.0, 0.6)
		likes_container.add_child(none_label)

func _populate_tags(npc: NPC) -> void:
		tags_label.text = "Tags"
		_clear_children(tags_container)
		if npc.tags != null and npc.tags.size() > 0:
				for tag in npc.tags:
						var pill: Control = _make_like_pill(_safe_str(tag))
						tags_container.add_child(pill)
		else:
				var none_label: Label = Label.new()
				none_label.text = "No tags listed"
				none_label.modulate = Color(1.0, 1.0, 1.0, 0.6)
				tags_container.add_child(none_label)

func _populate_bio(npc: NPC) -> void:
	var lines: Array[String] = []
	if npc.fumble_bio != null and npc.fumble_bio != "":
		lines.append(_safe_str(npc.fumble_bio))
	else:
		if npc.occupation != null and npc.occupation != "":
			lines.append("Occupation: %s" % _safe_str(npc.occupation))
		if npc.relationship_status != null and npc.relationship_status != "":
			lines.append("Relationship: %s" % _safe_str(npc.relationship_status))
		lines.append("Affinity: %s" % _safe_str(npc.affinity))
		lines.append("Rizz: %s" % _safe_str(npc.rizz))
		lines.append("Gender: %s" % npc.describe_gender())
	bio_text.text = "\n\n".join(lines)

func _populate_astrology(npc: NPC) -> void:
	var astro: Variant = npc.get("astrology_sign")
	if astro == null or astro == "":
		astro = npc.get("astrology")
	if astro == null or astro == "":
		astro = npc.get("zodiac")
	if astro == null or astro == "":
		astrology_value.text = "Unknown"
	else:
		astrology_value.text = str(astro)

func _populate_greek(npc: NPC) -> void:
	var stats: Dictionary = {
		"alpha": npc.alpha,
		"beta": npc.beta,
		"gamma": npc.gamma,
		"delta": npc.delta,
		"omega": npc.omega,
		"sigma": npc.sigma
	}
	if greek_stats_ui.has_method("set_stats"):
		greek_stats_ui.call("set_stats", stats)
		return
	if greek_stats_ui.has_method("update_from_npc"):
		greek_stats_ui.call("update_from_npc", npc)
		return
	for key in stats.keys():
		var bar: Variant = greek_stats_ui.get("%s_progress_bar" % key)
		if typeof(bar) == TYPE_OBJECT and bar != null:
			bar.value = stats[key]

func _populate_wealth(npc: NPC) -> void:
	var formatted: String
	if Engine.has_singleton("NumberFormatter") and NumberFormatter.has_method("format_commas"):
		formatted = NumberFormatter.format_commas(npc.wealth)
	else:
		formatted = format_commas(npc.wealth)
	wealth_value.text = "$" + formatted

func _run_entrance_animation() -> void:
	portrait.modulate.a = 0.0
	var p_tween: Tween = create_tween()
	var py: float = portrait.position.y
	p_tween.tween_property(portrait, "modulate:a", 1.0, 0.25)
	p_tween.parallel().tween_property(portrait, "position:y", py, 0.25).from(py - 20.0)

	var root_tween: Tween = create_tween()
	var delay_step: float = 0.06
	var index: int = 0
	for node in sections:
		node.modulate.a = 0.0
		var ny: float = node.position.y
		var delay: float = float(index) * delay_step
		root_tween.parallel().tween_property(node, "modulate:a", 1.0, 0.25).set_delay(delay)
		root_tween.parallel().tween_property(node, "position:y", ny, 0.25).from(ny + 10.0).set_delay(delay)
		index += 1

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _make_like_pill(text: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	var label: Label = Label.new()
	label.text = text
	margin.add_child(label)
	panel.add_child(margin)
	return panel

func _safe_str(v: Variant) -> String:
	if v == null:
		return ""
	if typeof(v) == TYPE_STRING:
		return v
	return str(v)

func format_commas(value: int) -> String:
	var sign: String = ""
	var abs_val: int = value
	if value < 0:
		sign = "-"
		abs_val = -value
	var digits: String = str(abs_val)
	var pieces: Array[String] = []
	while digits.length() > 3:
		pieces.insert(0, digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	pieces.insert(0, digits)
	return sign + ",".join(pieces)

func animate_swipe_left(on_complete: Callable) -> void:
	pivot_offset = size / 2
	var swipe_distance: float = 2.0 * size.x + 100.0
	var duration: float = 0.35
	var final_rotation: float = -18.0
	var target_x: float = position.x - swipe_distance
	var tween1: Tween = create_tween()
	tween1.tween_property(self, "position:x", target_x, duration)
	var tween2: Tween = create_tween()
	tween2.tween_property(self, "rotation_degrees", final_rotation, duration)
	tween1.tween_callback(on_complete)
	tween1.tween_callback(queue_free)

func animate_swipe_right(on_complete: Callable) -> void:
	pivot_offset = size / 2
	var swipe_distance: float = 2.0 * size.x + 100.0
	var duration: float = 0.35
	var final_rotation: float = 18.0
	var target_x: float = position.x + swipe_distance
	var tween1: Tween = create_tween()
	tween1.tween_property(self, "position:x", target_x, duration)
	var tween2: Tween = create_tween()
	tween2.tween_property(self, "rotation_degrees", final_rotation, duration)
	tween1.tween_callback(on_complete)
	tween1.tween_callback(queue_free)
