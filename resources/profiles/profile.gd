@icon("res://assets/silhouette.png") 
extends Resource
class_name Profile

# === Basic Info ===
@export var full_name: String
@export var username: String
@export var profile_pic: Texture2D
@export_multiline var bio: String
@export var occupation: String
@export var relationship_status: String = "Single" # or enum?

# === Stats ===
@export var affinity: float = 0.0 # 0-100

# Greek Stats (0–100 scale, or float if needed)
@export_range(0, 100, 0.1) var alpha: float = 0.0
@export_range(0, 100, 0.1) var beta: float = 0.0
@export_range(0, 100, 0.1) var gamma: float = 0.0
@export_range(0, 100, 0.1) var delta: float = 0.0
@export_range(0, 100, 0.1) var omega: float = 0.0
@export_range(0, 100, 0.1) var sigma: float = 0.0

# === Wall Posts === (optional)
@export var wall_posts: Array[String] = []

# === Dialog Reference ===
#@export var starting_dialog: DialogComponent

# === Tags / Attributes ===
@export var tags: Array[String] = [] # e.g. ["flirtable", "boss", "rival"]
