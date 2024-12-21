extends Node3D

var width: float:
	set(value):
		$Mesh.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(value, 0),
			Vector2(value, 1),
			Vector2(0, 1),
		])

var path: PackedVector3Array:
	set(value):
		$Path3D.curve = Curve3D.new()
		
		for point in value:
			$Path3D.curve.add_point(point)
