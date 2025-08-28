class_name FumbleProfileUI
extends PanelContainer

@export var profile_bg_color: Color = Color(0.147672, 0.147672, 0.147672, 1.0)
@export var section_bg_color: Color = Color(1, 1, 1, 0.05)
@export var pill_bg_color: Color = Color(0, 0, 0, 0.1)
@export var type_panel_color: Color = Color(1, 1, 1, 0.05)
@export var none_label_color: Color = Color(1.0, 1.0, 1.0, 0.6)
@export var label_color: Color = Color(1, 1, 1, 1)
@export var value_color: Color = Color(1, 1, 1, 1)

@onready var portrait: PortraitView = %Portrait
@onready var dime_status_label: Label = %DimeStatusLabel
@onready var name_label: Label = %NameLabel
@onready var type_panel: PanelContainer = %TypePanel
@onready var type_label: Label = %TypeLabel
@onready var job_label: Label = %JobLabel
@onready var likes_container: Control = %LikesContainer
@onready var likes_label: Label = %LikesLabel
@onready var dislikes_container: Control = %DislikesContainer
@onready var dislikes_label: Label = %DislikesLabel
@onready var tags_container: Control = %TagsContainer
@onready var tags_label: Label = %TagsLabel
@onready var bio_text: RichTextLabel = %BioText
@onready var astrology_value: Label = %AstrologyValue
@onready var greek_stats_ui: Node = %GreekStatsUI
@onready var wealth_value: Label = %WealthValue
@onready var mbti_value: Label = %MBTIValue
@onready var openness_value: Label = %OpennessValue
@onready var conscientiousness_value: Label = %ConscientiousnessValue
@onready var extraversion_value: Label = %ExtraversionValue
@onready var agreeableness_value: Label = %AgreeablenessValue
@onready var neuroticism_value: Label = %NeuroticismValue

@onready var likes_section: VBoxContainer = %LikesSection
@onready var dislikes_section: VBoxContainer = %DislikesSection
@onready var bio_panel: PanelContainer = %BioPanel
@onready var tags_section: VBoxContainer = %TagsSection
@onready var greek_panel: PanelContainer = %GreekPanel
@onready var stats_grid: GridContainer = %GridContainer

# Updated: astrology_row / wealth_row don’t exist in your scene,
# so we animate the value labels instead.
@onready var sections: Array[Control] = [
																dime_status_label,
																name_label,
																type_panel,
																job_label,
																likes_section,
																dislikes_section,
																bio_panel,
																tags_section,
																stats_grid,
																greek_panel
]


func _ready() -> void:
		_apply_colors()

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
	job_label.text = _safe_str(npc.occupation)

	_populate_likes(npc)
	_populate_dislikes(npc)
	_populate_bio(npc)
	_populate_tags(npc)
	_populate_astrology(npc)
	_populate_greek(npc)
	_populate_wealth(npc)
	_populate_mbti(npc)
	_populate_ocean(npc)

	call_deferred("_run_entrance_animation")

func _apply_colors() -> void:
	var root_style: StyleBoxFlat = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	root_style.bg_color = profile_bg_color
	add_theme_stylebox_override("panel", root_style)

	var section_style: StyleBoxFlat = bio_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	section_style.bg_color = section_bg_color
	bio_panel.add_theme_stylebox_override("panel", section_style)
	greek_panel.add_theme_stylebox_override("panel", section_style.duplicate())

	var type_style: StyleBoxFlat = type_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	type_style.bg_color = type_panel_color
	type_panel.add_theme_stylebox_override("panel", type_style)

	dime_status_label.modulate = label_color
	name_label.modulate = label_color
	type_label.modulate = label_color
	job_label.modulate = label_color
	likes_label.modulate = label_color
	dislikes_label.modulate = label_color
	tags_label.modulate = label_color

	bio_text.modulate = value_color
	astrology_value.modulate = value_color
	wealth_value.modulate = value_color
	mbti_value.modulate = value_color
	openness_value.modulate = value_color
	conscientiousness_value.modulate = value_color
	extraversion_value.modulate = value_color
	agreeableness_value.modulate = value_color
	neuroticism_value.modulate = value_color

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
		none_label.modulate = none_label_color
		likes_container.add_child(none_label)

func _populate_dislikes(npc: NPC) -> void:
		dislikes_label.text = "Dislikes"
		_clear_children(dislikes_container)
		if npc.dislikes != null and npc.dislikes.size() > 0:
				for dislike in npc.dislikes:
						var pill: Control = _make_like_pill(_safe_str(dislike))
						dislikes_container.add_child(pill)
		else:
				var none_label: Label = Label.new()
				none_label.text = "No dislikes listed"
				none_label.modulate = none_label_color
				dislikes_container.add_child(none_label)

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
				none_label.modulate = none_label_color
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

func _populate_mbti(npc: NPC) -> void:
		var mbti: String = npc.mbti
		if mbti == null or mbti == "":
				mbti_value.text = "Unknown"
		else:
				mbti_value.text = str(mbti)

func _populate_ocean(npc: NPC) -> void:
		openness_value.text = "%0.1f" % npc.openness
		conscientiousness_value.text = "%0.1f" % npc.conscientiousness
		extraversion_value.text = "%0.1f" % npc.extraversion
		agreeableness_value.text = "%0.1f" % npc.agreeableness
		neuroticism_value.text = "%0.1f" % npc.neuroticism


func _run_entrance_animation() -> void:
        await _await_layout_ready()

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
                var delay: float = float(index) * delay_step
                root_tween.parallel().tween_property(node, "modulate:a", 1.0, 0.25).set_delay(delay)
                root_tween.parallel().tween_property(node, "position:y", 0.0, 0.25).from(10.0).as_relative().set_delay(delay)
                index += 1


func _await_layout_ready() -> void:
        await get_tree().process_frame
        await get_tree().process_frame
        var attempts := 0
        while stats_grid.position.y == 0 and attempts < 10:
                await get_tree().process_frame
                attempts += 1


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _make_like_pill(text: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = pill_bg_color
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
	label.modulate = value_color
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
