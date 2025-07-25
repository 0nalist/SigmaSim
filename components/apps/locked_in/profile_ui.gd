# profile_ui.gd
extends PanelContainer

@onready var profile_pic: TextureRect = %ProfilePic
@onready var name_label: Label = %NameLabel
@onready var username_button: Button = %UsernameButton
@onready var affinity_progress_bar: ProgressBar = %AffinityProgressBar
@onready var work_label: Label = %WorkLabel
@onready var relationship_label: Label = %RelationshipLabel
@onready var wall_v_box_container: VBoxContainer = %WallVBoxContainer
@onready var greek_stats_ui: Control = %GreekStatsUI

@onready var bio_label: Label = %BioLabel


func _ready() -> void:
	dump_player_data_in_bio()
	update_name_label()
	update_work_label()
	update_prof_pic()


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

func update_prof_pic():
	pass
	#profile_pic.texture = PlayerManager.user_data["profile_picture_path"]
	## Invalid assignment of property or key 'texture' with value of type 'String' on a base object of type 'TextureRect'.

func update_name_label():
	var pname = PlayerManager.user_data["name"]
	name_label.text = pname
	relationship_label.text = pname + " is terminally single"
	
	username_button.text = "@" + PlayerManager.user_data["username"]

func update_work_label():
	if randi_range(0,1) > 0:
		work_label.text = PlayerManager.user_data["name"] + " woke up this morning and chose violence"
	else:
		work_label.text = PlayerManager.user_data["name"] + " is creating lifelong b2b partnerships"

func dump_player_data_in_bio():
	var bio_text := ""
	for key in PlayerManager.user_data.keys():
		var value = PlayerManager.user_data[key]
		if value is Array:
			value = "[" + ", ".join(value) + "]"
		elif value is Dictionary:
			value = JSON.stringify(value)
		bio_text += "%s: %s\n" % [key.capitalize().replace("_", " "), str(value)]
	
	bio_label.text = bio_text.strip_edges()
