class_name GenderedFirstName
extends Resource

var name: String
var gender_vector: Vector3  # x: femme, y: masc, z: ungendered

func _init(_name: String = "", _vector: Vector3 = Vector3(0, 0, 1)):
	name = _name
	gender_vector = _vector
