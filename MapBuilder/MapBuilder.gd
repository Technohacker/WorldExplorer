extends Node

const Building = preload("res://MapBuilder/Building/Building.tscn")
const Road = preload("res://MapBuilder/Road/Road.tscn")

func prepare_tile_for_osmjson(root: Node3D, json: String, gps_coords: Vector2):
	var parsed = JSON.parse_string(json)
	if parsed == null:
		print(json)
		return

	var node_cache = {}

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

				node_cache[element_id] = {
					"pos": coords_to_meters(rel_coords),
				}

			"way":
				await get_tree().process_frame
				var way_nodes: Array = element["nodes"]

				var entity: Node3D
				if element_tags.get("building") != null:
					# Building
					entity = build_building(node_cache, way_nodes, element_tags)
				elif element_tags.get("highway") != null:
					# Road
					entity = build_road(node_cache, way_nodes, element_tags)

				entity.name = str(element_id)
				root.add_child(entity)

			_:
				push_warning("Unknown element?", element)

func build_building(node_cache: Dictionary, way_nodes: Array, tags: Dictionary) -> Node3D:
	var footprint = PackedVector2Array()

	for id in way_nodes:
		var node = node_cache.get(id)
		if node != null:
			var pos: Vector3 = node["pos"]
			footprint.push_back(Vector2(pos.x, pos.z))

	if footprint.size() < 3:
		return Node3D.new()

	var building_pos = footprint[0]
	for i in range(footprint.size()):
		footprint[i] -= building_pos

	# Default 1 floor (3 meters)
	var height: float = 3

	if tags.has("height"):
		# Explicit height in meters
		height = float(tags["height"])
	elif tags.has("building:levels"):
		# Height in floors
		height = 3.0 * float(tags["building:levels"])

	var building = Building.instantiate()
	building.position = Vector3(building_pos.x, 0, building_pos.y)
	building.footprint = footprint
	building.height = height

	return building

func build_road(node_cache: Dictionary, way_nodes: Array, tags: Dictionary) -> Node3D:
	var road_type: String = tags["highway"]
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
		return Node3D.new()

	var road_path = PackedVector3Array()
	# Loop over the points
	for segment_id in way_nodes:
		var node = node_cache.get(segment_id)
		if node == null:
			continue

		road_path.push_back(node["pos"])

	if road_path.size() < 2:
		#print(element_tags)
		return Node3D.new()

	var road_pos = road_path[0]
	for i in range(road_path.size()):
		road_path[i] -= road_pos

	# Default 1 lane
	var width = 4
	if tags.has("width"):
		width = float(tags["width"])
	elif tags.has("lanes"):
		width = 4 * int(tags["lanes"])

	var road = Road.instantiate()
	road.position = road_pos
	road.width = width
	road.path = road_path

	return road

# Lat, Lon = y, x
func coords_to_meters(coords: Vector2) -> Vector3:
	return Vector3(
		coords.y * 110574,
		0,
		coords.x * 111320 * cos(coords.y),
	)
