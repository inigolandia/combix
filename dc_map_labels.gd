extends Node3D

# Supplemental world-space labels for the procedural DC blockout.
# Coordinates mirror dc_map_runtime.gd's _geo_pos() and named geometry anchors.
const ORIGIN_LAT := 38.8899
const ORIGIN_LON := -77.0091
const METERS_PER_DEG_LAT := 111320.0
const METERS_PER_DEG_LON := 98200.0

const LABEL_COLOR := Color("#f6f0d8")
const LANDMARK_COLOR := Color("#3d3a35")
const WATER_COLOR := Color("#e7f5f2")
const GREEN_COLOR := Color("#35563d")
const MAX_SCENE_WAIT_FRAMES := 240
const OVERLAY_LAYER := 50
const OVERLAY_FONT_SIZE := 18
const OVERLAY_OUTLINE_SIZE := 5
const OVERLAY_ANCHOR_OFFSET := 10.0
const SIDEWALK_MARKER_COLOR := Color("#ffe36e")
const SIDEWALK_MARKER_FONT_SIZE := 16
const SIDEWALK_MARKER_OUTLINE_SIZE := 4
# The sidewalk source uses an explicit 4.0 m strip width; keep this marker
# clearance metric and convert it through the canonical 45.0 m/unit source.
const SIDEWALK_MARKER_OFFSET_M := 4.0

var _overlay_layer: CanvasLayer
var _overlay_root: Control
var _overlay_entries: Array[Dictionary] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# The autoload coordinates the build, but the rendered root must belong to
	# the active scene so it uses that scene's World3D.
	call_deferred("_wait_for_scene_and_build")

func _wait_for_scene_and_build() -> void:
	var scene: Node3D = null
	for _attempt in range(MAX_SCENE_WAIT_FRAMES):
		scene = get_tree().current_scene as Node3D
		if scene != null and scene.is_inside_tree():
			# Let the current scene finish its synchronous procedural _ready().
			await get_tree().process_frame
			_build_missing_labels(scene)
			return
		await get_tree().process_frame

	# Explicit fallback: do not silently abandon the build if current_scene was
	# assigned late. Prefer current_scene, then a Node3D scene root in /root.
	scene = get_tree().current_scene as Node3D
	if scene == null:
		for candidate in get_tree().root.get_children():
			var candidate_3d := candidate as Node3D
			if candidate_3d != null and candidate_3d != self:
				scene = candidate_3d
				break
	if scene != null:
		_build_missing_labels(scene)

func _geo_pos(latitude: float, longitude: float) -> Vector3:
	return Vector3(WorldScale.meters_to_units((longitude - ORIGIN_LON) * METERS_PER_DEG_LON), 0.0, WorldScale.meters_to_units(-(latitude - ORIGIN_LAT) * METERS_PER_DEG_LAT))

func _build_missing_labels(scene: Node) -> void:
	var world_root := scene as Node3D
	if world_root == null:
		return

	# The autoload is only the coordinator. The actual Label3D root is reparented
	# into the current scene so it renders in that scene's World3D.
	var scene_labels := world_root.get_node_or_null("SupplementalMapLabels") as Node3D
	var autoload_labels := get_node_or_null("SupplementalMapLabels") as Node3D
	if scene_labels == null:
		if autoload_labels != null:
			remove_child(autoload_labels)
			scene_labels = autoload_labels
		else:
			scene_labels = Node3D.new()
		scene_labels.name = "SupplementalMapLabels"
		world_root.add_child(scene_labels)
	elif scene_labels.get_parent() != world_root:
		scene_labels.reparent(world_root, false)

	# Any coordinator-side staging root is drained and released only after its
	# children are safely under the scene-owned root.
	if autoload_labels != null and autoload_labels != scene_labels:
		while autoload_labels.get_child_count() > 0:
			var child := autoload_labels.get_child(0)
			autoload_labels.remove_child(child)
			scene_labels.add_child(child)
		autoload_labels.queue_free()

	# Every position below is derived from dc_map_runtime.gd's _geo_pos(), road
	# endpoints, procedural grid ranges, named meshes, or bridge loop anchors.
	var capitol := _geo_pos(38.8899, -77.0091)
	var loc := _geo_pos(38.8887, -77.0047)
	var union_station := _geo_pos(38.8971, -77.0064)
	var white_house := _geo_pos(38.8977, -77.0365)
	var washington_monument := _geo_pos(38.8895, -77.0353)
	var lincoln := _geo_pos(38.8893, -77.0502)
	var jefferson := _geo_pos(38.8814, -77.0365)
	var smithsonian := _geo_pos(38.8882, -77.0282)
	var archives := _geo_pos(38.8923, -77.0261)
	var grid_center := Vector3((-4200.0 + 800.0) * 0.5, 3.0, (-900.0 + 1200.0) * 0.5)

	var required_labels: Array[Dictionary] = [
		{"text": "Pennsylvania Avenue", "pos": (capitol + white_house) * 0.5 + Vector3(0, 3.0, 0), "color": LABEL_COLOR},
		{"text": "Constitution Avenue", "pos": (_geo_pos(38.8920, -77.0091) + _geo_pos(38.8920, -77.0500)) * 0.5 + Vector3(0, 3.0, 0), "color": LABEL_COLOR},
		{"text": "Independence Avenue", "pos": (_geo_pos(38.8870, -77.0091) + _geo_pos(38.8870, -77.0500)) * 0.5 + Vector3(0, 3.0, 0), "color": LABEL_COLOR},
		{"text": "Massachusetts Avenue", "pos": (union_station + _geo_pos(38.9050, -77.0500)) * 0.5 + Vector3(0, 3.0, 0), "color": LABEL_COLOR},
		{"text": "rede de ruas", "pos": grid_center, "color": LABEL_COLOR},
		{"text": "passeios", "pos": Vector3(-1750.0, 3.0, 105.5), "color": LABEL_COLOR},
		{"text": "passadeiras", "pos": Vector3(-2200.0, 3.0, -500.0), "color": LABEL_COLOR},
		{"text": "marcações rodoviárias", "pos": Vector3(-4000.0, 3.0, 120.0), "color": LABEL_COLOR},
		{"text": "quarteirões/edifícios", "pos": Vector3(-4200.0, 12.0, -900.0), "color": LABEL_COLOR},
		{"text": "pontes sobre o Potomac", "pos": Vector3(-4510.0, 4.0, 0.0), "color": WATER_COLOR},
		{"text": "pontes sobre o Anacostia", "pos": Vector3(4070.0, 4.0, 0.0), "color": WATER_COLOR},
		{"text": "Potomac", "pos": Vector3(-5100.0, 3.0, 500.0), "color": WATER_COLOR},
		{"text": "Anacostia", "pos": Vector3(4500.0, 3.0, 500.0), "color": WATER_COLOR},
		{"text": "National Mall", "pos": Vector3(-2100.0, 3.0, 35.0), "color": GREEN_COLOR},
		{"text": "Mall Reflecting Pool", "pos": Vector3(-3300.0, 3.0, 56.0), "color": WATER_COLOR},
		{"text": "White House Lawn", "pos": white_house + Vector3(0, 4.0, 90), "color": GREEN_COLOR},
		{"text": "US Capitol", "pos": capitol + Vector3(0, 45.0, 0), "color": LANDMARK_COLOR},
		{"text": "Library of Congress", "pos": loc + Vector3(0, 34.0, 0), "color": LANDMARK_COLOR},
		{"text": "Union Station", "pos": union_station + Vector3(0, 38.0, 0), "color": LANDMARK_COLOR},
		{"text": "White House", "pos": white_house + Vector3(0, 20.0, 0), "color": LANDMARK_COLOR},
		{"text": "Washington Monument", "pos": washington_monument + Vector3(0, 185.0, 0), "color": LANDMARK_COLOR},
		{"text": "Lincoln Memorial", "pos": lincoln + Vector3(0, 42.0, 0), "color": LANDMARK_COLOR},
		{"text": "Jefferson Memorial", "pos": jefferson + Vector3(0, 57.0, 0), "color": LANDMARK_COLOR},
		{"text": "Smithsonian Castle", "pos": smithsonian + Vector3(0, 28.0, 0), "color": LANDMARK_COLOR},
		{"text": "National Archives", "pos": archives + Vector3(0, 32.0, 0), "color": LANDMARK_COLOR}
	]
	for item in required_labels:
		_ensure_label(world_root, scene_labels, String(item["text"]), item["pos"] as Vector3, item["color"] as Color)
	_build_screen_overlay(required_labels, world_root)

func _ensure_label(world_root: Node3D, label_root: Node3D, required_text: String, world_position: Vector3, color: Color) -> void:
	var key := _label_key(required_text)
	var matches: Array[Label3D] = []
	for node in world_root.find_children("*", "Label3D", true, false):
		var candidate := node as Label3D
		if candidate != null and _matches_required(candidate.text, key):
			matches.append(candidate)

	var label: Label3D
	if matches.is_empty():
		label = Label3D.new()
		label.name = "MapLabel_" + required_text.replace(" ", "_").replace("/", "_")
		label_root.add_child(label)
	else:
		label = matches[0]
		if label.get_parent() != label_root:
			label.reparent(label_root, false)
		for duplicate_index in range(1, matches.size()):
			matches[duplicate_index].queue_free()

	# Normalize old runtime labels (including dimension suffixes) to the exact
	# required name, then apply one shared, readable billboard style.
	label.text = required_text
	label.position = world_position
	label.font_size = 28
	label.outline_size = 7
	label.outline_modulate = Color("#172027e6")
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.004
	label.scale = Vector3.ONE
	# The screen-space overlay is the single reliable visible path.
	label.visible = false

func _build_screen_overlay(required_labels: Array[Dictionary], world_root: Node3D) -> void:
	if is_instance_valid(_overlay_layer):
		_overlay_layer.queue_free()
	_overlay_entries.clear()

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "MapLabelOverlay"
	_overlay_layer.layer = OVERLAY_LAYER
	add_child(_overlay_layer)

	_overlay_root = Control.new()
	_overlay_root.name = "FullRectWorldAnchoredLabels"
	_overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_overlay_root)

	for item in required_labels:
		var entry: Dictionary = item.duplicate()
		var label := Label.new()
		label.name = "OverlayLabel_" + _label_key(String(item["text"])).replace(" ", "_").replace("/", "_")
		label.text = String(item["text"])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", OVERLAY_FONT_SIZE)
		var text_color: Color = item["color"] as Color
		if text_color.get_luminance() < 0.45:
			text_color = Color("#fff3c4")
		label.add_theme_color_override("font_color", text_color)
		label.add_theme_color_override("font_outline_color", Color("#172027f2"))
		label.add_theme_constant_override("outline_size", OVERLAY_OUTLINE_SIZE)
		label.size = label.get_combined_minimum_size()
		label.visible = false
		_overlay_root.add_child(label)
		entry["control"] = label
		_overlay_entries.append(entry)

	_append_sidewalk_markers(world_root)
	_update_screen_overlay()

func _append_sidewalk_markers(world_root: Node3D) -> void:
	# Discover the actual procedural sidewalk MeshInstance3D nodes after the map is built.
	# Their world positions come from each mesh AABB, never from guessed map coordinates.
	var seen_segments: Dictionary = {}
	var marker_index := 0
	for candidate in world_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		if mesh == null or not _is_sidewalk_mesh(mesh):
			continue

		var local_aabb: AABB = mesh.get_aabb()
		var center_world: Vector3 = mesh.global_transform * local_aabb.get_center()
		var dedupe_key := "%s|%.3f|%.3f|%.3f" % [mesh.get_instance_id(), center_world.x, center_world.y, center_world.z]
		if seen_segments.has(dedupe_key):
			continue
		seen_segments[dedupe_key] = true

		var top_local := Vector3(local_aabb.get_center().x, local_aabb.position.y + local_aabb.size.y, local_aabb.get_center().z)
		var marker_world: Vector3 = mesh.global_transform * top_local
		marker_world.y += WorldScale.meters_to_units(SIDEWALK_MARKER_OFFSET_M)

		var label := Label.new()
		label.name = "OverlaySidewalkMarker_%d" % marker_index
		label.text = "1"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", SIDEWALK_MARKER_FONT_SIZE)
		label.add_theme_color_override("font_color", SIDEWALK_MARKER_COLOR)
		label.add_theme_color_override("font_outline_color", Color("#172027f2"))
		label.add_theme_constant_override("outline_size", SIDEWALK_MARKER_OUTLINE_SIZE)
		label.size = label.get_combined_minimum_size()
		label.visible = false
		_overlay_root.add_child(label)
		_overlay_entries.append({"text": "1", "pos": marker_world, "color": SIDEWALK_MARKER_COLOR, "control": label})
		marker_index += 1

func _is_sidewalk_mesh(mesh: MeshInstance3D) -> bool:
	var node_name := mesh.name.to_lower()
	var surface_type := String(mesh.get_meta("surface_type", "")).to_lower()
	var surface := String(mesh.get_meta("surface", "")).to_lower()
	return node_name.contains("sidewalk") or surface_type == "sidewalk" or surface == "sidewalk"

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_screen_overlay()

func _update_screen_overlay() -> void:
	if not is_instance_valid(_overlay_root):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		for entry in _overlay_entries:
			(entry["control"] as Label).visible = false
		return

	var viewport_size := get_viewport().get_visible_rect().size
	for entry in _overlay_entries:
		var label := entry["control"] as Label
		var anchor := entry["pos"] as Vector3
		var show_label := not camera.is_position_behind(anchor)
		var screen_position := Vector2.ZERO
		if show_label:
			screen_position = camera.unproject_position(anchor)
			show_label = screen_position.x >= 0.0 and screen_position.x <= viewport_size.x
			show_label = show_label and screen_position.y >= 0.0 and screen_position.y <= viewport_size.y
		if show_label:
			label.position = screen_position - Vector2(label.size.x * 0.5, label.size.y + OVERLAY_ANCHOR_OFFSET)
		label.visible = show_label

func _matches_required(value: String, required_key: String) -> bool:
	var candidate_key := _label_key(value)
	return candidate_key == required_key or candidate_key.begins_with(required_key + " ")

func _label_key(value: String) -> String:
	return value.strip_edges().to_upper()
