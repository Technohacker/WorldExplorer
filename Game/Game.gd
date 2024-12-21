extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	var end_coord = start_coord + Vector2(0.01, 0.01)

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

	var tile = MapBuilder.prepare_tile_for_osmjson(osmjson, start_coord)

	self.add_child(tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
