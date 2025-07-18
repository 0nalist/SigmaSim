@tool
extends EditorScript

# Config: Set these paths
const FIRST_NAMES_CSV := "res://data/NamesGenerator - First Names.csv"
const LAST_NAMES_CSV  := "res://data/NamesGenerator - Last Names.csv"
const FIRST_NAMES_JSON := "res://data/first_names.json"
const LAST_NAMES_JSON  := "res://data/last_names.json"

func _run():
	parse_first_names(FIRST_NAMES_CSV, FIRST_NAMES_JSON)
	parse_last_names(LAST_NAMES_CSV, LAST_NAMES_JSON)
	print("CSV->JSON export complete!")

func parse_first_names(csv_path: String, json_path: String) -> void:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		printerr("Failed to open: ", csv_path)
		return
	var lines = []
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()
	if lines.size() < 2:
		printerr("No data in first names CSV!")
		return
	var header = lines[0].split(",")
	var out = []
	for i in range(1, lines.size()):
		var row = lines[i].split(",")
		if row.size() < 4:
			continue
		out.append({
			"name": row[0].strip_edges(),
			"femininity": float(row[1]),
			"masculinity": float(row[2]),
			"nonbinaryness": float(row[3])
		})
	var f = FileAccess.open(json_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	print("Exported: ", json_path)

func parse_last_names(csv_path: String, json_path: String) -> void:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		printerr("Failed to open: ", csv_path)
		return
	var lines = []
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()
	if lines.size() < 2:
		printerr("No data in last names CSV!")
		return
	var out = []
	for i in range(1, lines.size()):
		var name = lines[i].strip_edges()
		if name != "":
			out.append(name)
	var f = FileAccess.open(json_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	print("Exported: ", json_path)
