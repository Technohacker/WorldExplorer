extends Node3D

var footprint: PackedVector2Array:
	set(value):
		$Mesh.polygon = value

var height: float:
	set(value):
		$Mesh.depth = value
