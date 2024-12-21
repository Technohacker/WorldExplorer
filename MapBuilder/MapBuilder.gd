extends Node

func prepare_tile_for_osmjson(json: String, gps_coords: Vector2) -> Node3D:
	var root = Node3D.new()
	var parsed = JSON.parse_string(json)
	if parsed == null:
		print(json)
		return root

	var nodes = {}

	for element in parsed["elements"]:
		var element_id = element["id"]
		var element_tags: Dictionary = element.get("tags", {})

		match element["type"]:
			"node":
				var coords = Vector2(
					element["lon"],
					element["lat"]
				)
				var rel_coords = coords - gps_coords

				nodes[element_id] = {
					"pos": coords_to_meters(rel_coords),
				}

			"way":
				var way_nodes: Array = element["nodes"]

				if element_tags.get("building") != null:
					# Building
					var footprint = PackedVector2Array()

					for id in way_nodes:
						var node = nodes.get(id)
						if node != null:
							var pos: Vector3 = node["pos"]
							footprint.push_back(Vector2(pos.x, pos.z))

					# Default 1 floor (3 meters)
					var height: float = 3

					if element_tags.has("height"):
						# Explicit height in meters
						height = float(element_tags["height"])
					elif element_tags.has("building:levels"):
						# Height in floors
						height = 3.0 * float(element_tags["building:levels"])

					root.add_child(build_building(footprint, height))

				elif element_tags.get("highway") != null:
					# Road
					var road_type: String = element_tags["highway"]
					const ACTUAL_ROADS = [
						"motorway",
						"trunk",
						"primary",
						"secondary",
						"tertiary",
						"unclassified",
						"residential",

						"motorway_link",
						"trunk_link",
						"primary_link",
						"secondary_link",
						"tertiary_link",

						"living_street",
						"service",
						"pedestrian",
						"track",
						"bus_guideway",
						"escape",
						"raceway",
						"road",
						"busway",
						
						"footway",
						"bridleway",
						"path",
						
						"cycleway",
					]
					if road_type not in ACTUAL_ROADS:
						#print(element_tags)
						continue

					# Default 1 lane
					var width = 4
					if element_tags.has("width"):
						width = float(element_tags["width"])
					elif element_tags.has("lanes"):
						width = 4 * int(element_tags["lanes"])

					var road_path = PackedVector3Array()
					# Loop over the points
					for segment_id in way_nodes:
						var node = nodes.get(segment_id)
						if node == null:
							continue

						road_path.push_back(node["pos"])
					root.add_child(build_road(road_path, width))

			_:
				print(element)

	return root

func build_building(footprint: PackedVector2Array, height: float) -> Node3D:
	var building = Node3D.new()
	
	if footprint.is_empty():
		return building

	var pos_2d = footprint[0]
	
	for i in range(footprint.size()):
		footprint[i] -= pos_2d
		pass

	building.position = Vector3(pos_2d.x, 0, pos_2d.y)

	# Create the Mesh
	var mesh = CSGPolygon3D.new()

	mesh.polygon = footprint
	mesh.depth = height
	mesh.rotation.x = deg_to_rad(90)
	
	building.add_child(mesh)

	return building

func build_road(path: PackedVector3Array, width: float) -> Node3D:
	var road = Node3D.new()
	
	if path.is_empty():
		return road

	var path_node = Path3D.new()
	path_node.curve = Curve3D.new()

	var path_start = path[0]
	for point in path:
		path_node.curve.add_point(point - path_start)

	road.position = path_start
	road.add_child(path_node)

	var mesh = CSGPolygon3D.new()
	road.add_child(mesh)

	mesh.mode = CSGPolygon3D.MODE_PATH
	mesh.path_local = true
	mesh.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(width, 0),
		Vector2(width, 1),
		Vector2(0, 1),
	])
	mesh.path_node = mesh.get_path_to(path_node)

	#var mesh = PlaneMesh.new()
	#mesh.center_offset = Vector3(0, 0, -length / 2)
	#mesh.size = Vector2(width, length)
	#mesh.material = StandardMaterial3D.new()
	#(mesh.material as StandardMaterial3D).albedo_color = Color(randf(), randf(), randf())

	#var road = MeshInstance3D.new()
	#road.add_child(CSGSphere3D.new())
	#road.look_at_from_position(start_pos, end_pos)
	#road.mesh = mesh

	return road

# Lat, Lon = y, x
func coords_to_meters(coords: Vector2) -> Vector3:
	return Vector3(
		coords.y * 110574,
		0,
		coords.x * 111320 * cos(coords.y),
	)
