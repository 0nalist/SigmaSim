extends Pane
class_name SuitorView

const STAGE_NAMES: Array[String] = ["STRANGER", "TALKING", "DATING", "SERIOUS", "ENGAGED", "MARRIED", "DIVORCED", "EX"]
const LOVE_COOLDOWN_MINUTES: int = 24 * 60

@onready var name_label: Label = %NameLabel
@onready var portrait_view: PortraitView = %Portrait
@onready var relationship_stage_label: Label = %RelationshipStageLabel
@onready var relationship_bar: RelationshipBar = %RelationshipBar
@onready var next_stage_button: Button = %NextStageButton
@onready var affinity_bar: StatProgressBar = %AffinityBar
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

var npc: NPC
var logic: SuitorLogic = SuitorLogic.new()
var breakup_reward: float = 0.0
var apologize_cost: int = 10
var npc_idx: int = -1

func setup_custom(data: Dictionary) -> void:
	npc = data.get("npc")
	logic.setup(npc)
	npc_idx = data.get("npc_idx", -1)
	name_label.text = npc.full_name
	portrait_view.portrait_creator_enabled = true
	if npc_idx != -1:
		portrait_view.subject_npc_idx = npc_idx
	if portrait_view.has_method("apply_config") and npc.portrait_config:
		portrait_view.apply_config(npc.portrait_config)
	breakup_reward = 0.0
	apologize_cost = 10
	_update_all()


func _ready() -> void:
	gift_button.pressed.connect(_on_gift_pressed)
	date_button.pressed.connect(_on_date_pressed)
	breakup_button.pressed.connect(_on_breakup_pressed)
	apologize_button.pressed.connect(_on_apologize_pressed)
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	breakup_confirm_yes_button.pressed.connect(_on_breakup_confirm_yes_pressed)
	breakup_confirm_no_button.pressed.connect(_on_breakup_confirm_no_pressed)
	love_button.pressed.connect(_on_love_pressed)
	
	await get_tree().process_frame
	if Events.has_signal("fumble_talk_therapy_purchased"):
		Events.connect("fumble_talk_therapy_purchased", _on_talk_therapy_purchased)


func _process(delta: float) -> void:
	if npc == null or npc.relationship_stage >= NPC.RelationshipStage.DIVORCED:
		return
	logic.process(delta)
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
		next_stage_button.visible = true
	_update_relationship_bar()
	_update_breakup_button_text()
	_update_love_button()
func _update_all() -> void:
	_update_relationship_bar()
	_update_affinity_bar()
	_update_breakup_button_text()
	_update_action_buttons_text()
	_update_love_button()
	var blocked: bool = npc.relationship_stage >= NPC.RelationshipStage.DIVORCED
	gift_button.disabled = blocked
	date_button.disabled = blocked
	apologize_button.visible = UpgradeManager.get_level("fumble_talk_therapy") > 0 and npc.relationship_stage in [NPC.RelationshipStage.DIVORCED, NPC.RelationshipStage.EX]
func _update_relationship_bar() -> void:
	var current_stage: int = npc.relationship_stage
	if current_stage == NPC.RelationshipStage.MARRIED:
		var level: int = npc.get_marriage_level()
		relationship_stage_label.text = "Level %d Marriage" % level
	elif current_stage in [NPC.RelationshipStage.DIVORCED, NPC.RelationshipStage.EX]:
		relationship_stage_label.text = STAGE_NAMES[current_stage]
	else:
		var next_stage: int = current_stage + 1
		relationship_stage_label.text = "%s -> %s" % [STAGE_NAMES[current_stage], STAGE_NAMES[next_stage]]
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(current_stage, npc.relationship_progress)
	relationship_bar.max_value = bounds.y - bounds.x
	relationship_bar.update_value(npc.relationship_progress - bounds.x)
	if current_stage < NPC.RelationshipStage.MARRIED:
		relationship_bar.set_mark_fractions(logic.get_stop_marks())
	else:
		relationship_bar.set_mark_fractions([])
func _update_affinity_bar() -> void:
	affinity_bar.max_value = 100
	affinity_bar.update_value(npc.affinity)

func _update_breakup_button_text() -> void:
	if npc.relationship_stage >= NPC.RelationshipStage.DIVORCED:
		breakup_button.disabled = true
		return
	breakup_button.disabled = false
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	var fraction: float = (npc.relationship_progress - bounds.x) / (bounds.y - bounds.x)
	var stage_idx: int = max(1, npc.relationship_stage)
	var base: float
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED:
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
	if npc.relationship_stage < NPC.RelationshipStage.DATING:
		love_button.visible = false
		love_cooldown_label.visible = false
		return
	love_button.visible = true
	var now: int = TimeManager.get_now_minutes()
	var remaining: int = npc.love_cooldown + LOVE_COOLDOWN_MINUTES - now
	if remaining > 0:
		love_button.disabled = true
		var hours: int = remaining / 60
		var minutes: int = remaining % 60
		love_cooldown_label.visible = true
		love_cooldown_label.text = "Love in %dh %dm" % [hours, minutes]
	else:
		love_button.disabled = false
		love_cooldown_label.visible = false
func _on_next_stage_pressed() -> void:
	next_stage_button.visible = false
	logic.progress_paused = false
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED:
		npc.relationship_stage += 1
	_update_all()
func _on_gift_pressed() -> void:
	if PortfolioManager.attempt_spend(npc.gift_cost):
		npc.affinity = min(npc.affinity + 5.0, 100.0)
		npc.gift_cost *= 2.0
		if npc_idx != -1:
			NPCManager.promote_to_persistent(npc_idx)
			NPCManager.set_npc_field(npc_idx, "gift_cost", npc.gift_cost)
		_update_affinity_bar()
		_update_action_buttons_text()

func _on_love_pressed() -> void:
	var now: int = TimeManager.get_now_minutes()
	if now - npc.love_cooldown < LOVE_COOLDOWN_MINUTES:
		return
	npc.love_cooldown = now
	logic.apply_love()
	if npc_idx != -1:
		NPCManager.promote_to_persistent(npc_idx)
		NPCManager.set_npc_field(npc_idx, "love_cooldown", npc.love_cooldown)
		NPCManager.set_npc_field(npc_idx, "affinity", npc.affinity)
		NPCManager.set_npc_field(npc_idx, "relationship_progress", npc.relationship_progress)
	_update_affinity_bar()
	_update_relationship_bar()
	_update_breakup_button_text()
	_update_love_button()

func _on_date_pressed() -> void:
	if not PortfolioManager.attempt_spend(npc.date_cost):
		return
	logic.on_date_paid()
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	if npc.relationship_stage == NPC.RelationshipStage.TALKING and npc.relationship_progress < bounds.y - 1.0:
		npc.relationship_progress = bounds.y - 1.0
		logic.progress_paused = true
		next_stage_button.visible = true
	else:
		npc.relationship_progress = min(npc.relationship_progress + 25.0, bounds.y)
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED and npc.relationship_progress >= bounds.y:
		logic.progress_paused = true
		next_stage_button.visible = true
	_update_relationship_bar()
	_update_breakup_button_text()
	npc.date_cost *= 2.0
	if npc_idx != -1:
		NPCManager.promote_to_persistent(npc_idx)
		NPCManager.set_npc_field(npc_idx, "date_cost", npc.date_cost)
	_update_action_buttons_text()
func _on_breakup_pressed() -> void:
	var bounds: Vector2 = SuitorLogic.get_stage_bounds(npc.relationship_stage, npc.relationship_progress)
	var fraction: float = (npc.relationship_progress - bounds.x) / (bounds.y - bounds.x)
	var stage_idx: int = max(1, npc.relationship_stage)
	var base: float
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED:
		base = pow(10.0, float(stage_idx - 1))
	else:
		var level: int = npc.get_marriage_level()
		base = 10000.0 * pow(1.5, float(level - 1))
	breakup_reward = (0.1 + fraction * 0.9) * base
	var text: String = "Are you sure you want to break up with %s and gain %.2f EX?" % [npc.first_name, breakup_reward]
	if npc.relationship_stage == NPC.RelationshipStage.MARRIED:
		text += "\n\n%s will get half of all of your assets" % npc.first_name
	breakup_confirm_label.text = text
	breakup_confirm.visible = true
func _on_breakup_confirm_yes_pressed() -> void:
	breakup_confirm.visible = false
	var current_ex: float = StatManager.get_stat("ex", 0.0)
	StatManager.set_base_stat("ex", current_ex + breakup_reward)
	if npc.relationship_stage == NPC.RelationshipStage.MARRIED:
		npc.relationship_stage = NPC.RelationshipStage.DIVORCED
		PortfolioManager.halve_assets()
	else:
		npc.relationship_stage = NPC.RelationshipStage.EX
	npc.relationship_progress = 0.0
	npc.affinity *= 0.2
	logic.progress_paused = true
	next_stage_button.visible = false
	gift_button.disabled = true
	date_button.disabled = true
	breakup_button.disabled = true
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
	npc.relationship_stage = NPC.RelationshipStage.TALKING
	npc.relationship_progress = 0.0
	npc.affinity = 1.0
	logic.progress_paused = false
	#npc.gift_cost = 25.0
	#npc.date_cost = 200.0
	breakup_reward = 0.0
	apologize_cost = int(ceil(apologize_cost * 1.5))
	next_stage_button.visible = false
	gift_button.disabled = false
	date_button.disabled = false
	breakup_button.disabled = false
	_update_all()

func _on_talk_therapy_purchased(level: int) -> void:
	if npc == null:
		return
	if npc.relationship_stage in [NPC.RelationshipStage.DIVORCED, NPC.RelationshipStage.EX]:
		apologize_button.visible = true
