extends Pane
class_name SuitorView

const STAGE_NAMES := ["STRANGER", "TALKING", "DATING", "SERIOUS", "ENGAGED", "MARRIED", "DIVORCED", "EX"]

@onready var name_label: Label = %NameLabel
@onready var portrait_view: PortraitView = %Portrait
@onready var relationship_stage_label: Label = %RelationshipStageLabel
@onready var relationship_bar: RelationshipBar = %RelationshipBar
@onready var next_stage_button: Button = %NextStageButton
@onready var affinity_bar: StatProgressBar = %AffinityBar
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
var gift_cost: float = 25.0
var date_cost: float = 200.0
var breakup_reward: float = 0.0
var apologize_cost: int = 10

func setup_custom(data: Dictionary) -> void:
	npc = data.get("npc")
	logic.setup(npc)
	var idx: int = data.get("npc_idx", -1)
	name_label.text = npc.full_name
	portrait_view.portrait_creator_enabled = true
	if idx != -1:
		portrait_view.subject_npc_idx = idx
	if portrait_view.has_method("apply_config") and npc.portrait_config:
		portrait_view.apply_config(npc.portrait_config)
	gift_cost = 25.0
	date_cost = 200.0
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
	
	await get_tree().process_frame
	if Events.has_signal("fumble_talk_therapy_purchased"):
		Events.connect("fumble_talk_therapy_purchased", _on_talk_therapy_purchased)


func _process(delta: float) -> void:
	if npc == null or npc.relationship_stage >= NPC.RelationshipStage.DIVORCED:
		return
	logic.process(delta)
	if npc.relationship_progress >= 100.0 and npc.relationship_stage < NPC.RelationshipStage.MARRIED:
		next_stage_button.visible = true
_update_relationship_bar()
_update_breakup_button_text()

func _update_all() -> void:
	_update_relationship_bar()
	_update_affinity_bar()
	_update_breakup_button_text()
	_update_action_buttons_text()
	var blocked = npc.relationship_stage >= NPC.RelationshipStage.DIVORCED
	gift_button.disabled = blocked
	date_button.disabled = blocked
	apologize_button.visible = UpgradeManager.get_level("fumble_talk_therapy") > 0 and npc.relationship_stage in [NPC.RelationshipStage.DIVORCED, NPC.RelationshipStage.EX]
func _update_relationship_bar() -> void:
	var current_stage: int = npc.relationship_stage
	var label_text: String
	if current_stage in [NPC.RelationshipStage.MARRIED, NPC.RelationshipStage.DIVORCED, NPC.RelationshipStage.EX]:
		label_text = STAGE_NAMES[current_stage]
	else:
		var next_stage: int = current_stage
		if current_stage < NPC.RelationshipStage.MARRIED:
			next_stage = current_stage + 1
		label_text = "%s -> %s" % [STAGE_NAMES[current_stage], STAGE_NAMES[next_stage]]
relationship_stage_label.text = label_text
relationship_bar.max_value = 100
relationship_bar.update_value(npc.relationship_progress)
	relationship_bar.set_mark_fractions(logic.get_stop_marks())

func _update_affinity_bar() -> void:
	affinity_bar.max_value = 100
	affinity_bar.update_value(npc.affinity)

func _update_breakup_button_text() -> void:
	if npc.relationship_stage >= NPC.RelationshipStage.DIVORCED:
			breakup_button.disabled = true
			return
	breakup_button.disabled = false
	var stage_idx = max(1, npc.relationship_stage)
	var base := pow(10, stage_idx - 1)
	var reward := (0.1 + (npc.relationship_progress / 100.0) * 0.9) * base
	breakup_button.text = "Breakup & gain %.2f Ex" % reward

func _update_action_buttons_text() -> void:
	gift_button.text = "Gift ($%s)" % NumberFormatter.format_commas(gift_cost)
	date_button.text = "Date ($%s)" % NumberFormatter.format_commas(date_cost)
	apologize_button.text = "Apologize (%s EX)" % NumberFormatter.format_commas(apologize_cost, 0)

func _on_next_stage_pressed() -> void:
	next_stage_button.visible = false
	logic.progress_paused = false
	if npc.relationship_stage < NPC.RelationshipStage.MARRIED:
			npc.relationship_stage += 1
			npc.relationship_progress = 0.0
	_update_all()

func _on_gift_pressed() -> void:
	if PortfolioManager.attempt_spend(gift_cost):
		npc.affinity = min(npc.affinity + 5.0, 100.0)
		gift_cost *= 2.0
		_update_affinity_bar()
		_update_action_buttons_text()

func _on_date_pressed() -> void:
	if not PortfolioManager.attempt_spend(date_cost):
	        return
	logic.on_date_paid()
	if npc.relationship_stage == NPC.RelationshipStage.TALKING and npc.relationship_progress < 99.0:
	        npc.relationship_progress = 99.0
	        logic.progress_paused = true
	        next_stage_button.visible = true
	else:
	        npc.relationship_progress = min(npc.relationship_progress + 25.0, 100.0)
	        if npc.relationship_progress >= 100.0:
	                logic.progress_paused = true
	                next_stage_button.visible = true
	_update_relationship_bar()
	_update_breakup_button_text()
	date_cost *= 2.0
	_update_action_buttons_text()

func _on_breakup_pressed() -> void:
	var stage_idx = max(1, npc.relationship_stage)
	var base := pow(10, stage_idx - 1)
	breakup_reward = (0.1 + (npc.relationship_progress / 100.0) * 0.9) * base
	var text = "Are you sure you want to break up with %s and gain %.2f EX?" % [npc.first_name, breakup_reward]
	if npc.relationship_stage == NPC.RelationshipStage.MARRIED:
		text += "\n\n%s will get half of all of your assets" % npc.first_name
	breakup_confirm_label.text = text
	breakup_confirm.visible = true

func _on_breakup_confirm_yes_pressed() -> void:
	breakup_confirm.visible = false
	var current_ex = StatManager.get_stat("ex", 0.0)
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
		var current_ex = StatManager.get_stat("ex", 0.0)
		if current_ex < apologize_cost:
			return
		StatManager.set_base_stat("ex", current_ex - apologize_cost)
		npc.relationship_stage = NPC.RelationshipStage.TALKING
		npc.relationship_progress = 0.0
		npc.affinity = 1.0
		logic.progress_paused = false
		#gift_cost = 25.0
		#date_cost = 200.0
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
