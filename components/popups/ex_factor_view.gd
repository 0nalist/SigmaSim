extends Pane
class_name ExFactorView

#@export var persist_on_save := true

const STAGE_NAMES: Array[String] = ["STRANGER", "TALKING", "DATING", "SERIOUS", "ENGAGED", "MARRIED", "DIVORCED", "EX"]
const LOVE_COOLDOWN_MINUTES: int = 24 * 60
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
@onready var exclusivity_label: Label = %ExclusivityLabel
@onready var exclusivity_button: Button = %ExclusivityButton

var npc: NPC
var logic: SuitorLogic = SuitorLogic.new()
var breakup_reward: float = 0.0
var apologize_cost: int = 10
var npc_idx: int = -1
var last_saved_progress: float = 0.0
var progress_save_elapsed: float = 0.0
var pending_npc_idx: int = -1

func setup_custom(data: Dictionary) -> void:
	npc = data.get("npc")
	npc.gift_cost = (float(npc.attractiveness) / 10.0) * NPC.BASE_GIFT_COST * pow(2.0, npc.gift_count)
	npc.date_cost = (float(npc.attractiveness) / 10.0) * NPC.BASE_DATE_COST * pow(2.0, npc.date_count)
	logic.setup(npc)
	npc_idx = data.get("npc_idx", -1)
	unique_popup_key = "ex_factor_%d" % npc_idx
	last_saved_progress = npc.relationship_progress
	
	await ready
	
	name_label.text = npc.full_name
	portrait_view.portrait_creator_enabled = true
	if npc_idx != -1:
			portrait_view.subject_npc_idx = npc_idx
	if portrait_view.has_method("apply_config") and npc.portrait_config:
			portrait_view.apply_config(npc.portrait_config)
	breakup_reward = 0.0
	apologize_cost = 10

	if npc_idx != -1 and npc.relationship_stage >= NPCManager.RelationshipStage.DATING:
			NPCManager.notify_player_advanced_someone_to_dating(npc_idx)

	_update_all()


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
	NPCManager.affinity_changed.connect(_on_npc_affinity_changed)
	NPCManager.affinity_equilibrium_changed.connect(_on_affinity_equilibrium_changed)
	NPCManager.exclusivity_core_changed.connect(_on_exclusivity_core_changed)
	NPCManager.relationship_stage_changed.connect(_on_relationship_stage_changed)

	if pending_npc_idx != -1:
		call_deferred("_try_load_npc")
	
	await get_tree().process_frame
	if Events.has_signal("ex_factor_talk_therapy_purchased"):
			Events.connect("ex_factor_talk_therapy_purchased", _on_talk_therapy_purchased)


func _process(delta: float) -> void:
	if npc == null or npc.relationship_stage >= NPCManager.RelationshipStage.DIVORCED:
		return
	var prev_progress: float = npc.relationship_progress
	logic.process(delta)
	if npc_idx != -1 and npc.relationship_progress != prev_progress:
		progress_save_elapsed += delta
		if progress_save_elapsed >= PROGRESS_SAVE_INTERVAL and abs(npc.relationship_progress - last_saved_progress) >= PROGRESS_MIN_DELTA:
			NPCManager.promote_to_persistent(npc_idx)
			NPCManager.set_npc_field(npc_idx, "relationship_progress", npc.relationship_progress)
			last_saved_progress = npc.relationship_progress
			progress_save_elapsed = 0.0
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	if npc.relationship_stage < NPCManager.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
		next_stage_button.visible = true
	_update_relationship_bar()
	_update_breakup_button_text()
	_update_love_button()

func _exit_tree() -> void:
				if npc_idx != -1 and npc.relationship_progress != last_saved_progress:
								NPCManager.promote_to_persistent(npc_idx)
								NPCManager.set_npc_field(npc_idx, "relationship_progress", npc.relationship_progress)


func get_custom_save_data() -> Dictionary:
	if npc_idx != -1:
		NPCManager.promote_to_persistent(npc_idx)
		return {"npc_idx": npc_idx}
	elif pending_npc_idx != -1:
		NPCManager.promote_to_persistent(pending_npc_idx)
		return {"npc_idx": pending_npc_idx}
	return {}

func load_custom_save_data(data: Dictionary) -> void:
	pending_npc_idx = data.get("npc_idx", -1)
	if pending_npc_idx != -1 and is_node_ready():
		call_deferred("_try_load_npc")

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


func _update_all() -> void:

	_update_relationship_bar()
	_update_affinity_bar()
	_update_breakup_button_text()
	_update_action_buttons_text()
	_update_love_button()
	_update_dime_status_label()
	_update_exclusivity_label()
	_update_exclusivity_button()
	var blocked: bool = npc.relationship_stage >= NPCManager.RelationshipStage.DIVORCED

	gift_button.disabled = blocked
	date_button.disabled = blocked
	apologize_button.visible = UpgradeManager.get_level("ex_factor_talk_therapy") > 0 and npc.relationship_stage in [NPCManager.RelationshipStage.DIVORCED, NPCManager.RelationshipStage.EX]


func _update_relationship_bar() -> void:
	var current_stage: int = npc.relationship_stage
	if current_stage == NPCManager.RelationshipStage.MARRIED:
			var level: int = npc.get_marriage_level()
			relationship_stage_label.text = "Level %d Marriage" % level
	elif current_stage in [NPCManager.RelationshipStage.DIVORCED, NPCManager.RelationshipStage.EX]:
		relationship_stage_label.text = STAGE_NAMES[current_stage]
	else:
		var next_stage: int = current_stage + 1
		relationship_stage_label.text = "%s -> %s" % [STAGE_NAMES[current_stage], STAGE_NAMES[next_stage]]
		var bounds: Vector2 = SuitorLogic.get_stage_bounds(current_stage, npc.relationship_progress)
		relationship_bar.max_value = bounds.y - bounds.x
		relationship_bar.update_value(npc.relationship_progress - bounds.x)
		relationship_value_label.text = "%s / %s" % [
				NumberFormatter.format_commas(npc.relationship_progress - bounds.x, 2),
				NumberFormatter.format_commas(bounds.y - bounds.x, 2)
		]
		if current_stage < NPCManager.RelationshipStage.MARRIED:
				relationship_bar.set_mark_fractions(logic.get_stop_marks())
		else:
				relationship_bar.set_mark_fractions([])
func _update_affinity_bar() -> void:
		affinity_bar.max_value = 100
		affinity_bar.update_value(npc.affinity)
		affinity_bar.set_affinity_equilibrium(npc.affinity_equilibrium)
		affinity_value_label.text = "%s / 100" % NumberFormatter.format_commas(npc.affinity, 0)

func _update_breakup_button_text() -> void:
	if npc.relationship_stage >= NPCManager.RelationshipStage.DIVORCED:
		breakup_button.disabled = true
		return
	breakup_button.disabled = false
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	var fraction: float = (npc.relationship_progress - bounds.x) / (bounds.y - bounds.x)
	var stage_idx: int = max(1, npc.relationship_stage)
	var base: float
	if npc.relationship_stage < NPCManager.RelationshipStage.MARRIED:
		base = pow(10.0, float(stage_idx - 1))
	else:
		var level: int = npc.get_marriage_level()
		base = 10000.0 * pow(1.5, float(level - 1))
	var reward: float = (0.1 + fraction * 0.9) * base
	breakup_button.text = "Breakup & gain %.2f Ex" % reward
func _update_action_buttons_text() -> void:
	gift_button.text = "Gift ($%s)" % NumberFormatter.format_commas(npc.gift_cost)
	date_button.text = "Date ($%s)" % NumberFormatter.format_commas(npc.date_cost)
	apologize_button.text = "Apologize (%s EX)" % NumberFormatter.format_commas(apologize_cost, 0)

func _update_love_button() -> void:

	if npc == null:
			return
	if npc.relationship_stage < NPCManager.RelationshipStage.DATING:
			love_button.visible = false
			love_cooldown_label.visible = false


			return
	love_button.visible = true
	var now: int = TimeManager.get_now_minutes()
	var remaining: int = npc.love_cooldown - now
	if remaining > 0:
		love_button.disabled = true
		var hours: int = remaining / 60
		var minutes: int = remaining % 60
		love_cooldown_label.visible = true
		love_cooldown_label.text = "Love in %dh %dm" % [hours, minutes]
	else:
		love_button.disabled = false
		love_cooldown_label.visible = false

func _update_dime_status_label() -> void:
		if npc == null:
				return
		dime_status_label.text = "🔥 %.1f/10" % (float(npc.attractiveness) / 10.0)




func _update_exclusivity_label() -> void:
	if npc == null:
		return

	var label_text: String
	if npc_idx != -1:
		label_text = NPCManager.exclusivity_descriptor_label(npc_idx)
	else:
		var desc: int = NPCManager.exclusivity_descriptor_for(
			npc.relationship_stage,
			npc.exclusivity_core,
			npc.claimed_exclusive_boost
		)
		match desc:
			NPCManager.ExclusivityDescriptor.UNMENTIONED:
				label_text = "Unmentioned"
			NPCManager.ExclusivityDescriptor.DATING_AROUND:
				label_text = "Dating Around"
			NPCManager.ExclusivityDescriptor.EXCLUSIVE:
				label_text = "Exclusive"
			NPCManager.ExclusivityDescriptor.MONOGAMOUS:
				label_text = "Monogamous"
			NPCManager.ExclusivityDescriptor.POLYAMOROUS:
				label_text = "Polyamorous"
			NPCManager.ExclusivityDescriptor.OPEN:
				label_text = "Open"
			NPCManager.ExclusivityDescriptor.CHEATING:
				label_text = "Cheating"
			_:
				label_text = "Unmentioned"

	exclusivity_label.text = "Exclusivity: " + label_text
	if npc.exclusivity_core == NPCManager.ExclusivityCore.CHEATING:
		exclusivity_label.add_theme_color_override("font_color", Color.RED)
	else:
		exclusivity_label.remove_theme_color_override("font_color")


func _update_exclusivity_button() -> void:
		if npc == null:
				return
		if npc.relationship_stage < NPCManager.RelationshipStage.DATING or npc.relationship_stage > NPCManager.RelationshipStage.MARRIED:
				exclusivity_button.visible = false
				return
		exclusivity_button.visible = true
		match npc.exclusivity_core:
				NPCManager.ExclusivityCore.MONOG:
						exclusivity_button.text = "Go Poly"
				NPCManager.ExclusivityCore.POLY:
						exclusivity_button.text = "Go Monog"
				NPCManager.ExclusivityCore.CHEATING:
						exclusivity_button.text = "Come Clean"
				_:
						exclusivity_button.text = "Toggle"
func _on_npc_affinity_changed(idx: int, value: float) -> void:
		if idx != npc_idx:
				return
		npc.affinity = value
		_update_affinity_bar()

func _on_affinity_equilibrium_changed(idx: int, value: float) -> void:
		if idx != npc_idx:
				return
		npc.affinity_equilibrium = value
		_update_affinity_bar()

func _on_exclusivity_core_changed(idx: int, _old_core: int, new_core: int) -> void:
				if idx != npc_idx:
								return
				npc.exclusivity_core = new_core
				_update_exclusivity_label()
				_update_exclusivity_button()

func _on_relationship_stage_changed(idx: int, _old_stage: int, new_stage: int) -> void:
	if idx != npc_idx:
		return
	npc.relationship_stage = new_stage
	_update_exclusivity_label()
	_update_exclusivity_button()
	_update_affinity_bar()

func _on_exclusivity_button_pressed() -> void:
	if npc == null:
		return
	match npc.exclusivity_core:
		NPCManager.ExclusivityCore.MONOG:
			if npc_idx != -1:
				if npc.relationship_stage == NPCManager.RelationshipStage.DATING:
					NPCManager.go_poly_during_dating(npc_idx)
				else:
					NPCManager.request_poly_at_serious_or_engaged(npc_idx)
			else:
				npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
				npc.affinity *= 0.1
			_update_affinity_bar()
			_update_exclusivity_label()
			_update_exclusivity_button()

		NPCManager.ExclusivityCore.POLY:
			if npc_idx != -1:
				if npc.relationship_stage == NPCManager.RelationshipStage.DATING:
					NPCManager.go_exclusive_during_dating(npc_idx)
				else:
					NPCManager.return_to_monogamy(npc_idx)
			else:
				var cheating: bool = false
				for idx in NPCManager.encountered_npcs:
					var other_idx: int = int(idx)
					var other: NPC = NPCManager.get_npc_by_index(other_idx)
					if other.relationship_stage >= NPCManager.RelationshipStage.DATING and other.relationship_stage <= NPCManager.RelationshipStage.MARRIED:
						cheating = true
						break
				if cheating:
					npc.exclusivity_core = NPCManager.ExclusivityCore.CHEATING
					npc.affinity *= 0.25
					npc.affinity_equilibrium *= 0.5
					NPCManager.notify_player_advanced_someone_to_dating(-1)
				else:
					npc.exclusivity_core = NPCManager.ExclusivityCore.MONOG
					npc.affinity = min(npc.affinity * 1.5, 100.0)
				_update_affinity_bar()
			_update_exclusivity_label()
			_update_exclusivity_button()

		NPCManager.ExclusivityCore.CHEATING:
			if npc_idx != -1:
				NPCManager.come_clean_from_cheating(npc_idx)
			else:
				npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
				npc.affinity = 1.0
			_update_affinity_bar()
			_update_exclusivity_label()
			_update_exclusivity_button()

		_:
			pass


func _on_next_stage_pressed() -> void:
		next_stage_button.visible = false
		_prepare_next_stage_confirm()
		next_stage_confirm.visible = true

func _prepare_next_stage_confirm() -> void:
		var current_stage: int = npc.relationship_stage
		var current_name: String = STAGE_NAMES[current_stage]
		var next_name: String = STAGE_NAMES[min(current_stage + 1, STAGE_NAMES.size() - 1)]
		next_stage_confirm_label.text = "Transition to %s?" % next_name
		next_stage_confirm_no_button.text = "Stay %s" % current_name
		next_stage_confirm_alt_button.visible = false
		if current_stage == NPCManager.RelationshipStage.DATING:
				if npc.exclusivity_core == NPCManager.ExclusivityCore.POLY:
						next_stage_confirm_label.text = "How do you want to get serious?"
						next_stage_confirm_primary_button.text = "Get Serious, Monogamous"
						next_stage_confirm_alt_button.text = "Get Serious, Polyamorous"
						next_stage_confirm_alt_button.visible = true
				else:
						next_stage_confirm_primary_button.text = "Get Serious"
		elif current_stage == NPCManager.RelationshipStage.SERIOUS:
				next_stage_confirm_primary_button.text = "Propose ($%s)" % NumberFormatter.format_commas(npc.proposal_cost, 0)
		else:
				next_stage_confirm_primary_button.text = "Transition to %s" % next_name

func _advance_to_next_stage() -> void:
		next_stage_confirm.visible = false
		logic.progress_paused = false
		next_stage_button.visible = false
		if npc_idx != -1:
				NPCManager.set_relationship_stage(npc_idx, npc.relationship_stage + 1)
		else:
				npc.relationship_stage += 1
				npc.affinity_equilibrium = float(npc.relationship_stage) * 10.0
		logic.change_state(npc.relationship_stage)
		_update_all()

func _transition_dating_to_serious_monog() -> void:
		next_stage_confirm.visible = false
		logic.progress_paused = false
		next_stage_button.visible = false
		if npc_idx != -1:
				NPCManager.transition_dating_to_serious_monog(npc_idx)
		else:
				npc.relationship_stage = NPCManager.RelationshipStage.SERIOUS
				npc.exclusivity_core = NPCManager.ExclusivityCore.MONOG
				if not npc.claimed_serious_monog_boost:
						npc.affinity += 20.0
						npc.claimed_serious_monog_boost = true
		logic.change_state(npc.relationship_stage)
		_update_all()

func _transition_dating_to_serious_poly() -> void:
		next_stage_confirm.visible = false
		logic.progress_paused = false
		next_stage_button.visible = false
		if npc_idx != -1:
				NPCManager.transition_dating_to_serious_poly(npc_idx)
		else:
				npc.relationship_stage = NPCManager.RelationshipStage.SERIOUS
				npc.exclusivity_core = NPCManager.ExclusivityCore.POLY
				npc.affinity = npc.affinity * 0.1
				npc.affinity_equilibrium = npc.affinity_equilibrium * 0.5
		logic.change_state(npc.relationship_stage)
		_update_all()

func _on_next_stage_confirm_primary_pressed() -> void:
	match npc.relationship_stage:
		NPCManager.RelationshipStage.DATING:
			_transition_dating_to_serious_monog()
		NPCManager.RelationshipStage.SERIOUS:
			if PortfolioManager.attempt_spend(npc.proposal_cost, PortfolioManager.CREDIT_REQUIREMENTS["proposal"]):
				_advance_to_next_stage()
		_:
			_advance_to_next_stage()

func _on_next_stage_confirm_alt_pressed() -> void:
	if npc.relationship_stage == NPCManager.RelationshipStage.DATING:
		_transition_dating_to_serious_poly()

func _on_next_stage_confirm_no_pressed() -> void:
	next_stage_confirm.visible = false
	next_stage_button.visible = true


func _on_gift_pressed() -> void:
	if PortfolioManager.attempt_spend(npc.gift_cost, PortfolioManager.CREDIT_REQUIREMENTS["gift"]):
		npc.affinity = min(npc.affinity + 5.0, 100.0)
		npc.gift_count += 1
		npc.gift_cost = (float(npc.attractiveness) / 10.0) * NPC.BASE_GIFT_COST * pow(2.0, npc.gift_count)
		if npc_idx != -1:
			NPCManager.promote_to_persistent(npc_idx)
			NPCManager.set_npc_field(npc_idx, "affinity", npc.affinity)
			NPCManager.set_npc_field(npc_idx, "gift_count", npc.gift_count)
		_update_affinity_bar()
		_update_action_buttons_text()

func _on_love_pressed() -> void:
	var now: int = TimeManager.get_now_minutes()
	if now < npc.love_cooldown:
			return
	npc.love_cooldown = now + LOVE_COOLDOWN_MINUTES
	logic.apply_love()
	if npc_idx != -1:
		NPCManager.promote_to_persistent(npc_idx)
		NPCManager.set_npc_field(npc_idx, "love_cooldown", npc.love_cooldown)
		NPCManager.set_npc_field(npc_idx, "affinity", npc.affinity)
	_update_affinity_bar()
	_update_love_button()

func _on_date_pressed() -> void:
	if not PortfolioManager.attempt_spend(npc.date_cost, PortfolioManager.CREDIT_REQUIREMENTS["date"]):
		return
	logic.on_date_paid()
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	#if npc.relationship_stage == NPCManager.RelationshipStage.TALKING and npc.relationship_progress < bounds.y - 1.0:
	#	npc.relationship_progress = bounds.y - 1.0
	#	logic.progress_paused = true
	#	next_stage_button.visible = true
	#else:
	var date_progress_boost = npc.date_cost/10
	npc.relationship_progress = min(npc.relationship_progress + date_progress_boost, bounds.y)
	
	if npc.relationship_stage < NPCManager.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
		logic.progress_paused = true
		next_stage_button.visible = true
	_update_relationship_bar()
	_update_breakup_button_text()
	npc.date_cost = (float(npc.attractiveness) / 10.0) * NPC.BASE_DATE_COST * pow(2.0, npc.date_count)
	if npc_idx != -1:
			NPCManager.promote_to_persistent(npc_idx)
			NPCManager.set_npc_field(npc_idx, "relationship_progress", npc.relationship_progress)
			NPCManager.set_npc_field(npc_idx, "date_count", npc.date_count)
	_update_action_buttons_text()




func _on_breakup_pressed() -> void:
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	var fraction: float = (npc.relationship_progress - bounds.x) / (bounds.y - bounds.x)
	var stage_idx: int = max(1, npc.relationship_stage)
	var base: float
	if npc.relationship_stage < NPCManager.RelationshipStage.MARRIED:
		base = pow(10.0, float(stage_idx - 1))
	else:
		var level: int = npc.get_marriage_level()
		base = 10000.0 * pow(1.5, float(level - 1))
	breakup_reward = (0.1 + fraction * 0.9) * base
	var text: String = "Are you sure you want to break up with %s and gain %.2f EX?" % [npc.first_name, breakup_reward]
	if npc.relationship_stage == NPCManager.RelationshipStage.MARRIED:
		text += "\n\n%s will get half of all of your assets" % npc.first_name
	breakup_confirm_label.text = text
	breakup_confirm.visible = true


func _on_breakup_confirm_yes_pressed() -> void:
	breakup_confirm.visible = false
	var current_ex: float = StatManager.get_stat("ex", 0.0)
	StatManager.set_base_stat("ex", current_ex + breakup_reward)
	if npc.relationship_stage == NPCManager.RelationshipStage.MARRIED:
		npc.relationship_stage = NPCManager.RelationshipStage.DIVORCED
		PortfolioManager.halve_assets()
	else:
		npc.relationship_stage = NPCManager.RelationshipStage.EX
	npc.relationship_progress = 0.0
	npc.affinity *= 0.2
	logic.change_state(npc.relationship_stage)
	logic.progress_paused = true
	next_stage_button.visible = false
	gift_button.disabled = true
	date_button.disabled = true
	breakup_button.disabled = true
	npc.emit_signal("player_broke_up")
	if npc_idx != -1:
		NPCManager.promote_to_persistent(npc_idx)
		NPCManager.set_relationship_stage(npc_idx, npc.relationship_stage)
		NPCManager.set_npc_field(npc_idx, "relationship_progress", npc.relationship_progress)
		NPCManager.set_npc_field(npc_idx, "affinity", npc.affinity)
		NPCManager.player_broke_up_with(npc_idx)
	_update_all()

func _on_breakup_confirm_no_pressed() -> void:
	breakup_confirm.visible = false

func _on_apologize_pressed() -> void:
	if npc == null:
		return
	var current_ex: float = StatManager.get_stat("ex", 0.0)
	if current_ex < apologize_cost:
		return
	StatManager.set_base_stat("ex", current_ex - apologize_cost)
	npc.relationship_stage = NPCManager.RelationshipStage.TALKING
	npc.relationship_progress = 0.0
	npc.affinity = 1.0
	logic.progress_paused = false
	logic.change_state(npc.relationship_stage)
	#npc.gift_cost = 25.0
	#npc.date_cost = 200.0
	breakup_reward = 0.0
	apologize_cost = int(ceil(apologize_cost * 1.5))
	next_stage_button.visible = false
	gift_button.disabled = false
	date_button.disabled = false
	breakup_button.disabled = false
	if npc_idx != -1:
		NPCManager.promote_to_persistent(npc_idx)
		NPCManager.set_relationship_stage(npc_idx, npc.relationship_stage)
		NPCManager.set_npc_field(npc_idx, "relationship_progress", npc.relationship_progress)
		NPCManager.set_npc_field(npc_idx, "affinity", npc.affinity)
	_update_all()

func _on_talk_therapy_purchased(level: int) -> void:
	if npc == null:
		return
	if npc.relationship_stage in [NPCManager.RelationshipStage.DIVORCED, NPCManager.RelationshipStage.EX]:
		apologize_button.visible = true
