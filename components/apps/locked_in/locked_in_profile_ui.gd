class_name LockedInProfileUI
extends PanelContainer

@onready var profile_pic: PortraitView = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var username_button: Button = %UsernameButton
@onready var affinity_progress_bar: ProgressBar = %AffinityProgressBar
@onready var work_label: Label = %WorkLabel
@onready var relationship_label: Label = %RelationshipLabel
@onready var greek_stats_ui: Control = %GreekStatsUI
@onready var bio_label: Label = %BioLabel
@onready var wall_ui: LockedInWallUI = %LockedInWallUI

func load_npc(npc: NPC) -> void:
	if npc.portrait_config != null:
		profile_pic.apply_config(npc.portrait_config)
	elif npc.profile_pic is Texture2D:
		var face: TextureRect = profile_pic.get_node("face")
		face.texture = npc.profile_pic
	name_label.text = npc.full_name
	username_button.text = "@" + npc.username
	work_label.text = npc.occupation
	relationship_label.text = npc.relationship_status
	affinity_progress_bar.value = npc.affinity

	var greek = greek_stats_ui
	greek.alpha_progress_bar.value = npc.alpha
	greek.beta_progress_bar.value = npc.beta
	greek.gamma_progress_bar.value = npc.gamma
	greek.delta_progress_bar.value = npc.delta
	greek.omega_progress_bar.value = npc.omega
	greek.sigma_progress_bar.value = npc.sigma

	bio_label.text = npc.fumble_bio
	wall_ui.set_posts(npc.wall_posts)
