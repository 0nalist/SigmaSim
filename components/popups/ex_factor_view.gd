extends Pane
class_name ExFactorView

const STAGE_NAMES: Array[String] = ["STRANGER","TALKING","DATING","SERIOUS","ENGAGED","MARRIED","DIVORCED","EX"]
const PROGRESS_SAVE_INTERVAL: float = 0.5
const PROGRESS_MIN_DELTA: float = 0.01

@onready var name_label: Label = %NameLabel
@onready var portrait_view: PortraitView = %Portrait
@onready var relationship_stage_label: Label = %RelationshipStageLabel
@onready var relationship_bar: RelationshipBar = %RelationshipBar
@onready var next_stage_button: Button = %NextStageButton
@onready var affinity_bar: AffinityBar = %AffinityBar
@onready var relationship_value_label: Label = %RelationshipValueLabel
@onready var affinity_value_label: Label = %AffinityValueLabel
@onready var love_button: Button = %LoveButton
@onready var love_cooldown_label: Label = %LoveCooldownLabel
@onready var gift_button: Button = %GiftButton
@onready var date_button: Button = %DateButton
@onready var breakup_button: Button = %BreakupButton
@onready var apologize_button: Button = %ApologizeButton
@onready var breakup_confirm: CenterContainer = %BreakupConfirm
@onready var breakup_confirm_label: Label = %BreakupConfirmLabel
@onready var breakup_confirm_yes_button: Button = %BreakupConfirmYesButton
@onready var breakup_confirm_no_button: Button = %BreakupConfirmNoButton
@onready var next_stage_confirm: CenterContainer = %NextStageConfirm
@onready var next_stage_confirm_label: Label = %NextStageConfirmLabel
@onready var next_stage_confirm_primary_button: Button = %NextStageConfirmPrimaryButton
@onready var next_stage_confirm_alt_button: Button = %NextStageConfirmAltButton
@onready var next_stage_confirm_no_button: Button = %NextStageConfirmNoButton
@onready var dime_status_label: Label = %DimeStatusLabel
@onready var relationship_status_label: Label = %RelationshipStatusLabel
@onready var exclusivity_label: Label = %ExclusivityLabel
@onready var exclusivity_button: Button = %ExclusivityButton

const SPEECH_BUBBLE_SCENE := preload("res://components/ui/speech_bubble.tscn")
const QUIPS_PATH := "res://data/npc_data/exfactor/eXFactorQuips.json"
const QUIP_CHAR_DELAY: float = 0.05

var _quips: Array = []
var _active_speech_bubble: SpeechBubble

var npc: NPC
var logic: ExFactorLogic = ExFactorLogic.new()
var npc_idx: int = -1
var last_saved_progress: float = 0.0
var progress_save_elapsed: float = 0.0
var pending_npc_idx: int = -1
var breakup_preview: float = 0.0

func setup_custom(data: Dictionary) -> void:
	npc = data.get("npc")
	npc_idx = data.get("npc_idx", -1)
	unique_popup_key = "ex_factor_%d" % npc_idx

	if logic.get_parent() == null:
		add_child(logic)

	logic.setup(npc, npc_idx)
	_connect_logic_signals()

	last_saved_progress = npc.relationship_progress

	if is_node_ready():
		_finalize_setup()
	else:
		ready.connect(_finalize_setup, CONNECT_ONE_SHOT)

func _connect_logic_signals() -> void:
	logic.progress_changed.connect(_on_progress_changed)
	logic.stage_gate_reached.connect(_on_stage_gate)
	logic.stage_changed.connect(_on_stage_changed)
	logic.affinity_changed.connect(_on_affinity_changed)
	logic.equilibrium_changed.connect(_on_equilibrium_changed)
	logic.costs_changed.connect(_on_costs_changed)
	logic.cooldown_changed.connect(_on_cooldown_changed)
	logic.exclusivity_changed.connect(_on_exclusivity_changed)
	logic.blocked_state_changed.connect(_on_blocked_state_changed)
	logic.request_persist.connect(_persist_fields)

	if npc_idx != -1:
		NPCManager.affinity_changed.connect(_on_npc_affinity_changed)
		NPCManager.affinity_equilibrium_changed.connect(_on_npc_equilibrium_changed)
		NPCManager.exclusivity_core_changed.connect(_on_npc_exclusivity_core_changed)
		NPCManager.relationship_stage_changed.connect(_on_npc_stage_changed)
		NPCManager.cheating_detected.connect(_on_cheating_detected)


func _finalize_setup() -> void:
	if npc == null:
		return
	name_label.text = npc.full_name
	portrait_view.portrait_creator_enabled = true
	if npc_idx != -1:
		portrait_view.subject_npc_idx = npc_idx
	if portrait_view.has_method("apply_config") and npc.portrait_config:
		portrait_view.apply_config(npc.portrait_config)

	_refresh_all()

func _ready() -> void:
	gift_button.pressed.connect(_on_gift_pressed)
	date_button.pressed.connect(_on_date_pressed)
	breakup_button.pressed.connect(_on_breakup_pressed)
	apologize_button.pressed.connect(_on_apologize_pressed)
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	breakup_confirm_yes_button.pressed.connect(_on_breakup_confirm_yes_pressed)
	breakup_confirm_no_button.pressed.connect(_on_breakup_confirm_no_pressed)
	next_stage_confirm_primary_button.pressed.connect(_on_next_stage_confirm_primary_pressed)
	next_stage_confirm_alt_button.pressed.connect(_on_next_stage_confirm_alt_pressed)
	next_stage_confirm_no_button.pressed.connect(_on_next_stage_confirm_no_pressed)
	love_button.pressed.connect(_on_love_pressed)
	exclusivity_button.pressed.connect(_on_exclusivity_button_pressed)
	StatManager.stat_changed.connect(_on_stat_changed)
	TimeManager.minute_passed.connect(_on_minute_passed)

	await get_tree().process_frame
	if Events.has_signal("ex_factor_talk_therapy_purchased"):
		Events.connect("ex_factor_talk_therapy_purchased", _on_talk_therapy_purchased)

func _process(delta: float) -> void:
	if npc == null:
		return
	logic.process(delta)

	# Throttle progress autosave.
	if npc_idx != -1 and npc.relationship_progress != last_saved_progress:
		progress_save_elapsed += delta
		if progress_save_elapsed >= PROGRESS_SAVE_INTERVAL and abs(npc.relationship_progress - last_saved_progress) >= PROGRESS_MIN_DELTA:
			_persist_fields({"relationship_progress": npc.relationship_progress})
			last_saved_progress = npc.relationship_progress
			progress_save_elapsed = 0.0

func _exit_tree() -> void:
	if TimeManager.minute_passed.is_connected(_on_minute_passed):
		TimeManager.minute_passed.disconnect(_on_minute_passed)

	if npc_idx != -1:
		if NPCManager.affinity_changed.is_connected(_on_npc_affinity_changed):
			NPCManager.affinity_changed.disconnect(_on_npc_affinity_changed)
		if NPCManager.affinity_equilibrium_changed.is_connected(_on_npc_equilibrium_changed):
			NPCManager.affinity_equilibrium_changed.disconnect(_on_npc_equilibrium_changed)
		if NPCManager.exclusivity_core_changed.is_connected(_on_npc_exclusivity_core_changed):
			NPCManager.exclusivity_core_changed.disconnect(_on_npc_exclusivity_core_changed)
		# NEW:
		if NPCManager.relationship_stage_changed.is_connected(_on_npc_stage_changed):
			NPCManager.relationship_stage_changed.disconnect(_on_npc_stage_changed)
		if NPCManager.cheating_detected.is_connected(_on_cheating_detected):
			NPCManager.cheating_detected.disconnect(_on_cheating_detected)

	if npc.relationship_progress != last_saved_progress:
		_persist_fields({"relationship_progress": npc.relationship_progress})



# ---------------------------- Persistence glue ----------------------------

func _persist_fields(fields: Dictionary) -> void:
	if npc_idx == -1:
		return
	NPCManager.promote_to_persistent(npc_idx)
	for k in fields.keys():
		NPCManager.set_npc_field(npc_idx, String(k), fields[k])

# ---------------------------- Save API ----------------------------

func get_custom_save_data() -> Dictionary:
	if npc_idx != -1:
		NPCManager.promote_to_persistent(npc_idx)
		return {"npc_idx": npc_idx}
	if pending_npc_idx != -1:
		NPCManager.promote_to_persistent(pending_npc_idx)
		return {"npc_idx": pending_npc_idx}
	return {}

func load_custom_save_data(data: Dictionary) -> void:
	pending_npc_idx = data.get("npc_idx", -1)
	if pending_npc_idx == -1:
			return

	if is_node_ready():
			call_deferred("_try_load_npc")
	else:
			ready.connect(_try_load_npc, CONNECT_ONE_SHOT)

func _try_load_npc() -> void:
	if pending_npc_idx == -1:
		return
	while pending_npc_idx != -1:
		var found: NPC = NPCManager.get_npc_by_index(pending_npc_idx)
		if found:
			await setup_custom({"npc": found, "npc_idx": pending_npc_idx})
			pending_npc_idx = -1
		else:
			await get_tree().process_frame

# ---------------------------- UI updates ----------------------------

func _refresh_all() -> void:
	_update_relationship_bar()
	_update_affinity_bar()
	_update_buttons_text()
	_update_love_button()
	_update_dime_status_label()
	_update_relationship_status_label()
	_update_exclusivity_label()
	_update_exclusivity_button()
	_update_next_stage_button()
	_update_apologize_button()
	
func _update_relationship_bar() -> void:
	var stage: int = npc.relationship_stage
	if stage == NPCManager.RelationshipStage.MARRIED:
			var level: int = ExFactorLogic.get_marriage_level(npc.relationship_progress)
			relationship_stage_label.text = "Level %d Marriage" % level
			var bounds: Vector2 = ExFactorLogic.get_stage_bounds(stage, npc.relationship_progress)
			var maxv: float = bounds.y - bounds.x
			var val: float = npc.relationship_progress - bounds.x
			relationship_bar.max_value = maxv
			relationship_bar.update_value(val)
			relationship_value_label.text = "%s / %s" % [
					NumberFormatter.format_commas(val, 2),
					NumberFormatter.format_commas(maxv, 2)
			]
			relationship_bar.set_mark_fractions([])
			return

	if stage == NPCManager.RelationshipStage.DIVORCED or stage == NPCManager.RelationshipStage.EX:
		relationship_stage_label.text = STAGE_NAMES[stage]
		relationship_bar.set_mark_fractions([])
		relationship_value_label.text = ""
		return

	var next_stage: int = stage + 1
	relationship_stage_label.text = "%s -> %s" % [STAGE_NAMES[stage], STAGE_NAMES[next_stage]]

	var bounds: Vector2 = ExFactorLogic.get_stage_bounds(stage, npc.relationship_progress)
	var maxv: float = bounds.y - bounds.x
	var val: float = npc.relationship_progress - bounds.x
	relationship_bar.max_value = maxv
	relationship_bar.update_value(val)
	relationship_value_label.text = "%s / %s" % [
		NumberFormatter.format_commas(val, 2),
		NumberFormatter.format_commas(maxv, 2)
	]
	relationship_bar.set_mark_fractions(logic.get_stop_marks())

func _update_affinity_bar() -> void:
	affinity_bar.max_value = 100.0
	affinity_bar.update_value(npc.affinity)
	affinity_bar.set_affinity_equilibrium(npc.affinity_equilibrium)
	affinity_value_label.text = "%s / 100" % NumberFormatter.format_commas(npc.affinity, 0)

func _update_buttons_text() -> void:
	gift_button.text = "Gift ($%s)" % NumberFormatter.format_commas(npc.gift_cost)
	date_button.text = "Date ($%s)" % NumberFormatter.format_commas(npc.date_cost)
	# breakup button label uses preview:
	breakup_preview = logic.preview_breakup_reward()
	if npc.relationship_stage >= NPCManager.RelationshipStage.DIVORCED:
		breakup_button.disabled = true
	else:
		breakup_button.disabled = false
		breakup_button.text = "Breakup & gain %.2f Ex" % breakup_preview

func _update_love_button() -> void:
	if npc.relationship_stage < NPCManager.RelationshipStage.DATING:
		love_button.visible = false
		love_button.disabled = true
		love_cooldown_label.visible = false
		return

	love_button.visible = true
	var now_m: int = TimeManager.get_now_minutes()
	var can: bool = logic.can_love(now_m)
	love_button.disabled = not can
	if can:
		love_cooldown_label.visible = false
	else:
		var remaining: int = npc.love_cooldown - now_m
		if remaining < 0:
			remaining = 0
		var hours: int = remaining / 60
		var minutes: int = remaining % 60
		love_cooldown_label.visible = true
		love_cooldown_label.text = "Love in %dh %dm" % [hours, minutes]

func _update_dime_status_label() -> void:
	dime_status_label.text = "🔥 %.1f/10" % (float(npc.attractiveness) / 10.0)

func _update_relationship_status_label() -> void:
	var text: String = ""
	match npc.relationship_stage:
		NPCManager.RelationshipStage.TALKING:
			text = "You are TALKING to"
		NPCManager.RelationshipStage.DATING:
			match npc.exclusivity_core:
				NPCManager.ExclusivityCore.MONOG:
					text = "You are DATING EXCLUSIVELY"
				NPCManager.ExclusivityCore.CHEATING:
					text = "You are DATING and CHEATING ON"
				_:
					text = "You are DATING"
		NPCManager.RelationshipStage.SERIOUS:
			match npc.exclusivity_core:
				NPCManager.ExclusivityCore.MONOG:
					text = "You are SERIOUSLY DATING, EXCLUSIVELY"
				NPCManager.ExclusivityCore.CHEATING:
					text = "You are SERIOUSLY DATING, and CHEATING ON"
				_:
					text = "You are SERIOUSLY DATING, POLYAMOROUSLY"
		NPCManager.RelationshipStage.ENGAGED:
			match npc.exclusivity_core:
				NPCManager.ExclusivityCore.MONOG:
					text = "You are ENGAGED to"
				NPCManager.ExclusivityCore.CHEATING:
					text = "You are ENGAGED and CHEATING ON"
				_:
					text = "You are ENGAGED, and POLY with"
		NPCManager.RelationshipStage.MARRIED:
			match npc.exclusivity_core:
				NPCManager.ExclusivityCore.MONOG:
					text = "You are MARRIED to"
				NPCManager.ExclusivityCore.CHEATING:
					text = "You are MARRIED and CHEATING ON"
				_:
					text = "You are MARRIED, and POLY with"
		NPCManager.RelationshipStage.DIVORCED, NPCManager.RelationshipStage.EX:
			text = "Your EX:"
		_:
			text = ""
	relationship_status_label.text = text

		# Color the text red if cheating, otherwise remove any override
	if npc.exclusivity_core == NPCManager.ExclusivityCore.CHEATING:
			relationship_status_label.add_theme_color_override("font_color", Color.RED)
	else:
			relationship_status_label.remove_theme_color_override("font_color")



func _update_exclusivity_label() -> void:
	var label_text: String
	if npc_idx != -1:
		label_text = NPCManager.exclusivity_descriptor_label(npc_idx)
	else:
		var desc: int = NPCManager.exclusivity_descriptor_for(
			npc.relationship_stage, npc.exclusivity_core, npc.claimed_exclusive_boost
		)
		match desc:
			NPCManager.ExclusivityDescriptor.UNMENTIONED: label_text = "Unmentioned"
			NPCManager.ExclusivityDescriptor.DATING_AROUND: label_text = "Dating Around"
			NPCManager.ExclusivityDescriptor.EXCLUSIVE: label_text = "Exclusive"
			NPCManager.ExclusivityDescriptor.MONOGAMOUS: label_text = "Monogamous"
			NPCManager.ExclusivityDescriptor.POLYAMOROUS: label_text = "Polyamorous"
			NPCManager.ExclusivityDescriptor.OPEN: label_text = "Open"
			NPCManager.ExclusivityDescriptor.CHEATING: label_text = "Cheating"
			_: label_text = "Unmentioned"

	exclusivity_label.text = "Exclusivity: " + label_text
	if npc.exclusivity_core == NPCManager.ExclusivityCore.CHEATING:
		exclusivity_label.add_theme_color_override("font_color", Color.RED)
	else:
		exclusivity_label.remove_theme_color_override("font_color")

func _update_exclusivity_button() -> void:
		var visible: bool = npc.relationship_stage >= NPCManager.RelationshipStage.DATING and \
						npc.relationship_stage <= NPCManager.RelationshipStage.MARRIED
		exclusivity_button.visible = visible
		if not visible:
						return
		match npc.exclusivity_core:
						NPCManager.ExclusivityCore.MONOG: exclusivity_button.text = "Go Poly"
						NPCManager.ExclusivityCore.POLY: exclusivity_button.text = "Go Monog"
						NPCManager.ExclusivityCore.CHEATING: exclusivity_button.text = "Come Clean"
						_: exclusivity_button.text = "Toggle"

func _update_next_stage_button() -> void:
		var show: bool = logic.progress_paused and npc.relationship_stage < NPCManager.RelationshipStage.DIVORCED
		next_stage_button.visible = show
		next_stage_button.disabled = not show

func _update_apologize_button() -> void:
	var has_upgrade: bool = UpgradeManager.get_level("ex_factor_talk_therapy") > 0
	var in_ex_stage: bool = npc.relationship_stage == NPCManager.RelationshipStage.DIVORCED or npc.relationship_stage == NPCManager.RelationshipStage.EX
	apologize_button.visible = has_upgrade and in_ex_stage
	if not apologize_button.visible:
		return
	var cost: int = logic.get_apologize_cost()
	apologize_button.text = "Apologize (%s Ex)" % NumberFormatter.format_number(cost)
	apologize_button.disabled = StatManager.get_stat("ex", 0.0) < float(cost)


# ---------------------------- Button handlers ----------------------------

func _on_gift_pressed() -> void:
		if logic.try_gift():
				_update_affinity_bar()
				_update_buttons_text()
				_show_quip("gift")

func _on_date_pressed() -> void:
		if logic.try_date():
				_update_relationship_bar()
				_update_buttons_text()
				_show_quip("date")

func _on_love_pressed() -> void:
		var now_m: int = TimeManager.get_now_minutes()
		logic.apply_love(now_m)
		_update_affinity_bar()
		_update_love_button()
		_show_quip("love")

func _on_breakup_pressed() -> void:
	breakup_preview = logic.preview_breakup_reward()
	var text: String = "Are you sure you want to break up with %s and gain %.2f EX?" % [npc.first_name, breakup_preview]
	if npc.relationship_stage == NPCManager.RelationshipStage.MARRIED:
		text += "\n\n%s will get half of all of your assets" % npc.first_name
	breakup_confirm_label.text = text
	breakup_confirm.visible = true

func _on_breakup_confirm_yes_pressed() -> void:
		breakup_confirm.visible = false
		logic.confirm_breakup()
		_refresh_all()
		_show_quip("breakup")

func _on_breakup_confirm_no_pressed() -> void:
	breakup_confirm.visible = false

func _on_apologize_pressed() -> void:
	var ok: bool = logic.apologize_try()
	if ok:
		_refresh_all()

func _on_next_stage_pressed() -> void:
	next_stage_button.visible = false
	_prepare_next_stage_confirm()
	next_stage_confirm.visible = true

func _prepare_next_stage_confirm() -> void:
	var current_stage: int = npc.relationship_stage
	var current_name: String = STAGE_NAMES[current_stage]
	var next_name: String = STAGE_NAMES[min(current_stage + 1, STAGE_NAMES.size() - 1)]
	next_stage_confirm_label.text = "Progress to %s?" % next_name
	next_stage_confirm_no_button.text = "Stay %s" % current_name
	next_stage_confirm_alt_button.visible = false
	if current_stage == NPCManager.RelationshipStage.DATING:
		if npc.exclusivity_core == NPCManager.ExclusivityCore.POLY:
			next_stage_confirm_label.text = "How do you want to get serious?"
			next_stage_confirm_primary_button.text = "Get SERIOUS, Monogamously"
			next_stage_confirm_alt_button.text = "Get SERIOUS, Polyamorously"
			next_stage_confirm_alt_button.visible = true
		else:
			next_stage_confirm_primary_button.text = "Get SERIOUS"
	elif current_stage == NPCManager.RelationshipStage.SERIOUS:
		next_stage_confirm_primary_button.text = "Propose ($%s)" % NumberFormatter.format_commas(npc.proposal_cost, 0)
	else:
		next_stage_confirm_primary_button.text = "Progress to %s" % next_name

func _on_next_stage_confirm_primary_pressed() -> void:
	next_stage_confirm.visible = false
	logic.request_next_stage_primary()
	_refresh_all()
	_show_quip("next level")

func _on_next_stage_confirm_alt_pressed() -> void:
	next_stage_confirm.visible = false
	logic.request_next_stage_alt_for_dating()
	_refresh_all()
	_show_quip("next level")

func _on_next_stage_confirm_no_pressed() -> void:
		next_stage_confirm.visible = false
		_update_next_stage_button()

func _on_exclusivity_button_pressed() -> void:
		logic.toggle_exclusivity()
		_update_exclusivity_label()
		_update_exclusivity_button()
		_update_relationship_status_label()
		_update_affinity_bar()

func _load_quips() -> void:
		if _quips.size() == 0:
				var file = FileAccess.open(QUIPS_PATH, FileAccess.READ)
				if file:
						_quips = JSON.parse_string(file.get_as_text())

func _pick_variant(text: String, rng: RandomNumberGenerator) -> String:
		if text.is_empty():
				return ""
		var parts = text.split(";;")
		return parts[rng.randi_range(0, parts.size() - 1)]

func _select_quip(action: String) -> String:
		_load_quips()
		if npc == null:
				return ""
		var stage_str = STAGE_NAMES[npc.relationship_stage].to_lower()
		var exclusivity_str: String
		if npc.exclusivity_core == NPCManager.ExclusivityCore.POLY:
			exclusivity_str = "poly"
		else:
			exclusivity_str = "monog"
		var rng = RNGManager.npc_manager.get_rng()
		var candidates: Array = []
		for entry in _quips:
				if entry.get("action", "") not in [action, "any"]:
						continue
				if entry.get("stage", "any") not in [stage_str, "any"]:
						continue
				if entry.get("exclusivity", "any") not in [exclusivity_str, "any"]:
						continue
				candidates.append(entry)
		if candidates.is_empty():
				return ""
		var chosen: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		var prefix = _pick_variant(chosen.get("prefix", ""), rng)
		var core = _pick_variant(chosen.get("core", ""), rng)
		var suffix = _pick_variant(chosen.get("suffix", ""), rng)
		var line = prefix + core + suffix
		line = line.replace("{random first_name}", "{random_first_name}")
		return MarkupParser.parse(line, npc)

func _show_quip(action: String) -> void:
	if _active_speech_bubble and is_instance_valid(_active_speech_bubble):
		return
	var text = _select_quip(action)
	if text == "":
		return
	var bubble: SpeechBubble = SPEECH_BUBBLE_SCENE.instantiate()
	add_child(bubble)
	bubble.set_as_top_level(true)
	bubble.set_text(text)
	bubble.follow(portrait_view)
	_active_speech_bubble = bubble
	bubble.tree_exited.connect(func(): _active_speech_bubble = null)
	var label: Label = bubble.get_label()
	label.visible_ratio = 0.0
	var lifetime: float = max(3.0, text.length() * QUIP_CHAR_DELAY + 1.0)
	bubble.pop_and_fade(lifetime)
	await get_tree().create_timer(0.35).timeout
	for i in range(text.length()):
		label.visible_ratio = float(i + 1) / text.length()
		await get_tree().create_timer(QUIP_CHAR_DELAY).timeout

# ---------------------------- Logic signal sinks ----------------------------

func _on_progress_changed(_p: float) -> void:
	_update_relationship_bar()

func _on_stage_gate() -> void:
		_update_next_stage_button()

func _on_stage_changed(_stage: int) -> void:
	_update_relationship_bar()
	_update_love_button()
	_update_relationship_status_label()
	_update_exclusivity_label()
	_update_exclusivity_button()
	_update_next_stage_button()

func _on_affinity_changed(_a: float) -> void:
	_update_affinity_bar()

func _on_equilibrium_changed(_e: float) -> void:
	_update_affinity_bar()

func _on_costs_changed(_gift: float, _date: float) -> void:
	_update_buttons_text()

func _on_cooldown_changed(_ready_at: int) -> void:
		_update_love_button()

func _on_minute_passed(_m: int) -> void:
		_update_love_button()

func _on_exclusivity_changed(_core: int) -> void:
	_update_relationship_status_label()
	_update_exclusivity_label()
	_update_exclusivity_button()

func _on_blocked_state_changed(is_blocked: bool) -> void:
	gift_button.disabled = is_blocked
	date_button.disabled = is_blocked
	_update_apologize_button()


func _on_talk_therapy_purchased(_level: int) -> void:
	_update_apologize_button()


func _on_stat_changed(stat: String, _value: Variant) -> void:
	if stat == "ex":
		_update_apologize_button()

func _on_npc_affinity_changed(idx: int, _value: float) -> void:
				if idx != npc_idx:
								return
				_sync_from_manager()
				_update_affinity_bar()

func _on_npc_equilibrium_changed(idx: int, _value: float) -> void:
								if idx != npc_idx:
																return
								_sync_from_manager()
								_update_affinity_bar()

func _on_npc_exclusivity_core_changed(idx: int, _old_core: int, _new_core: int) -> void:
								if idx != npc_idx:
																return
								_sync_from_manager()
								_update_exclusivity_label()
								_update_exclusivity_button()
								_update_relationship_status_label()

func _on_npc_stage_changed(idx: int, _old_stage: int, _new_stage: int) -> void:
		if idx != npc_idx:
				return
		_sync_from_manager()
		# Re-run all UI derived from stage.
		_update_relationship_bar()
		_update_love_button()
		_update_relationship_status_label()
		_update_exclusivity_label()
		_update_exclusivity_button()
		_update_next_stage_button()
		_update_apologize_button()

func _on_cheating_detected(primary_idx: int, other_idx: int) -> void:
		# If this view’s NPC is either the one marked cheating or the “other”, refresh.
		if primary_idx != npc_idx and other_idx != npc_idx:
				return
		_sync_from_manager()
		_update_relationship_status_label()
		_update_exclusivity_label()
		_update_exclusivity_button()
		_update_affinity_bar()

func _sync_from_manager() -> void:
	if npc_idx == -1:
		return
	var latest: NPC = NPCManager.get_npc_by_index(npc_idx)
	if latest != null and latest != npc:
		npc = latest
		# keep logic pointing at the same object:
		logic.npc = npc
