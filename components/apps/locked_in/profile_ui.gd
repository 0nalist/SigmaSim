extends Panel

@onready var profile_pic: TextureRect = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var username_button: Button = %UsernameButton
@onready var affinity_progress_bar: ProgressBar = %AffinityProgressBar
@onready var work_label: Label = %WorkLabel
@onready var relationship_label: Label = %RelationshipLabel
@onready var wall_v_box_container: VBoxContainer = %WallVBoxContainer
@onready var greek_stats_ui: Control = %GreekStatsUI

func load_profile(profile: Profile) -> void:
	profile_pic.texture = profile.profile_pic
	name_label.text = profile.full_name
	username_button.text = "@" + profile.username
	work_label.text = profile.occupation
	relationship_label.text = profile.relationship_status
	affinity_progress_bar.value = profile.affinity
	
	var greek = greek_stats_ui
	greek.alpha_progress_bar.value = profile.alpha
	greek.beta_progress_bar.value = profile.beta
	greek.gamma_progress_bar.value = profile.gamma
	greek.delta_progress_bar.value = profile.delta
	greek.omega_progress_bar.value = profile.omega
	greek.sigma_progress_bar.value = profile.sigma
	
	# Clear and populate wall posts
	wall_v_box_container.clear()
	for post in profile.wall_posts:
		var label = Label.new()
		label.text = post
		wall_v_box_container.add_child(label)
