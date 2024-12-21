extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	const QUERY_FORMAT: String = "
		[out:json];
		(
		  node({bounding_box});

		  way({bounding_box})[highway];
		  way({bounding_box})[building];
		);
		out;
	"

	var http = HTTPRequest.new()
	add_child(http)

	# Long, Lat
	var start_coord = Vector2(-74.01264, 40.72619)
	var end_coord = start_coord + Vector2(0.04, 0.04)

	http.request(
		"https://overpass-api.de/api/interpreter",
		PackedStringArray(),
		HTTPClient.METHOD_POST,
		"data=" + QUERY_FORMAT.format({
			"bounding_box": "%f, %f, %f, %f" % [start_coord.y, start_coord.x, end_coord.y, end_coord.x]
		}).dedent().uri_encode()
	)
	print("Request sent")
	
	var res = await http.request_completed
	var osmjson: String = res[3].get_string_from_utf8()
	print("Response received")

	await MapBuilder.prepare_tile_for_osmjson($Tile, osmjson, start_coord)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera: Node3D = $Vehicle/Focus

		var rot = camera.rotation
		rot.y -= deg_to_rad(event.relative.x * 0.1)
		rot.x -= deg_to_rad(event.relative.y * 0.1)

		camera.set_rotation(rot)
