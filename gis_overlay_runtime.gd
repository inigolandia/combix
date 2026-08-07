@tool
extends Node3D

## One-shot editor trigger. Setting true regenerates ALL five line-overlay .res
## files from the local GeoJSON sources using the current strip builder and
## resets itself to false when done. The game startup stays lightweight.
@export var regenerate_baked_line_meshes: bool = false:
	set(value):
		regenerate_baked_line_meshes = false
		if not value:
			return
		if not Engine.is_editor_hint():
			push_error("[GISLineRegen] Regeneration is editor-only.")
			return
		if _bake_in_progress:
			push_error("[GISLineRegen] A bake is already in progress; no regeneration was started.")
			return
		_bake_in_progress = true
		call_deferred("_regenerate_line_meshes_deferred")

@export var editor_preview_enabled: bool = false
## When false (default), skips GIS overlay loading at runtime so the game starts without
## parsing GeoJSON or building meshes/collision. Set true to restore the full GIS overlay
## for preview or testing; existing data and scripts are preserved.
@export var runtime_gis_enabled: bool = false
## When runtime_gis_enabled is false, this loads the pre-parsed building segments from the
## runtime cache (fast binary Variant load, no GeoJSON parsing) and builds only the
## aggregated building footprint collision shape. The visual overlays and boundary collision
## are left as their baked scene state. Set false to skip even this lightweight step.
@export var building_collision_runtime_enabled: bool = false
## Manual editor-only action. Setting this property true queues exactly one bake.
## The setter is used instead of @export_tool_button because the Inspector instance
## was retaining a null Callable and did not re-evaluate the button declaration.
var _bake_request_queued := false
@export var bake_embedded_gis_resources: bool = false:
	set(value):
		bake_embedded_gis_resources = value
		if not value:
			_bake_request_queued = false
			return
		if not Engine.is_editor_hint():
			bake_embedded_gis_resources = false
			push_error("[GISResourceBake] Manual bake is editor-only; no resource was saved.")
			return
		if _bake_in_progress or _bake_request_queued:
			bake_embedded_gis_resources = false
			push_error("[GISResourceBake] Bake request is already queued or in progress; no second bake was started.")
			return
		_bake_request_queued = true
		call_deferred("_run_editor_bake_action")
## Editorial-only low-rise preview; runtime remains governed by lowrise_mass_layer_enabled.
## Heights are visual estimates because the footprint source has no official height field.
@export var editor_preview_lowrise_enabled: bool = true
@export_range(0, 250, 1) var editor_preview_lowrise_instance_budget: int = 180

@export_range(1000, 200000, 1000) var building_edge_budget: int = 200000
@export_range(1, 15479, 1) var building_feature_budget: int = 15479
## Estimated visual footprint outline width in real metres, not a surveyed building dimension.
## 1.5 m keeps the batched line legible without making it wider than the 1.8 m player height.
@export var building_line_width: float = 1.5
## Optional low-rise massing; kept batched so it creates no node/collision per footprint.
@export var lowrise_mass_layer_enabled: bool = true:
	set(value):
		lowrise_mass_layer_enabled = value
		_apply_layer_visibility("Sector1LowRiseMassesMultiMesh", value)
@export_range(1, 2000, 1) var lowrise_instance_budget: int = 1800
## Toggle visibility of the baked building footprint linework overlay.
## Does not affect building collision.
@export var building_footprints_visible: bool = true:
	set(value):
		building_footprints_visible = value
		_apply_layer_visibility("Sector1BuildingFootprintsBatch", value)
## Toggle visibility of the baked roadway linework overlay.
@export var roadway_overlay_visible: bool = true:
	set(value):
		roadway_overlay_visible = value
		_apply_layer_visibility("Sector1RoadwayOverlay", value)
## Toggle visibility of the baked square boundaries linework overlay.
@export var square_boundaries_visible: bool = true:
	set(value):
		square_boundaries_visible = value
		_apply_layer_visibility("Sector1SquareBoundariesBatch", value)
## Toggle visibility of the baked waterbody margins overlay.
@export var waterbody_margins_visible: bool = true:
	set(value):
		waterbody_margins_visible = value
		_apply_layer_visibility("Sector1WaterbodyMarginsBatch", value)

## Height estimate only: the CRS84 footprint dataset has no official height field.
## These deliberately low visual-blockout values assume modest one-to-three-storey
## construction in the economically underdeveloped Sector 1; they are not surveyed data.
const LOWRISE_HEIGHT_MIN := 0.18
const LOWRISE_HEIGHT_MAX := 0.42
const LOWRISE_MIN_FOOTPRINT_SIZE := 0.08

## Runtime-only GIS overlay for the Sector 1 compressed canvas. Preview reload touch: r2.
## Reads only local GeoJSON with FileAccess; no HTTP or external dependencies.
## CRS84 lon/lat is projected once through a shared map anchor. The anchor is the
## existing ArenaGround: origin (0, 0), 100 x 100 world units, with the canonical
## WorldScale 1:45 metres-to-units conversion followed by one uniform fit to that
## ground extent. All five GIS layers use this exact _geo_to_canvas transform.
## This is a visual GIS blockout, not final metric georeferencing; batching and the
## arbitrary low-rise preview constants remain unchanged.

const BOUNDARY_PATH := "res://gis/03_sector1_boundary.geojson"
const ROAD_PATH := "res://gis/roadway_functional_classification.geojson"
const BUILDING_PATH := "res://gis/04_building_footprints_sector1.geojson"
const SQUARE_BOUNDARY_PATH := "res://gis/square_boundaries.geojson"
const WATERBODY_PATH := "res://gis/waterbodies.geojson"
const MAP_ANCHOR_CENTER := Vector2.ZERO
const MAP_ANCHOR_EXTENT := 100.0
const MIN_LON := -77.028211888341929
const MAX_LON := -76.961947542810393
const MIN_LAT := 38.808681689858254
const MAX_LAT := 38.875005252856745
const METERS_PER_DEG_LON := 98200.0
const METERS_PER_DEG_LAT := 111320.0
const GIS_ORIGIN_LON := (MIN_LON + MAX_LON) * 0.5
const GIS_ORIGIN_LAT := (MIN_LAT + MAX_LAT) * 0.5
const GIS_EXTENT_UNITS_X := ((MAX_LON - MIN_LON) * METERS_PER_DEG_LON) / WorldScale.METERS_PER_UNIT
const GIS_EXTENT_UNITS_Z := ((MAX_LAT - MIN_LAT) * METERS_PER_DEG_LAT) / WorldScale.METERS_PER_UNIT
const GROUND_Y := 0.0012
## Layer-specific Y offsets eliminate z-fighting between overlapping GIS line layers.
## Roadway is the reference height; the other layers are offset by ~0.00008 increments
## that stay well below player feet (player starts at Y ~= 0.021) while providing
## enough depth-buffer separation at the ~0.35 m spring-arm distance to stop flicker.
const LAYER_Y_ROADWAY := GROUND_Y
const LAYER_Y_WATERBODY := GROUND_Y + 0.00008
const LAYER_Y_BUILDINGS := GROUND_Y + 0.00016
const LAYER_Y_SQUARES := GROUND_Y + 0.00024
const LAYER_Y_BOUNDARY := GROUND_Y + 0.00032
## GIS linework is a representation, not surveyed road/footprint geometry.
## These are explicit metric estimates converted through WorldScale and then through
## the same uniform envelope fit used by _geo_to_canvas, so thin lines remain legible
## without changing the canonical 1:45 world or inventing GIS buildings.
## Explicit user-confirmed road-width fallback. TOTALTRAVELLANEWIDTH is feet, not metres.
const ROAD_WIDTH_FALLBACK_M := 18.0
const BOUNDARY_WIDTH_M := 24.0
const SQUARE_BOUNDARY_WIDTH_M := 5.0
const WATERBODY_WIDTH_M := 8.0
const PREVIEW_REVISION := "r8_road_totaltravellane_ft"
## Runtime cache is a user-local binary Variant file. GeoJSON stays authoritative and visible in the editor.
const RUNTIME_CACHE_PATH := "user://gis_overlay_runtime.cache"
const RUNTIME_CACHE_VERSION := 1
## Main-thread work is deliberately capped so the player can keep processing input
## while local GIS data is prepared. Mesh/Resource creation still stays on main.
const PARSE_FRAME_CHUNK := 1
const CANONICAL_VERTEX_CHUNK := 512
const GEOMETRY_VERTEX_CHUNK := 512
const MESH_SEGMENT_CHUNK := 512
const LOWRISE_FEATURE_CHUNK := 128
const LOWRISE_VERTEX_CHUNK := 512
const LOWRISE_INSTANCE_CHUNK := 128

var _overlay_built := false
var _bake_in_progress := false
var _overlay_build_queued := false
var _overlay_build_running := false
var _overlay_build_generation := 0
var _geojson_cache: Dictionary = {}

# Canonical GIS frame, derived once from the Sector 1 boundary (never per layer).
var _canonical_envelope_rings: Array = []
var _canonical_min_lon := MIN_LON
var _canonical_max_lon := MAX_LON
var _canonical_min_lat := MIN_LAT
var _canonical_max_lat := MAX_LAT
var _canonical_origin_lon := GIS_ORIGIN_LON
var _canonical_origin_lat := GIS_ORIGIN_LAT
var _canonical_extent_units_x := GIS_EXTENT_UNITS_X
var _canonical_extent_units_z := GIS_EXTENT_UNITS_Z
var _canonical_crs := "CRS84"

## Loads the pre-parsed building segments from the runtime binary cache and builds only
## the aggregated building footprint collision shape. No GeoJSON parsing, no mesh creation,
## no visual overlay rebuild. Attaches the shape to the existing Sector1BuildingCollision
## body if one is present and not already populated.
func _build_building_collision_from_cache() -> void:
	var body := get_node_or_null("Sector1BuildingCollision")
	if body == null or not (body is StaticBody3D):
		set_meta("gis_build_phase", "building_collision_body_missing")
		return
	for child in (body as StaticBody3D).get_children():
		if child is CollisionShape3D and child.shape != null:
			set_meta("gis_build_phase", "building_collision_already_present")
			return
	var paths := [BOUNDARY_PATH, ROAD_PATH, BUILDING_PATH, SQUARE_BOUNDARY_PATH, WATERBODY_PATH]
	var prepared: Variant = _runtime_cache_load(paths, building_feature_budget, building_edge_budget, lowrise_instance_budget)
	if prepared == null or not (prepared is Dictionary):
		set_meta("gis_build_phase", "building_collision_cache_miss")
		return
	var prepared_data := prepared as Dictionary
	_set_worker_envelope(prepared_data)
	var building_segments: Array[Vector4] = _segments_from_worker(prepared_data.get("building_segments", []))
	if building_segments.is_empty():
		set_meta("gis_build_phase", "building_collision_no_segments")
		return
	var building_wall_height := LOWRISE_HEIGHT_MAX
	var building_bottom_y := GROUND_Y
	var building_top_y := GROUND_Y + building_wall_height
	var inner_offset := _meters_to_canvas_width(building_line_width) * 0.5
	var building_collision_faces: PackedVector3Array = _build_building_inner_edge_collision_faces(
		building_segments,
		inner_offset,
		building_bottom_y,
		building_top_y
	)
	if building_collision_faces.is_empty():
		set_meta("gis_build_phase", "building_collision_empty_faces")
		return
	var building_collision_shape := ConcavePolygonShape3D.new()
	building_collision_shape.set_faces(building_collision_faces)
	var shape_node := CollisionShape3D.new()
	shape_node.name = "AggregatedFootprintWalls"
	shape_node.shape = building_collision_shape
	body.add_child(shape_node)
	var valid_count: int = int(building_collision_faces.size() / 6)
	set_meta("gis_building_collision_aggregated", true)
	set_meta("gis_building_collision_shape_type", "ConcavePolygonShape3D")
	set_meta("gis_building_collision_shape_count", 1)
	set_meta("gis_building_collision_segment_count", valid_count)
	set_meta("gis_building_collision_wall_height_units", building_wall_height)
	set_meta("gis_building_collision_per_footprint_nodes", 0)
	set_meta("gis_build_phase", "building_collision_loaded_from_cache")

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_overlay_built = false
		_overlay_build_queued = false

func _apply_layer_visibility(node_name: String, show: bool) -> void:
	var node := get_node_or_null("../BakedMap/" + node_name)
	if node is Node3D:
		(node as Node3D).visible = show

func _sync_baked_layer_visibility() -> void:
	_apply_layer_visibility("Sector1LowRiseMassesMultiMesh", lowrise_mass_layer_enabled)
	_apply_layer_visibility("Sector1BuildingFootprintsBatch", building_footprints_visible)
	_apply_layer_visibility("Sector1RoadwayOverlay", roadway_overlay_visible)
	_apply_layer_visibility("Sector1SquareBoundariesBatch", square_boundaries_visible)
	_apply_layer_visibility("Sector1WaterbodyMarginsBatch", waterbody_margins_visible)

## When runtime GIS is disabled, hide stale visual overlay nodes under
## GISOverlayRuntime that were created by a previous editor bake. The
## BakedMap nodes provide the visible geometry; duplicates at identical
## Y coordinates cause z-fighting flicker. Collision bodies stay active.
func _hide_runtime_visual_overlays() -> void:
	var visual_names := ["Sector1BoundaryOverlay", "Sector1RoadwayOverlay",
		"Sector1SquareBoundariesBatch", "Sector1WaterbodyMarginsBatch",
		"Sector1BuildingFootprintsBatch", "Sector1LowRiseMassesMultiMesh"]
	for node_name in visual_names:
		var node := get_node_or_null(node_name)
		if node is Node3D:
			(node as Node3D).visible = false

func _ready() -> void:
	_sync_baked_layer_visibility()
	if Engine.is_editor_hint():
		_overlay_built = false
		if editor_preview_enabled:
			_build_overlay_once()
		return
	if not runtime_gis_enabled:
		_overlay_built = false
		set_meta("gis_load_completed", false)
		set_meta("gis_build_phase", "disabled")
		_hide_runtime_visual_overlays()
		if building_collision_runtime_enabled:
			_build_building_collision_from_cache()
		return
	set_meta("startup_unblocked_fix", true)
	set_meta("gis_load_completed", false)
	set_meta("gis_build_phase", "queued_scene_ready")
	_queue_overlay_build()

func _run_editor_bake_action() -> void:
	if not Engine.is_editor_hint():
		push_error("[GISResourceBake] Bake requested outside the editor; no resource was saved.")
		bake_embedded_gis_resources = false
		return
	if _bake_in_progress:
		push_error("[GISResourceBake] Bake is already in progress; no second bake was started.")
		bake_embedded_gis_resources = false
		return
	_bake_in_progress = true
	set_meta("gis_resource_bake_status", "materializing_editor_overlay")
	# The overlay build may have cleared generated children and still be awaiting
	# worker/mesh frames. One frame is not a materialization barrier.
	await get_tree().process_frame
	if not is_inside_tree() or not Engine.is_editor_hint():
		push_error("[GISResourceBake] Editor frame was not available; no resource was saved.")
		bake_embedded_gis_resources = false
		_bake_in_progress = false
		return
	if not await _ensure_editor_bake_materialization():
		set_meta("gis_resource_bake_status", "blocked_materialization")
		push_error("[GISResourceBake] GIS overlay could not be materialized for bake. Existing GISOverlayRuntime children: %s. No resource was saved." % _existing_editor_child_names())
		bake_embedded_gis_resources = false
		_bake_in_progress = false
		return
	set_meta("gis_resource_bake_status", "running")
	var bake_succeeded: bool = _bake_materialized_gis_resources()
	if bake_succeeded:
		print("[GISResourceBake] Manual bake completed: %d resources saved to %s" % [int(get_meta("gis_resource_bake_resource_count", 0)), str(get_meta("gis_resource_bake_scene_path", "res://main.tscn"))])
	else:
		push_error("[GISResourceBake] Manual bake failed; status=%s" % str(get_meta("gis_resource_bake_status", "unknown")))
	# Always clear the visible one-shot trigger after the deferred action.
	bake_embedded_gis_resources = false
	_bake_in_progress = false

func _ensure_editor_bake_materialization() -> bool:
	if _has_materialized_bake_nodes():
		return true
	if _overlay_build_running:
		var waited_frames := 0
		while _overlay_build_running and waited_frames < 240:
			await get_tree().process_frame
			waited_frames += 1
		if _overlay_build_running:
			set_meta("gis_resource_bake_status", "blocked_materialization_timeout")
			return false
	if not _has_materialized_bake_nodes():
		# Supersede any queued preview build and run one explicit editor rebuild.
		_overlay_build_queued = false
		_overlay_built = false
		_overlay_build_generation += 1
		await _build_overlay_once(_overlay_build_generation)
	return _has_materialized_bake_nodes()

func _has_materialized_bake_nodes() -> bool:
	for request in _GIS_RESOURCE_BAKE_REQUESTS:
		var node := get_node_or_null(str(request["node_path"]))
		if node == null:
			return false
		var materialized: Variant = node.get(str(request["property"]))
		if not (materialized is Resource):
			return false
	return true

func _existing_editor_child_names() -> String:
	var names: Array[String] = []
	for child in get_children():
		names.append(str(child.name))
	return ", ".join(names)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not editor_preview_enabled:
		return
	if not _overlay_built or not _has_generated_children():
		_overlay_built = false
		_build_overlay_once()

const _GIS_RESOURCE_BAKE_REQUESTS := [
	{"node_path": "Sector1BoundaryOverlay", "property": "mesh", "path": "res://gis/sector1_boundary_overlay.res"},
	{"node_path": "Sector1RoadwayOverlay", "property": "mesh", "path": "res://gis/sector1_roadway_overlay.res"},
	{"node_path": "Sector1SquareBoundariesBatch", "property": "mesh", "path": "res://gis/sector1_square_boundaries_batch.res"},
	{"node_path": "Sector1WaterbodyMarginsBatch", "property": "mesh", "path": "res://gis/sector1_waterbody_margins_batch.res"},
	{"node_path": "Sector1BuildingFootprintsBatch", "property": "mesh", "path": "res://gis/sector1_building_footprints_batch.res"},
	{"node_path": "Sector1LowRiseMassesMultiMesh", "property": "multimesh", "path": "res://gis/sector1_lowrise_masses_multimesh.res"}
]

func _bake_materialized_gis_resources() -> bool:
	if not Engine.is_editor_hint():
		return false
	var scene_root := get_tree().edited_scene_root
	if scene_root == null or scene_root.scene_file_path != "res://main.tscn":
		set_meta("gis_resource_bake_status", "blocked_expected_main_scene")
		push_error("[GISResourceBake] Edited scene must be res://main.tscn")
		return false

	var nodes: Array = []
	var properties: Array = []
	var originals: Array = []
	var external_resources: Array = []
	for request in _GIS_RESOURCE_BAKE_REQUESTS:
		var node := get_node_or_null(str(request["node_path"]))
		var property := str(request["property"])
		var path := str(request["path"])
		if node == null:
			set_meta("gis_resource_bake_status", "blocked_missing_node_%s" % request["node_path"])
			push_error("[GISResourceBake] Missing materialized GIS node: %s" % request["node_path"])
			return false
		var materialized: Variant = node.get(property)
		if not (materialized is Resource):
			set_meta("gis_resource_bake_status", "blocked_missing_resource_%s" % request["node_path"])
			push_error("[GISResourceBake] Missing resource on %s.%s" % [request["node_path"], property])
			return false
		nodes.append(node)
		properties.append(property)
		originals.append(materialized)
		var save_error: Error = ResourceSaver.save(materialized as Resource, path, ResourceSaver.FLAG_BUNDLE_RESOURCES)
		if save_error != OK or not FileAccess.file_exists(path):
			set_meta("gis_resource_bake_status", "failed_save_%s_%s" % [path, save_error])
			push_error("[GISResourceBake] ResourceSaver.save failed for %s: %s" % [path, save_error])
			return false

	# Resolve every saved resource before changing any scene property.
	for request in _GIS_RESOURCE_BAKE_REQUESTS:
		var path := str(request["path"])
		var loaded: Resource = ResourceLoader.load(path) as Resource
		if loaded == null:
			set_meta("gis_resource_bake_status", "failed_load_%s" % path)
			push_error("[GISResourceBake] Could not reload saved resource: %s" % path)
			return false
		external_resources.append(loaded)

	for index in range(nodes.size()):
		nodes[index].set(properties[index], external_resources[index])
		var assigned: Variant = nodes[index].get(properties[index])
		if not (assigned is Resource) or (assigned as Resource).resource_path != str(_GIS_RESOURCE_BAKE_REQUESTS[index]["path"]):
			_restore_gis_bake_originals(nodes, properties, originals)
			set_meta("gis_resource_bake_status", "failed_external_reference_%d" % index)
			push_error("[GISResourceBake] External resource reference verification failed")
			return false

	var packed_scene := PackedScene.new()
	var pack_error: Error = packed_scene.pack(scene_root)
	if pack_error != OK:
		_restore_gis_bake_originals(nodes, properties, originals)
		set_meta("gis_resource_bake_status", "failed_pack_scene_%s" % pack_error)
		push_error("[GISResourceBake] Could not pack main.tscn after externalization: %s" % pack_error)
		return false
	var scene_save_error: Error = ResourceSaver.save(packed_scene, scene_root.scene_file_path)
	if scene_save_error != OK:
		_restore_gis_bake_originals(nodes, properties, originals)
		set_meta("gis_resource_bake_status", "failed_save_scene_%s" % scene_save_error)
		push_error("[GISResourceBake] Could not save main.tscn after externalization: %s" % scene_save_error)
		return false
	set_meta("gis_resource_bake_status", "completed")
	set_meta("gis_resource_bake_resource_count", external_resources.size())
	set_meta("gis_resource_bake_scene_path", scene_root.scene_file_path)
	return true

func _restore_gis_bake_originals(nodes: Array, properties: Array, originals: Array) -> void:
	for index in range(mini(nodes.size(), originals.size())):
		if nodes[index] != null:
			nodes[index].set(properties[index], originals[index])

func _has_generated_children() -> bool:
	for child in get_children():
		if child.get_meta("gis_overlay_generated", false):
			return true
	return false

func _queue_overlay_build() -> void:
	if _overlay_built or _overlay_build_queued or _overlay_build_running:
		return
	_overlay_build_queued = true
	_overlay_build_generation += 1
	call_deferred("_build_overlay_once", _overlay_build_generation)

func _build_overlay_once(build_generation: int = -1) -> void:
	if build_generation >= 0 and build_generation != _overlay_build_generation:
		return
	_overlay_build_queued = false
	if _overlay_build_running or (_overlay_built and _has_generated_children()):
		return
	_overlay_build_running = true
	_overlay_built = false
	_clear_generated_children()
	set_meta("startup_unblocked_fix", true)
	set_meta("gis_load_completed", false)
	set_meta("gis_build_phase", "scene_ready")
	await _load_and_render()
	_overlay_build_running = false

func _build_is_current(build_generation: int) -> bool:
	return is_inside_tree() and (build_generation < 0 or build_generation == _overlay_build_generation)

func _clear_generated_children() -> void:
	for child in get_children():
		if child.get_meta("gis_overlay_generated", false):
			remove_child(child)
			child.free()

func _add_generated_child(child: Node) -> void:
	child.set_meta("gis_overlay_generated", true)
	add_child(child)
	if child is Node3D:
		var spatial_child := child as Node3D
		spatial_child.visible = true
		spatial_child.top_level = false
		spatial_child.transform = Transform3D.IDENTITY
	if Engine.is_editor_hint():
		child.owner = get_tree().edited_scene_root
	else:
		child.owner = null

func _build_building_inner_edge_collision_faces(building_segments: Array[Vector4], inner_offset: float, wall_bottom_y: float, wall_top_y: float) -> PackedVector3Array:
	return _build_building_inner_edge_collision_faces_impl(building_segments, inner_offset, wall_bottom_y, wall_top_y)

func _load_and_render() -> void:
	var build_generation := _overlay_build_generation
	set_meta("gis_build_phase", "yield_before_worker_prepare")
	await get_tree().process_frame
	if not _build_is_current(build_generation):
		return
	var paths := [BOUNDARY_PATH, ROAD_PATH, BUILDING_PATH, SQUARE_BOUNDARY_PATH, WATERBODY_PATH]
	# A valid user-local binary Variant cache skips JSON.parse_string, CRS conversion,
	# envelope clipping and the 15k-footprint traversal on subsequent Play Tests.
	# The cache contains only plain Arrays, Dictionaries and scalars, never Nodes,
	# SceneTree state or Resources. The GeoJSON sources remain editor-authoritative.
	var prepared: Variant = _runtime_cache_load(paths, building_feature_budget, building_edge_budget, lowrise_instance_budget)
	if prepared == null:
		set_meta("gis_build_phase", "worker_prepare_plain_data")
		var preparation_thread := Thread.new()
		var start_error: Error = preparation_thread.start(Callable(self, "_prepare_overlay_thread").bind(paths, building_feature_budget, building_edge_budget, lowrise_instance_budget))
		if start_error != OK:
			set_meta("gis_build_phase", "main_thread_fallback_prepare")
			prepared = _prepare_overlay_thread(paths, building_feature_budget, building_edge_budget, lowrise_instance_budget)
		else:
			while preparation_thread.is_alive():
				await get_tree().process_frame
				if not is_inside_tree():
					# Do not call wait_to_finish() while the worker is alive. The main-thread
					# continuation is abandoned during teardown and no scene state is touched.
					return
			prepared = preparation_thread.wait_to_finish()
		if not _build_is_current(build_generation):
			return
		if prepared is Dictionary and (prepared as Dictionary).get("error", "") == "":
			_runtime_cache_store(prepared as Dictionary, paths, building_feature_budget, building_edge_budget, lowrise_instance_budget)
	else:
		set_meta("gis_build_phase", "runtime_cache_loaded")
	if not _build_is_current(build_generation):
		return
	if not (prepared is Dictionary) or (prepared as Dictionary).get("error", "") != "":
		# A worker can fail after start (for example on a Variant shape mismatch).
		# Retry the same plain-data preparation synchronously; Mesh/Node creation
		# remains below on the main thread, and this path is idempotent.
		set_meta("gis_build_phase", "main_thread_fallback_prepare")
		var fallback_prepared: Variant = _prepare_overlay_thread(paths, building_feature_budget, building_edge_budget, lowrise_instance_budget)
		if fallback_prepared is Dictionary and (fallback_prepared as Dictionary).get("error", "") == "":
			prepared = fallback_prepared
		else:
			var failure := "invalid worker result"
			if fallback_prepared is Dictionary:
				failure = str((fallback_prepared as Dictionary).get("error", failure))
			push_error("[GISOverlay] GIS preparation failed in worker and fallback: %s" % failure)
			set_meta("gis_overlay_visible", false)
			return
	var prepared_data := prepared as Dictionary
	_set_worker_envelope(prepared_data)
	var boundary_segments: Array[Vector4] = _segments_from_worker(prepared_data.get("boundary_segments", []))
	var road_segments: Array[Vector4] = _segments_from_worker(prepared_data.get("road_segments", []))
	var road_width_meters: Array = prepared_data.get("road_width_meters", []) as Array
	var square_boundary_segments: Array[Vector4] = _segments_from_worker(prepared_data.get("square_boundary_segments", []))
	var waterbody_segments: Array[Vector4] = _segments_from_worker(prepared_data.get("waterbody_segments", []))
	var building_segments: Array[Vector4] = _segments_from_worker(prepared_data.get("building_segments", []))
	var building_features_drawn: int = int(prepared_data.get("building_features_drawn", 0))
	var lowrise_bounds: Array[Rect2] = _bounds_from_worker(prepared_data.get("lowrise_bounds", []))
	var lowrise_instances_drawn := lowrise_bounds.size()
	var lowrise_enabled := lowrise_mass_layer_enabled
	var lowrise_budget := lowrise_instance_budget
	if Engine.is_editor_hint():
		lowrise_enabled = lowrise_enabled and editor_preview_lowrise_enabled
		lowrise_budget = mini(editor_preview_lowrise_instance_budget, 250)
	set_meta("gis_build_phase", "main_thread_build_boundary_mesh")
	var boundary_mesh := await _build_strip_mesh(boundary_segments, _meters_to_canvas_width(BOUNDARY_WIDTH_M), LAYER_Y_BOUNDARY, build_generation)
	if not _build_is_current(build_generation):
		return
	var road_mesh := await _build_variable_width_strip_mesh(road_segments, road_width_meters, LAYER_Y_ROADWAY, build_generation)
	if not _build_is_current(build_generation):
		return
	var square_boundary_mesh := await _build_strip_mesh(square_boundary_segments, _meters_to_canvas_width(SQUARE_BOUNDARY_WIDTH_M), LAYER_Y_SQUARES, build_generation)
	if not _build_is_current(build_generation):
		return
	var waterbody_mesh := await _build_strip_mesh(waterbody_segments, _meters_to_canvas_width(WATERBODY_WIDTH_M), LAYER_Y_WATERBODY, build_generation)
	if not _build_is_current(build_generation):
		return
	var building_mesh := await _build_strip_mesh(building_segments, _meters_to_canvas_width(building_line_width), LAYER_Y_BUILDINGS, build_generation)
	if not _build_is_current(build_generation):
		return
	set_meta("gis_build_phase", "main_thread_build_boundary_collision")
	if _build_is_current(build_generation) and not boundary_segments.is_empty():
		var boundary_collision_root := StaticBody3D.new()
		boundary_collision_root.name = "Sector1BoundaryCollision"
		boundary_collision_root.collision_layer = 1
		boundary_collision_root.collision_mask = 1
		boundary_collision_root.set_meta("source", BOUNDARY_PATH)
		boundary_collision_root.set_meta("geometry", "same closed Sector 1 boundary segments as Sector1BoundaryOverlay")
		boundary_collision_root.set_meta("collision_scope", "boundary only; no roads, buildings or footprints")
		var envelope_rings: Array = prepared_data.get("envelope_rings", []) as Array
		var boundary_ring_area_xz := _boundary_ring_signed_area_xz(envelope_rings[0] as Array) if not envelope_rings.is_empty() else 0.0
		var boundary_visual_width_units := _meters_to_canvas_width(BOUNDARY_WIDTH_M)
		var boundary_collision_thickness := 0.04
		boundary_collision_root.set_meta("visual_line_width_m", BOUNDARY_WIDTH_M)
		boundary_collision_root.set_meta("visual_line_width_units", boundary_visual_width_units)
		boundary_collision_root.set_meta("ring_signed_area_xz", boundary_ring_area_xz)
		boundary_collision_root.set_meta("ring_winding_xz", "CCW/interior-left" if boundary_ring_area_xz > 0.0 else "CW/interior-right")
		boundary_collision_root.set_meta("collision_edge", "outer visual edge; centerline + exterior normal * (visual_width/2 + thickness/2)")
		boundary_collision_root.set_meta("collision_thickness_units", boundary_collision_thickness)
		_add_generated_child(boundary_collision_root)
		# Build one aggregated closed solid from every transformed boundary ring.
		# The segments are the exact array already consumed by the yellow overlay;
		# rings are closed on endpoint equality, so MultiPolygon parts and holes are
		# kept instead of being concatenated into one rectangular or hull envelope.
		var collision_faces := PackedVector3Array()
		var boundary_ring_points: Array = []
		var boundary_ring_count := 0
		var boundary_ring_vertex_count := 0
		var visual_half_width := boundary_visual_width_units * 0.5
		var collision_half_thickness := boundary_collision_thickness * 0.5
		var wall_bottom_y := GROUND_Y
		var wall_top_y := GROUND_Y + 0.08
		for segment in boundary_segments:
			var first := Vector2(segment.x, segment.y)
			var second := Vector2(segment.z, segment.w)
			if first.distance_squared_to(second) <= 0.00000001:
				continue
			if boundary_ring_points.is_empty():
				boundary_ring_points.append(first)
				boundary_ring_points.append(second)
			elif (boundary_ring_points[boundary_ring_points.size() - 1] as Vector2).distance_squared_to(first) <= 0.00000001:
				boundary_ring_points.append(second)
			else:
				if boundary_ring_points.size() > 1 and (boundary_ring_points[0] as Vector2).distance_squared_to(boundary_ring_points[boundary_ring_points.size() - 1] as Vector2) <= 0.00000001:
					boundary_ring_points.pop_back()
				collision_faces = _append_boundary_ring_collision_faces(collision_faces, boundary_ring_points, visual_half_width, collision_half_thickness, wall_bottom_y, wall_top_y)
				if boundary_ring_points.size() >= 3:
					boundary_ring_count += 1
					boundary_ring_vertex_count += boundary_ring_points.size()
				boundary_ring_points = [first, second]
			if boundary_ring_points.size() > 2 and (boundary_ring_points[0] as Vector2).distance_squared_to(boundary_ring_points[boundary_ring_points.size() - 1] as Vector2) <= 0.00000001:
				boundary_ring_points.pop_back()
				collision_faces = _append_boundary_ring_collision_faces(collision_faces, boundary_ring_points, visual_half_width, collision_half_thickness, wall_bottom_y, wall_top_y)
				if boundary_ring_points.size() >= 3:
					boundary_ring_count += 1
					boundary_ring_vertex_count += boundary_ring_points.size()
				boundary_ring_points = []
		if boundary_ring_points.size() > 1:
			if (boundary_ring_points[0] as Vector2).distance_squared_to(boundary_ring_points[boundary_ring_points.size() - 1] as Vector2) <= 0.00000001:
				boundary_ring_points.pop_back()
			collision_faces = _append_boundary_ring_collision_faces(collision_faces, boundary_ring_points, visual_half_width, collision_half_thickness, wall_bottom_y, wall_top_y)
			if boundary_ring_points.size() >= 3:
				boundary_ring_count += 1
				boundary_ring_vertex_count += boundary_ring_points.size()

		if not collision_faces.is_empty():
			var boundary_collision_shape := ConcavePolygonShape3D.new()
			boundary_collision_shape.set_faces(collision_faces)
			var shape_node := CollisionShape3D.new()
			shape_node.name = "AggregatedBoundaryMiteredWall"
			shape_node.shape = boundary_collision_shape
			boundary_collision_root.add_child(shape_node)
			if Engine.is_editor_hint():
				shape_node.owner = get_tree().edited_scene_root
			boundary_collision_root.set_meta("shape_type", "ConcavePolygonShape3D")
			boundary_collision_root.set_meta("segment_count", boundary_segments.size())
			boundary_collision_root.set_meta("ring_count", boundary_ring_count)
			boundary_collision_root.set_meta("ring_vertex_count", boundary_ring_vertex_count)
			boundary_collision_root.set_meta("join", "all closed GIS rings with per-vertex miter intersection")
			boundary_collision_root.set_meta("inner_edge_offset_units", visual_half_width)
			boundary_collision_root.set_meta("outer_edge_offset_units", visual_half_width + collision_half_thickness)
		set_meta("gis_boundary_collision_source", BOUNDARY_PATH)
		set_meta("gis_boundary_collision_segment_count", boundary_segments.size())
		set_meta("gis_boundary_collision_ring_count", boundary_ring_count)
		set_meta("gis_boundary_collision_ring_vertex_count", boundary_ring_vertex_count)
		set_meta("gis_boundary_collision_edge_offset", "visual half-width + outward thickness half per closed GIS ring; no spawn offset")
		set_meta("gis_boundary_collision_aligned", true)
	if boundary_mesh != null:
		var boundary_node := MeshInstance3D.new()
		boundary_node.name = "Sector1BoundaryOverlay"
		boundary_node.mesh = boundary_mesh
		boundary_node.material_override = _make_material(Color("#ffe88a"), -5)
		boundary_node.set_meta("source", BOUNDARY_PATH)
		boundary_node.set_meta("geometry", "Polygon/MultiPolygon rings")
		_add_generated_child(boundary_node)
	if road_mesh != null:
		var road_node := MeshInstance3D.new()
		road_node.name = "Sector1RoadwayOverlay"
		road_node.mesh = road_mesh
		road_node.material_override = _make_material(Color("#8fb8c8"), -1)
		road_node.set_meta("source", ROAD_PATH)
		road_node.set_meta("geometry", "LineString/MultiLineString")
		_add_generated_child(road_node)
	if square_boundary_mesh != null:
		var square_boundary_node := MeshInstance3D.new()
		square_boundary_node.name = "Sector1SquareBoundariesBatch"
		square_boundary_node.mesh = square_boundary_mesh
		square_boundary_node.material_override = _make_material(Color("#b8a879"), -4)
		square_boundary_node.set_meta("source", SQUARE_BOUNDARY_PATH)
		square_boundary_node.set_meta("geometry", "Polygon/MultiPolygon rings, batched outline")
		square_boundary_node.set_meta("collision_count", 0)
		_add_generated_child(square_boundary_node)
	if waterbody_mesh != null:
		var waterbody_node := MeshInstance3D.new()
		waterbody_node.name = "Sector1WaterbodyMarginsBatch"
		waterbody_node.mesh = waterbody_mesh
		waterbody_node.material_override = _make_material(Color("#668fa0"), -2)
		waterbody_node.set_meta("source", WATERBODY_PATH)
		waterbody_node.set_meta("geometry", "Polygon/MultiPolygon rings, batched margin")
		waterbody_node.set_meta("collision_count", 0)
		_add_generated_child(waterbody_node)
	if building_mesh != null:
		var building_node := MeshInstance3D.new()
		building_node.name = "Sector1BuildingFootprintsBatch"
		building_node.mesh = building_mesh
		building_node.material_override = _make_material(Color("#a9bac0"), -3)
		building_node.set_meta("source", BUILDING_PATH)
		building_node.set_meta("geometry", "MultiPolygon rings, batched outline")
		building_node.set_meta("normalization", "worker: CRS84/EPSG:26985 -> shared _geo_to_canvas transform; no projected-bounds normalization")
		building_node.set_meta("collision_count", 0)
		_add_generated_child(building_node)
	var lowrise_multimesh: MultiMesh = null
	await get_tree().process_frame
	if not _build_is_current(build_generation):
		return
	if lowrise_enabled and lowrise_budget > 0 and not lowrise_bounds.is_empty():
		set_meta("gis_build_phase", "main_thread_build_lowrise_multimesh")
		lowrise_multimesh = await _build_lowrise_multimesh(lowrise_bounds, lowrise_budget, build_generation)
		if not _build_is_current(build_generation):
			return
	if lowrise_multimesh != null:
		var lowrise_node := MultiMeshInstance3D.new()
		lowrise_node.name = "Sector1LowRiseMassesMultiMesh"
		lowrise_node.multimesh = lowrise_multimesh
		lowrise_node.visible = lowrise_enabled
		var lowrise_material := _make_material(Color("#9aa9a7", 0.72), -3)
		lowrise_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lowrise_node.material_override = lowrise_material
		lowrise_node.set_meta("source", BUILDING_PATH)
		lowrise_node.set_meta("geometry", "worker-prepared CRS84 footprint bounds as low-rise BoxMesh instances")
		lowrise_node.set_meta("height_estimate_source", "No official heights in dataset; explicit low-rise visual estimate for economically underdeveloped Sector 1")
		lowrise_node.set_meta("height_estimate_units", "%0.2f-%0.2f canvas units; not official building data" % [LOWRISE_HEIGHT_MIN, LOWRISE_HEIGHT_MAX])
		lowrise_node.set_meta("instance_budget", lowrise_budget)
		lowrise_node.set_meta("instances_drawn", lowrise_instances_drawn)
		lowrise_node.set_meta("collision_count", 0)
		_add_generated_child(lowrise_node)
	set_meta("gis_build_phase", "main_thread_build_aggregated_building_collision")
	if _build_is_current(build_generation) and not building_segments.is_empty() and get_node_or_null("Sector1BuildingCollision") == null:
		# One static concave shape contains the vertical walls for every source footprint.
		# Reuse the worker's building_segments; do not create footprint nodes or bodies.
		var building_wall_height := LOWRISE_HEIGHT_MAX
		var building_bottom_y := GROUND_Y
		var building_top_y := GROUND_Y + building_wall_height
		# The footprint overlay is a centered strip. Place the collision wall at its
		# inner edge, not at the strip centerline; the helper preserves each closed
		# ring's winding, mitered corners and nested holes while staying aggregated.
		var building_collision_faces: PackedVector3Array = _build_building_inner_edge_collision_faces(
			building_segments,
			_meters_to_canvas_width(building_line_width) * 0.5,
			building_bottom_y,
			building_top_y
		)
		var building_valid_segment_count: int = int(building_collision_faces.size() / 6)
		if not building_collision_faces.is_empty():
			var building_collision_root := StaticBody3D.new()
			building_collision_root.name = "Sector1BuildingCollision"
			building_collision_root.collision_layer = 1
			building_collision_root.collision_mask = 1
			building_collision_root.set_meta("source", BUILDING_PATH)
			building_collision_root.set_meta("geometry", "same closed footprint segments as Sector1BuildingFootprintsBatch")
			building_collision_root.set_meta("height_source", "LOWRISE_HEIGHT_MAX reused as conservative wall height")
			building_collision_root.set_meta("visual_line_width_m", building_line_width)
			building_collision_root.set_meta("visual_line_width_units", _meters_to_canvas_width(building_line_width))
			building_collision_root.set_meta("inner_edge_offset_units", _meters_to_canvas_width(building_line_width) * 0.5)
			building_collision_root.set_meta("collision_edge", "footprint inner edge; per-ring winding/normal with nested-hole inversion")
			building_collision_root.set_meta("collision_scope", "all Sector 1 building footprints; one aggregated static body")
			building_collision_root.set_meta("footprint_segment_count", building_valid_segment_count)
			building_collision_root.set_meta("wall_height_units", building_wall_height)
			building_collision_root.set_meta("per_building_collision_count", 0)
			var building_collision_shape := ConcavePolygonShape3D.new()
			building_collision_shape.set_faces(building_collision_faces)
			var building_shape_node := CollisionShape3D.new()
			building_shape_node.name = "AggregatedFootprintWalls"
			building_shape_node.shape = building_collision_shape
			building_collision_root.add_child(building_shape_node)
			if Engine.is_editor_hint():
				building_shape_node.owner = get_tree().edited_scene_root
			_add_generated_child(building_collision_root)
			set_meta("gis_building_collision_aggregated", true)
			set_meta("gis_building_collision_shape_type", "ConcavePolygonShape3D")
			set_meta("gis_building_collision_shape_count", 1)
			set_meta("gis_building_collision_segment_count", building_valid_segment_count)
			set_meta("gis_building_collision_wall_height_units", building_wall_height)
			set_meta("gis_building_collision_per_footprint_nodes", 0)
	set_meta("gis_overlay_visible", boundary_mesh != null and road_mesh != null)
	set_meta("gis_local_loader", true)
	set_meta("gis_boundary_segment_count", boundary_segments.size())
	set_meta("gis_road_segment_count", road_segments.size())
	set_meta("gis_square_boundary_segment_count", square_boundary_segments.size())
	set_meta("gis_waterbody_segment_count", waterbody_segments.size())
	set_meta("gis_transform", "worker CRS84/EPSG:26985 -> shared _geo_to_canvas; Sector 1 boundary envelope; ArenaGround anchor center (0,0), extent 100x100, WorldScale.METERS_PER_UNIT=45.0, uniform aspect-preserving fit; x=east, z=south")
	set_meta("gis_width_estimates_m", "roads=%0.1f; sector_boundary=%0.1f; square_boundary=%0.1f; water_margin=%0.1f; footprint_outline=%0.1f; all WorldScale.meters_to_units() then shared envelope fit" % [ROAD_WIDTH_FALLBACK_M, BOUNDARY_WIDTH_M, SQUARE_BOUNDARY_WIDTH_M, WATERBODY_WIDTH_M, building_line_width])
	set_meta("gis_road_width_estimate_m", ROAD_WIDTH_FALLBACK_M)
	set_meta("gis_footprint_line_width_estimate_m", building_line_width)
	set_meta("gis_map_anchor", "ArenaGround position (0,0,0), BoxMesh 100x0.4x100, origin shared with GISOverlayRuntime")
	set_meta("gis_geo_origin", "canonical Sector 1 bounds midpoint lon=%0.12f lat=%0.12f; no per-layer normalization" % [_canonical_origin_lon, _canonical_origin_lat])
	set_meta("gis_envelope_source", BOUNDARY_PATH)
	set_meta("gis_envelope_crs", _canonical_crs)
	set_meta("gis_envelope_filter", "all non-boundary layer segments require both endpoints inside canonical Sector 1 polygon")
	set_meta("gis_dataset_crs_normalization", "worker CRS84 passthrough; EPSG:26985 NAD83/Maryland inverse LCC -> CRS84 before shared transform")
	set_meta("gis_layers_batched", true)
	set_meta("gis_layer_node_budget", get_child_count() <= 7)
	set_meta("gis_layer_node_budget_limit", 7)
	set_meta("footprints_batched_script", true)
	set_meta("footprint_node_budget", get_child_count() <= 7)
	set_meta("gis_building_features_drawn", building_features_drawn)
	set_meta("gis_building_edge_count", building_segments.size())
	set_meta("gis_building_edge_budget", building_edge_budget)
	set_meta("gis_buildings_instanced", lowrise_instances_drawn)
	set_meta("gis_lowrise_mass_layer_enabled", lowrise_enabled)
	set_meta("gis_lowrise_instance_budget", lowrise_budget)
	set_meta("gis_lowrise_instances_drawn", lowrise_instances_drawn)
	set_meta("gis_lowrise_height_estimate", "Explicit low-rise estimate %0.2f-%0.2f canvas units; no official heights in source dataset" % [LOWRISE_HEIGHT_MIN, LOWRISE_HEIGHT_MAX])
	set_meta("gis_lowrise_single_multimesh", lowrise_multimesh != null)
	set_meta("gis_preview_revision", "r7_worker_preparation")
	set_meta("gis_build_phase", "completed")
	set_meta("gis_load_completed", true)
	_overlay_built = true

func _boundary_ring_signed_area_xz(ring: Array) -> float:
	var signed_area := 0.0
	for index in range(ring.size() - 1):
		var first := ring[index] as Array
		var second := ring[index + 1] as Array
		if first.size() < 2 or second.size() < 2:
			continue
		# The overlay frame is x=east, z=south, so latitude is negated here.
		var a := Vector2(float(first[0]), -float(first[1]))
		var b := Vector2(float(second[0]), -float(second[1]))
		signed_area += a.x * b.y - b.x * a.y
	return signed_area * 0.5

func _boundary_exterior_normal(delta: Vector2, ring_area_xz: float) -> Vector2:
	var left_normal := Vector2(-delta.y, delta.x).normalized()
	# Positive XZ winding means the Sector 1 interior is left of each edge;
	# negative winding means the interior is right. Pick the opposite side.
	return -left_normal if ring_area_xz > 0.0 else left_normal

func _append_boundary_ring_collision_faces(faces: PackedVector3Array, ring_points: Array, visual_half_width: float, collision_half_thickness: float, wall_bottom_y: float, wall_top_y: float) -> PackedVector3Array:
	if ring_points.size() < 3:
		return faces
	var point_count := ring_points.size()
	var ring_area_xz := 0.0
	for index in range(point_count):
		var first := ring_points[index] as Vector2
		var second := ring_points[(index + 1) % point_count] as Vector2
		ring_area_xz += first.x * second.y - second.x * first.y
	ring_area_xz *= 0.5
	if absf(ring_area_xz) <= 0.00000001:
		return faces
	var outer_offset := visual_half_width + collision_half_thickness
	var inner_offset := visual_half_width
	var outer_points: Array = []
	var inner_points: Array = []
	for index in range(point_count):
		var previous := ring_points[(index - 1 + point_count) % point_count] as Vector2
		var current := ring_points[index] as Vector2
		var following := ring_points[(index + 1) % point_count] as Vector2
		var previous_delta := current - previous
		var following_delta := following - current
		if previous_delta.length_squared() <= 0.00000001 or following_delta.length_squared() <= 0.00000001:
			var fallback_delta := following_delta if following_delta.length_squared() > 0.00000001 else previous_delta
			var fallback_normal := _boundary_exterior_normal(fallback_delta, ring_area_xz)
			outer_points.append(current + fallback_normal * outer_offset)
			inner_points.append(current + fallback_normal * inner_offset)
			continue
		var previous_normal := _boundary_exterior_normal(previous_delta, ring_area_xz)
		var following_normal := _boundary_exterior_normal(following_delta, ring_area_xz)
		var miter_sum := previous_normal + following_normal
		if miter_sum.length_squared() <= 0.00000001:
			miter_sum = following_normal
		var miter_direction := miter_sum.normalized()
		var miter_denominator := miter_direction.dot(following_normal)
		if absf(miter_denominator) < 0.05:
			miter_denominator = 1.0
		outer_points.append(current + miter_direction * (outer_offset / miter_denominator))
		inner_points.append(current + miter_direction * (inner_offset / miter_denominator))
	for index in range(point_count):
		var next_index := (index + 1) % point_count
		var outer_a_bottom := Vector3((outer_points[index] as Vector2).x, wall_bottom_y, (outer_points[index] as Vector2).y)
		var outer_b_bottom := Vector3((outer_points[next_index] as Vector2).x, wall_bottom_y, (outer_points[next_index] as Vector2).y)
		var inner_a_bottom := Vector3((inner_points[index] as Vector2).x, wall_bottom_y, (inner_points[index] as Vector2).y)
		var inner_b_bottom := Vector3((inner_points[next_index] as Vector2).x, wall_bottom_y, (inner_points[next_index] as Vector2).y)
		var outer_a_top := Vector3(outer_a_bottom.x, wall_top_y, outer_a_bottom.z)
		var outer_b_top := Vector3(outer_b_bottom.x, wall_top_y, outer_b_bottom.z)
		var inner_a_top := Vector3(inner_a_bottom.x, wall_top_y, inner_a_bottom.z)
		var inner_b_top := Vector3(inner_b_bottom.x, wall_top_y, inner_b_bottom.z)
		# Outer wall, inner wall, top and bottom caps make every ring a closed solid.
		faces.append_array([outer_a_bottom, outer_b_bottom, outer_b_top, outer_a_bottom, outer_b_top, outer_a_top])
		faces.append_array([inner_a_bottom, inner_b_top, inner_b_bottom, inner_a_bottom, inner_a_top, inner_b_top])
		faces.append_array([outer_a_top, outer_b_top, inner_b_top, outer_a_top, inner_b_top, inner_a_top])
		faces.append_array([outer_a_bottom, inner_b_bottom, outer_b_bottom, outer_a_bottom, inner_a_bottom, inner_b_bottom])
	return faces

func _build_building_inner_edge_collision_faces_impl(building_segments: Array[Vector4], inner_offset: float, wall_bottom_y: float, wall_top_y: float) -> PackedVector3Array:
	var faces := PackedVector3Array()
	var rings: Array = []
	var current_ring: Array = []
	for segment in building_segments:
		var first := Vector2(segment.x, segment.y)
		var second := Vector2(segment.z, segment.w)
		if first.distance_squared_to(second) <= 0.00000001:
			continue
		if current_ring.is_empty():
			current_ring = [first, second]
		elif (current_ring[current_ring.size() - 1] as Vector2).distance_squared_to(first) <= 0.00000001:
			current_ring.append(second)
		else:
			if current_ring.size() > 2 and (current_ring[0] as Vector2).distance_squared_to(current_ring[current_ring.size() - 1] as Vector2) <= 0.00000001:
				current_ring.pop_back()
			if current_ring.size() >= 3:
				rings.append(current_ring)
			current_ring = [first, second]
		if current_ring.size() > 2 and (current_ring[0] as Vector2).distance_squared_to(current_ring[current_ring.size() - 1] as Vector2) <= 0.00000001:
			current_ring.pop_back()
			if current_ring.size() >= 3:
				rings.append(current_ring)
			current_ring = []
	if current_ring.size() > 2:
		if (current_ring[0] as Vector2).distance_squared_to(current_ring[current_ring.size() - 1] as Vector2) <= 0.00000001:
			current_ring.pop_back()
		if current_ring.size() >= 3:
			rings.append(current_ring)

	for ring_index in range(rings.size()):
		var ring: Array = rings[ring_index] as Array
		var sample := ring[0] as Vector2
		var nesting_depth := 0
		for other_index in range(rings.size()):
			if ring_index == other_index:
				continue
			if _building_point_in_ring(sample, rings[other_index] as Array):
				nesting_depth += 1
		# Even nesting is a solid footprint boundary; odd nesting is a hole.
		# Winding chooses the geometric interior normal, then holes invert it
		# because the building volume is outside the hole ring.
		faces = _append_building_inner_edge_ring_faces(
			faces,
			ring,
			inner_offset,
			wall_bottom_y,
			wall_top_y,
			nesting_depth % 2 == 1
		)
	return faces

func _append_building_inner_edge_ring_faces(faces: PackedVector3Array, ring: Array, inner_offset: float, wall_bottom_y: float, wall_top_y: float, is_hole: bool) -> PackedVector3Array:
	if ring.size() < 3:
		return faces
	var point_count := ring.size()
	var ring_area := 0.0
	for index in range(point_count):
		var first := ring[index] as Vector2
		var second := ring[(index + 1) % point_count] as Vector2
		ring_area += first.x * second.y - second.x * first.y
	ring_area *= 0.5
	if absf(ring_area) <= 0.00000001:
		return faces
	var edge_normals: Array = []
	for index in range(point_count):
		var first := ring[index] as Vector2
		var second := ring[(index + 1) % point_count] as Vector2
		var delta := second - first
		if delta.length_squared() <= 0.00000001:
			edge_normals.append(Vector2.ZERO)
			continue
		var left_normal := Vector2(-delta.y, delta.x).normalized()
		var geometric_interior := left_normal if ring_area > 0.0 else -left_normal
		edge_normals.append(-geometric_interior if is_hole else geometric_interior)
	var inner_points: Array = []
	for index in range(point_count):
		var previous_normal := edge_normals[(index - 1 + point_count) % point_count] as Vector2
		var following_normal := edge_normals[index] as Vector2
		var current := ring[index] as Vector2
		if previous_normal == Vector2.ZERO:
			previous_normal = following_normal
		if following_normal == Vector2.ZERO:
			following_normal = previous_normal
		var miter_sum := previous_normal + following_normal
		if miter_sum.length_squared() <= 0.00000001:
			miter_sum = following_normal
		var miter_direction := miter_sum.normalized()
		var miter_denominator := miter_direction.dot(following_normal)
		if absf(miter_denominator) < 0.05:
			miter_denominator = 1.0
		inner_points.append(current + miter_direction * (inner_offset / miter_denominator))
	for index in range(point_count):
		var next_index := (index + 1) % point_count
		var first := inner_points[index] as Vector2
		var second := inner_points[next_index] as Vector2
		var a_bottom := Vector3(first.x, wall_bottom_y, first.y)
		var b_bottom := Vector3(second.x, wall_bottom_y, second.y)
		var a_top := Vector3(first.x, wall_top_y, first.y)
		var b_top := Vector3(second.x, wall_top_y, second.y)
		faces.append_array([a_bottom, b_bottom, b_top, a_bottom, b_top, a_top])
	return faces

func _building_point_in_ring(point: Vector2, ring: Array) -> bool:
	var inside := false
	var point_count := ring.size()
	for index in range(point_count):
		var first := ring[index] as Vector2
		var second := ring[(index + 1) % point_count] as Vector2
		var crosses := (first.y > point.y) != (second.y > point.y)
		if crosses and point.x < (second.x - first.x) * (point.y - first.y) / (second.y - first.y) + first.x:
			inside = not inside
	return inside

func _runtime_cache_signature(paths: Array, feature_budget: int, edge_budget: int, lowrise_budget: int) -> Dictionary:
	var sources: Dictionary = {}
	for path_variant in paths:
		var path := str(path_variant)
		var source_record: Dictionary = {"exists": false, "size": -1, "mtime": -1}
		if FileAccess.file_exists(path):
			var source_file := FileAccess.open(path, FileAccess.READ)
			if source_file != null:
				source_record["exists"] = true
				source_record["size"] = int(source_file.get_length())
				source_file.close()
			source_record["mtime"] = int(FileAccess.get_modified_time(path))
		sources[path] = source_record
	return {
		"cache_version": RUNTIME_CACHE_VERSION,
		"preview_revision": PREVIEW_REVISION,
		"world_scale_meters_per_unit": 45.0,
		"feature_budget": feature_budget,
		"edge_budget": edge_budget,
		"lowrise_budget": lowrise_budget,
		"sources": sources
	}

func _runtime_cache_prepared_is_usable(value: Variant) -> bool:
	if not (value is Dictionary):
		return false
	var prepared := value as Dictionary
	for key in ["envelope_rings", "boundary_segments", "road_segments", "square_boundary_segments", "waterbody_segments", "building_segments", "lowrise_bounds"]:
		var collection: Variant = prepared.get(key, null)
		if not (collection is Array):
			return false
	for key in ["canonical_min_lon", "canonical_max_lon", "canonical_min_lat", "canonical_max_lat", "canonical_origin_lon", "canonical_origin_lat", "canonical_extent_units_x", "canonical_extent_units_z"]:
		if not prepared.has(key) or not is_finite(float(prepared.get(key))):
			return false
	return true

func _runtime_cache_load(paths: Array, feature_budget: int, edge_budget: int, lowrise_budget: int) -> Variant:
	set_meta("gis_runtime_cache_path", RUNTIME_CACHE_PATH)
	set_meta("gis_runtime_cache_version", RUNTIME_CACHE_VERSION)
	set_meta("gis_runtime_cache_status", "miss")
	if not FileAccess.file_exists(RUNTIME_CACHE_PATH):
		return null
	var cache_file := FileAccess.open(RUNTIME_CACHE_PATH, FileAccess.READ)
	if cache_file == null:
		set_meta("gis_runtime_cache_status", "unreadable")
		return null
	var record: Variant = cache_file.get_var(false)
	cache_file.close()
	if not (record is Dictionary):
		set_meta("gis_runtime_cache_status", "invalid_record")
		return null
	var record_dict := record as Dictionary
	var header: Variant = record_dict.get("header", null)
	var expected_header := _runtime_cache_signature(paths, feature_budget, edge_budget, lowrise_budget)
	if not (header is Dictionary) or (header as Dictionary) != expected_header:
		set_meta("gis_runtime_cache_status", "stale")
		return null
	var prepared: Variant = record_dict.get("prepared", null)
	if not _runtime_cache_prepared_is_usable(prepared):
		set_meta("gis_runtime_cache_status", "invalid_payload")
		return null
	set_meta("gis_runtime_cache_status", "hit")
	set_meta("gis_build_phase", "runtime_cache_loaded")
	return prepared

func _runtime_cache_store(prepared: Dictionary, paths: Array, feature_budget: int, edge_budget: int, lowrise_budget: int) -> void:
	if not _runtime_cache_prepared_is_usable(prepared):
		set_meta("gis_runtime_cache_status", "skip_invalid_payload")
		return
	var cache_file := FileAccess.open(RUNTIME_CACHE_PATH, FileAccess.WRITE)
	if cache_file == null:
		set_meta("gis_runtime_cache_status", "write_failed")
		return
	var record := {
		"header": _runtime_cache_signature(paths, feature_budget, edge_budget, lowrise_budget),
		"prepared": prepared.duplicate(true)
	}
	cache_file.store_var(record, false)
	cache_file.close()
	set_meta("gis_runtime_cache_status", "written")
	set_meta("gis_runtime_cache_version", RUNTIME_CACHE_VERSION)
	set_meta("gis_runtime_cache_path", RUNTIME_CACHE_PATH)

func _prepare_overlay_thread(paths: Array, feature_budget: int, edge_budget: int, lowrise_budget: int) -> Dictionary:
	# Thread contract: only FileAccess, JSON Variants, scalar math and plain Arrays.
	# No SceneTree/Node/Resource/Mesh call is allowed from this function or helpers.
	var datasets: Dictionary = {}
	for path_variant in paths:
		var path := str(path_variant)
		if not FileAccess.file_exists(path):
			return {"error": "missing local GeoJSON: %s" % path}
		var raw_source_text := FileAccess.get_file_as_string(path)
		# Local GeoJSON may carry a UTF-8 BOM or editor-introduced outer whitespace.
		# Normalize only the transport envelope; the JSON payload remains authoritative.
		var source_text := raw_source_text.trim_prefix("\uFEFF").strip_edges()
		var json_parser := JSON.new()
		var parse_error: Error = json_parser.parse(source_text)
		if parse_error != OK:
			var parse_context := source_text.substr(0, mini(source_text.length(), 160)).replace("\n", "\\n").replace("\r", "\\r")
			var source_state := "empty" if source_text.is_empty() else "non_empty"
			return {"error": "invalid JSON in %s (parser_code=%d, line=%d, message=%s, source=%s, context=%s)" % [path, parse_error, json_parser.get_error_line(), json_parser.get_error_message(), source_state, parse_context]}
		var parsed: Variant = json_parser.data
		if not (parsed is Dictionary):
			return {"error": "invalid GeoJSON object in %s (parser_code=%d, message=%s, context=%s)" % [path, parse_error, "top-level JSON value is not an object", source_text.substr(0, mini(source_text.length(), 160))]}
		var canonical := _worker_canonicalize_dataset(parsed as Dictionary)
		if canonical.is_empty():
			return {"error": "unsupported CRS or empty GeoJSON: %s" % path}
		datasets[path] = canonical
	var envelope_rings: Array = []
	_worker_collect_envelope_rings(datasets[BOUNDARY_PATH] as Dictionary, envelope_rings)
	var envelope := _worker_make_envelope(envelope_rings)
	if envelope.is_empty():
		return {"error": "boundary envelope could not be derived"}
	var result: Dictionary = {
		"envelope_rings": envelope_rings,
		"canonical_min_lon": envelope["min_lon"],
		"canonical_max_lon": envelope["max_lon"],
		"canonical_min_lat": envelope["min_lat"],
		"canonical_max_lat": envelope["max_lat"],
		"canonical_origin_lon": envelope["origin_lon"],
		"canonical_origin_lat": envelope["origin_lat"],
		"canonical_extent_units_x": envelope["extent_units_x"],
		"canonical_extent_units_z": envelope["extent_units_z"]
	}
	var boundary_segments: Array = []
	var road_segments: Array = []
	var square_boundary_segments: Array = []
	var waterbody_segments: Array = []
	var building_segments: Array = []
	_worker_collect_geometry_segments(datasets[BOUNDARY_PATH], boundary_segments, envelope, true, false)
	var road_width_meters: Array = []
	_worker_collect_road_geometry_segments(datasets[ROAD_PATH], road_segments, road_width_meters, envelope)
	_worker_collect_geometry_segments(datasets[SQUARE_BOUNDARY_PATH], square_boundary_segments, envelope, true, true)
	_worker_collect_geometry_segments(datasets[WATERBODY_PATH], waterbody_segments, envelope, true, true)
	var building_state := {"features": 0}
	_worker_collect_building_segments(datasets[BUILDING_PATH], building_segments, envelope, edge_budget, feature_budget, building_state)
	var lowrise_bounds: Array = []
	_worker_collect_lowrise_bounds(datasets[BUILDING_PATH], lowrise_bounds, envelope, lowrise_budget)
	result["boundary_segments"] = boundary_segments
	result["road_segments"] = road_segments
	result["road_width_meters"] = road_width_meters
	result["square_boundary_segments"] = square_boundary_segments
	result["waterbody_segments"] = waterbody_segments
	result["building_segments"] = building_segments
	result["building_features_drawn"] = int(building_state.get("drawn", 0))
	result["lowrise_bounds"] = lowrise_bounds
	return result

func _worker_canonicalize_dataset(data: Dictionary) -> Dictionary:
	var crs: Dictionary = data.get("crs", {}) as Dictionary
	var properties: Dictionary = crs.get("properties", {}) as Dictionary
	var crs_name := str(properties.get("name", "")).to_upper()
	if crs_name.is_empty() or crs_name.contains("CRS84") or crs_name.contains("4326"):
		return data
	if crs_name.contains("26985"):
		_worker_convert_coordinates(data)
		data["crs"] = {"type": "name", "properties": {"name": "urn:ogc:def:crs:OGC:1.3:CRS84"}}
		return data
	return {}

func _worker_convert_coordinates(data: Dictionary) -> void:
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if feature is Dictionary:
				_worker_convert_coordinates(feature as Dictionary)
	elif data.get("type", "") == "Feature":
		var geometry: Dictionary = data.get("geometry", {}) as Dictionary
		_worker_convert_coordinates(geometry)
		data["geometry"] = geometry
	elif data.has("coordinates"):
		data["coordinates"] = _worker_convert_coordinate_tree(data.get("coordinates", []))

func _worker_convert_coordinate_tree(value: Variant) -> Variant:
	if not (value is Array):
		return value
	var values := value as Array
	if values.size() >= 2 and (values[0] is int or values[0] is float) and (values[1] is int or values[1] is float):
		var lon_lat := _maryland_state_plane_to_crs84(float(values[0]), float(values[1]))
		var coordinate := values.duplicate()
		coordinate[0] = lon_lat.x
		coordinate[1] = lon_lat.y
		return coordinate
	var converted: Array = []
	for child in values:
		converted.append(_worker_convert_coordinate_tree(child))
	return converted

func _worker_collect_envelope_rings(data: Dictionary, output: Array) -> void:
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if feature is Dictionary:
				_worker_collect_envelope_geometry((feature as Dictionary).get("geometry", {}), output)
	elif data.get("type", "") == "Feature":
		_worker_collect_envelope_geometry(data.get("geometry", {}), output)
	else:
		_worker_collect_envelope_geometry(data, output)

func _worker_collect_envelope_geometry(geometry: Variant, output: Array) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	match geometry_dict.get("type", ""):
		"Polygon":
			for ring in geometry_dict.get("coordinates", []) as Array:
				output.append(ring)
		"MultiPolygon":
			for polygon in geometry_dict.get("coordinates", []) as Array:
				for ring in polygon as Array:
					output.append(ring)

func _worker_make_envelope(rings: Array) -> Dictionary:
	if rings.is_empty():
		return {}
	var min_lon: float = INF
	var max_lon: float = -INF
	var min_lat: float = INF
	var max_lat: float = -INF
	for ring in rings:
		for point in ring as Array:
			if not (point is Array) or (point as Array).size() < 2:
				continue
			min_lon = minf(min_lon, float((point as Array)[0]))
			max_lon = maxf(max_lon, float((point as Array)[0]))
			min_lat = minf(min_lat, float((point as Array)[1]))
			max_lat = maxf(max_lat, float((point as Array)[1]))
	if not is_finite(min_lon) or not is_finite(min_lat):
		return {}
	return {
		"rings": rings,
		"min_lon": min_lon,
		"max_lon": max_lon,
		"min_lat": min_lat,
		"max_lat": max_lat,
		"origin_lon": (min_lon + max_lon) * 0.5,
		"origin_lat": (min_lat + max_lat) * 0.5,
		"extent_units_x": ((max_lon - min_lon) * METERS_PER_DEG_LON) / WorldScale.METERS_PER_UNIT,
		"extent_units_z": ((max_lat - min_lat) * METERS_PER_DEG_LAT) / WorldScale.METERS_PER_UNIT
	}

func _worker_geo_to_canvas(point: Variant, envelope: Dictionary) -> Array:
	if not (point is Array) or (point as Array).size() < 2:
		return [0.0, 0.0]
	var longitude := float((point as Array)[0])
	var latitude := float((point as Array)[1])
	var uniform_fit := minf(MAP_ANCHOR_EXTENT / maxf(float(envelope["extent_units_x"]), 0.001), MAP_ANCHOR_EXTENT / maxf(float(envelope["extent_units_z"]), 0.001))
	var east_units := ((longitude - float(envelope["origin_lon"])) * METERS_PER_DEG_LON) / WorldScale.METERS_PER_UNIT
	var south_units := -((latitude - float(envelope["origin_lat"])) * METERS_PER_DEG_LAT) / WorldScale.METERS_PER_UNIT
	return [MAP_ANCHOR_CENTER.x + east_units * uniform_fit, MAP_ANCHOR_CENTER.y + south_units * uniform_fit]

func _worker_point_in_envelope(point: Variant, rings: Array) -> bool:
	if not (point is Array) or (point as Array).size() < 2:
		return false
	var p := Vector2(float((point as Array)[0]), float((point as Array)[1]))
	for ring in rings:
		var inside := false
		var ring_points := ring as Array
		for index in range(ring_points.size() - 1):
			var a := Vector2(float((ring_points[index] as Array)[0]), float((ring_points[index] as Array)[1]))
			var b := Vector2(float((ring_points[index + 1] as Array)[0]), float((ring_points[index + 1] as Array)[1]))
			if ((a.y > p.y) != (b.y > p.y)) and p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x:
				inside = not inside
		if inside:
			return true
	return false

func _worker_road_width_meters(feature: Dictionary) -> float:
	var properties: Variant = feature.get("properties", {})
	if not (properties is Dictionary):
		return ROAD_WIDTH_FALLBACK_M
	var raw_value: Variant = (properties as Dictionary).get("TOTALTRAVELLANEWIDTH", null)
	var feet := 0.0
	if raw_value is int or raw_value is float:
		feet = float(raw_value)
	elif raw_value is String and not (raw_value as String).strip_edges().is_empty():
		feet = float((raw_value as String).strip_edges())
	if not is_finite(feet) or feet <= 0.0:
		return ROAD_WIDTH_FALLBACK_M
	# User-confirmed unit: TOTALTRAVELLANEWIDTH is feet. Convert ft -> metres here;
	# the visual path applies WorldScale.meters_to_units() below.
	return feet * 0.3048

func _worker_collect_road_geometry_segments(data: Dictionary, output: Array, widths_meters: Array, envelope: Dictionary) -> void:
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if feature is Dictionary:
				var before := output.size()
				_worker_collect_geometry((feature as Dictionary).get("geometry", {}), output, envelope, false, true)
				for _index in range(before, output.size()):
					widths_meters.append(_worker_road_width_meters(feature as Dictionary))
	elif data.get("type", "") == "Feature":
		var feature := data as Dictionary
		var before := output.size()
		_worker_collect_geometry(feature.get("geometry", {}), output, envelope, false, true)
		for _index in range(before, output.size()):
			widths_meters.append(_worker_road_width_meters(feature))
	else:
		var before := output.size()
		_worker_collect_geometry(data, output, envelope, false, true)
		for _index in range(before, output.size()):
			widths_meters.append(ROAD_WIDTH_FALLBACK_M)

func _worker_collect_geometry_segments(data: Dictionary, output: Array, envelope: Dictionary, close_rings: bool, clip_to_envelope: bool) -> void:
	var geometry_state := {"features": 0}
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if feature is Dictionary:
				_worker_collect_geometry((feature as Dictionary).get("geometry", {}), output, envelope, close_rings, clip_to_envelope)
	elif data.get("type", "") == "Feature":
		_worker_collect_geometry(data.get("geometry", {}), output, envelope, close_rings, clip_to_envelope)
	else:
		_worker_collect_geometry(data, output, envelope, close_rings, clip_to_envelope)

func _worker_collect_geometry(geometry: Variant, output: Array, envelope: Dictionary, close_rings: bool, clip_to_envelope: bool) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	var geometry_type: String = geometry_dict.get("type", "")
	var coordinates: Variant = geometry_dict.get("coordinates", [])
	match geometry_type:
		"LineString":
			_worker_add_line(coordinates, output, envelope, close_rings, clip_to_envelope, -1)
		"MultiLineString":
			for line in coordinates as Array:
				_worker_add_line(line, output, envelope, false, clip_to_envelope, -1)
		"Polygon":
			for ring in coordinates as Array:
				_worker_add_line(ring, output, envelope, close_rings, clip_to_envelope, -1)
		"MultiPolygon":
			for polygon in coordinates as Array:
				for ring in polygon as Array:
					_worker_add_line(ring, output, envelope, close_rings, clip_to_envelope, -1)

func _worker_add_line(points: Variant, output: Array, envelope: Dictionary, close_ring: bool, clip_to_envelope: bool, edge_budget: int) -> void:
	if not (points is Array):
		return
	var point_array := points as Array
	if point_array.size() < 2:
		return
	var envelope_rings: Array = []
	var rings_variant: Variant = envelope.get("rings", null)
	if rings_variant is Array:
		envelope_rings = rings_variant as Array
	for index in range(point_array.size() - 1):
		if edge_budget >= 0 and output.size() >= edge_budget:
			return
		var first_geo: Variant = point_array[index]
		var second_geo: Variant = point_array[index + 1]
		if clip_to_envelope and not envelope_rings.is_empty() and (not _worker_point_in_envelope(first_geo, envelope_rings) or not _worker_point_in_envelope(second_geo, envelope_rings)):
			continue
		var first := _worker_geo_to_canvas(first_geo, envelope)
		var second := _worker_geo_to_canvas(second_geo, envelope)
		if Vector2(first[0], first[1]).distance_to(Vector2(second[0], second[1])) > 0.0001:
			output.append([first[0], first[1], second[0], second[1]])
	if close_ring and (edge_budget < 0 or output.size() < edge_budget):
		var closing_first_geo: Variant = point_array[point_array.size() - 1]
		var closing_second_geo: Variant = point_array[0]
		if not clip_to_envelope or (_worker_point_in_envelope(closing_first_geo, envelope["rings"]) and _worker_point_in_envelope(closing_second_geo, envelope["rings"])):
			var closing_first := _worker_geo_to_canvas(closing_first_geo, envelope)
			var closing_second := _worker_geo_to_canvas(closing_second_geo, envelope)
			if Vector2(closing_first[0], closing_first[1]).distance_to(Vector2(closing_second[0], closing_second[1])) > 0.0001:
				output.append([closing_first[0], closing_first[1], closing_second[0], closing_second[1]])

func _worker_collect_building_segments(data: Dictionary, output: Array, envelope: Dictionary, edge_budget: int, feature_budget: int, state: Dictionary) -> void:
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if int(state.get("drawn", 0)) >= feature_budget or output.size() >= edge_budget:
				break
			if feature is Dictionary:
				var before := output.size()
				_worker_collect_building_geometry((feature as Dictionary).get("geometry", {}), output, envelope, edge_budget)
				if output.size() > before:
					state["drawn"] = int(state.get("drawn", 0)) + 1
	elif data.get("type", "") == "Feature":
		_worker_collect_building_geometry(data.get("geometry", {}), output, envelope, edge_budget)
		if not output.is_empty():
			state["drawn"] = 1
	else:
		_worker_collect_building_geometry(data, output, envelope, edge_budget)
		if not output.is_empty():
			state["drawn"] = 1

func _worker_collect_building_geometry(geometry: Variant, output: Array, envelope: Dictionary, edge_budget: int) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	var geometry_type: String = geometry_dict.get("type", "")
	var coordinates: Variant = geometry_dict.get("coordinates", [])
	match geometry_type:
		"Polygon":
			for ring in coordinates as Array:
				_worker_add_line(ring, output, envelope, true, true, edge_budget)
				if output.size() >= edge_budget:
					return
		"MultiPolygon":
			for polygon in coordinates as Array:
				for ring in polygon as Array:
					_worker_add_line(ring, output, envelope, true, true, edge_budget)
					if output.size() >= edge_budget:
						return

func _worker_collect_lowrise_bounds(data: Dictionary, output: Array, envelope: Dictionary, budget: int) -> void:
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if output.size() >= budget:
				return
			if feature is Dictionary:
				_worker_collect_lowrise_geometry((feature as Dictionary).get("geometry", {}), output, envelope, budget)
	elif data.get("type", "") == "Feature":
		_worker_collect_lowrise_geometry(data.get("geometry", {}), output, envelope, budget)
	else:
		_worker_collect_lowrise_geometry(data, output, envelope, budget)

func _worker_collect_lowrise_geometry(geometry: Variant, output: Array, envelope: Dictionary, budget: int) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	var geometry_type: String = geometry_dict.get("type", "")
	var coordinates: Variant = geometry_dict.get("coordinates", [])
	match geometry_type:
		"Polygon":
			if coordinates is Array and not (coordinates as Array).is_empty():
				_worker_append_lowrise_bound((coordinates as Array)[0], output, envelope, budget)
		"MultiPolygon":
			for polygon in coordinates as Array:
				if output.size() >= budget:
					return
				if polygon is Array and not (polygon as Array).is_empty():
					_worker_append_lowrise_bound((polygon as Array)[0], output, envelope, budget)

func _worker_append_lowrise_bound(points: Variant, output: Array, envelope: Dictionary, budget: int) -> void:
	if output.size() >= budget or not (points is Array) or (points as Array).size() < 3:
		return
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var has_inside_point := false
	for point in points as Array:
		if not (point is Array) or (point as Array).size() < 2 or not _worker_point_in_envelope(point, envelope["rings"]):
			continue
		var canvas_point := _worker_geo_to_canvas(point, envelope)
		min_x = minf(min_x, float(canvas_point[0]))
		min_y = minf(min_y, float(canvas_point[1]))
		max_x = maxf(max_x, float(canvas_point[0]))
		max_y = maxf(max_y, float(canvas_point[1]))
		has_inside_point = true
	if has_inside_point and max_x > min_x and max_y > min_y:
		output.append([min_x, min_y, max_x - min_x, max_y - min_y])

func _set_worker_envelope(prepared: Dictionary) -> void:
	_canonical_envelope_rings = prepared.get("envelope_rings", []) as Array
	_canonical_min_lon = float(prepared.get("canonical_min_lon", MIN_LON))
	_canonical_max_lon = float(prepared.get("canonical_max_lon", MAX_LON))
	_canonical_min_lat = float(prepared.get("canonical_min_lat", MIN_LAT))
	_canonical_max_lat = float(prepared.get("canonical_max_lat", MAX_LAT))
	_canonical_origin_lon = float(prepared.get("canonical_origin_lon", GIS_ORIGIN_LON))
	_canonical_origin_lat = float(prepared.get("canonical_origin_lat", GIS_ORIGIN_LAT))
	_canonical_extent_units_x = float(prepared.get("canonical_extent_units_x", GIS_EXTENT_UNITS_X))
	_canonical_extent_units_z = float(prepared.get("canonical_extent_units_z", GIS_EXTENT_UNITS_Z))
	_canonical_crs = "CRS84"

func _segments_from_worker(value: Variant) -> Array[Vector4]:
	var output: Array[Vector4] = []
	if not (value is Array):
		return output
	for segment in value as Array:
		if segment is Array and (segment as Array).size() >= 4:
			var values := segment as Array
			output.append(Vector4(float(values[0]), float(values[1]), float(values[2]), float(values[3])))
	return output

func _bounds_from_worker(value: Variant) -> Array[Rect2]:
	var output: Array[Rect2] = []
	if not (value is Array):
		return output
	for bound in value as Array:
		if bound is Array and (bound as Array).size() >= 4:
			var values := bound as Array
			output.append(Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3])))
	return output

func _parse_geojson_thread(path: String) -> Variant:
	# This worker touches only local file bytes and a plain JSON Variant. It never
	# accesses SceneTree, Nodes, Meshes, Materials, or other Godot scene resources.
	if not FileAccess.file_exists(path):
		return {}
	var raw := FileAccess.get_file_as_string(path)
	# Match the BOM/whitespace normalization used by _prepare_overlay_thread.
	return JSON.parse_string(raw.trim_prefix("\uFEFF").strip_edges())

func _read_geojson(path: String, build_generation: int) -> Dictionary:
	if _geojson_cache.has(path):
		return _geojson_cache[path] as Dictionary
	if not FileAccess.file_exists(path):
		if not Engine.is_editor_hint():
			push_error("[GISOverlay] Missing local GeoJSON: %s" % path)
		_geojson_cache[path] = {}
		return {}
	var parse_thread := Thread.new()
	var start_error: Error = parse_thread.start(Callable(self, "_parse_geojson_thread").bind(path))
	if start_error != OK:
		# Keep a safe fallback for platforms where a worker cannot be started.
		var fallback_raw := FileAccess.get_file_as_string(path)
		var fallback: Variant = JSON.parse_string(fallback_raw.trim_prefix("\uFEFF").strip_edges())
		if not (fallback is Dictionary):
			push_error("[GISOverlay] Invalid GeoJSON object: %s" % path)
			_geojson_cache[path] = {}
			return {}
		var fallback_data := fallback as Dictionary
		_geojson_cache[path] = fallback_data
		return fallback_data
	while parse_thread.is_alive():
		await get_tree().process_frame
	var parsed: Variant = parse_thread.wait_to_finish()
	if not _build_is_current(build_generation):
		return {}
	if not (parsed is Dictionary):
		push_error("[GISOverlay] Invalid GeoJSON object: %s" % path)
		_geojson_cache[path] = {}
		return {}
	var data := parsed as Dictionary
	_geojson_cache[path] = data
	return data

func _collect_geometry_segments(data: Dictionary, output: Array[Vector4], close_rings: bool, clip_to_envelope: bool, build_generation: int) -> void:
	var state := {"work": 0}
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if feature is Dictionary:
				await _process_geometry((feature as Dictionary).get("geometry", {}), output, close_rings, clip_to_envelope, state, build_generation)
				if not _build_is_current(build_generation):
					return
	elif data.get("type", "") == "Feature":
		await _process_geometry(data.get("geometry", {}), output, close_rings, clip_to_envelope, state, build_generation)
	else:
		await _process_geometry(data, output, close_rings, clip_to_envelope, state, build_generation)

func _process_geometry(geometry: Variant, output: Array[Vector4], close_rings: bool, clip_to_envelope: bool, state: Dictionary, build_generation: int) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	var geometry_type: String = geometry_dict.get("type", "")
	var coordinates: Variant = geometry_dict.get("coordinates", [])
	match geometry_type:
		"LineString":
			await _add_line(coordinates, output, false, -1, clip_to_envelope, state, build_generation)
		"MultiLineString":
			for line in coordinates as Array:
				await _add_line(line, output, false, -1, clip_to_envelope, state, build_generation)
		"Polygon":
			for ring in coordinates as Array:
				await _add_line(ring, output, close_rings, -1, clip_to_envelope, state, build_generation)
		"MultiPolygon":
			for polygon in coordinates as Array:
				for ring in polygon as Array:
					await _add_line(ring, output, close_rings, -1, clip_to_envelope, state, build_generation)

func _add_line(points: Variant, output: Array[Vector4], close_ring: bool, edge_budget: int = -1, clip_to_envelope: bool = false, state: Dictionary = {}, build_generation: int = -1) -> void:
	if not (points is Array):
		return
	var point_array := points as Array
	if point_array.size() < 2:
		return
	for index in range(point_array.size() - 1):
		if edge_budget >= 0 and output.size() >= edge_budget:
			return
		var first_geo: Variant = point_array[index]
		var second_geo: Variant = point_array[index + 1]
		if clip_to_envelope and not _geo_segment_is_inside_envelope(first_geo, second_geo):
			continue
		var first := _geo_to_canvas(first_geo)
		var second := _geo_to_canvas(second_geo)
		if first.distance_to(second) > 0.0001:
			output.append(Vector4(first.x, first.y, second.x, second.y))
		state["work"] = int(state.get("work", 0)) + 1
		if int(state["work"]) >= GEOMETRY_VERTEX_CHUNK:
			state["work"] = 0
			await get_tree().process_frame
			if build_generation >= 0 and not _build_is_current(build_generation):
				return
	if close_ring and (edge_budget < 0 or output.size() < edge_budget):
		var closing_first_geo: Variant = point_array[point_array.size() - 1]
		var closing_second_geo: Variant = point_array[0]
		if not clip_to_envelope or _geo_segment_is_inside_envelope(closing_first_geo, closing_second_geo):
			var closing_first := _geo_to_canvas(closing_first_geo)
			var closing_second := _geo_to_canvas(closing_second_geo)
			if closing_first.distance_to(closing_second) > 0.0001:
				output.append(Vector4(closing_first.x, closing_first.y, closing_second.x, closing_second.y))

func _meters_to_canvas_width(meters: float) -> float:
	# Longitude/latitude coordinates are first converted to canonical metres, then
	# uniformly fitted to the shared Sector 1 envelope. The line width follows both.
	var uniform_fit := minf(
		MAP_ANCHOR_EXTENT / maxf(_canonical_extent_units_x, 0.001),
		MAP_ANCHOR_EXTENT / maxf(_canonical_extent_units_z, 0.001)
	)
	return WorldScale.meters_to_units(meters) * uniform_fit

func _geo_to_canvas(point: Variant) -> Vector2:
	if not (point is Array) or (point as Array).size() < 2:
		return Vector2.ZERO
	var coords := point as Array
	# Every layer is already in canonical CRS84 and uses the Sector 1 frame.
	# There is intentionally no per-layer normalization and no visual clamp here;
	# out-of-envelope source geometry is rejected before this conversion.
	var longitude := float(coords[0])
	var latitude := float(coords[1])
	var east_units := ((longitude - _canonical_origin_lon) * METERS_PER_DEG_LON) / WorldScale.METERS_PER_UNIT
	var south_units := -((latitude - _canonical_origin_lat) * METERS_PER_DEG_LAT) / WorldScale.METERS_PER_UNIT
	var uniform_fit := minf(
		MAP_ANCHOR_EXTENT / maxf(_canonical_extent_units_x, 0.001),
		MAP_ANCHOR_EXTENT / maxf(_canonical_extent_units_z, 0.001)
	)
	return MAP_ANCHOR_CENTER + Vector2(east_units, south_units) * uniform_fit

func _set_canonical_envelope(data: Dictionary) -> bool:
	_canonical_envelope_rings.clear()
	_collect_envelope_rings(data, _canonical_envelope_rings)
	if _canonical_envelope_rings.is_empty():
		return false
	_canonical_min_lon = INF
	_canonical_max_lon = -INF
	_canonical_min_lat = INF
	_canonical_max_lat = -INF
	for ring in _canonical_envelope_rings:
		for point in ring as Array:
			if not (point is Array) or (point as Array).size() < 2:
				continue
			_canonical_min_lon = minf(_canonical_min_lon, float((point as Array)[0]))
			_canonical_max_lon = maxf(_canonical_max_lon, float((point as Array)[0]))
			_canonical_min_lat = minf(_canonical_min_lat, float((point as Array)[1]))
			_canonical_max_lat = maxf(_canonical_max_lat, float((point as Array)[1]))
	if not is_finite(_canonical_min_lon) or not is_finite(_canonical_min_lat):
		return false
	_canonical_origin_lon = (_canonical_min_lon + _canonical_max_lon) * 0.5
	_canonical_origin_lat = (_canonical_min_lat + _canonical_max_lat) * 0.5
	_canonical_extent_units_x = ((_canonical_max_lon - _canonical_min_lon) * METERS_PER_DEG_LON) / WorldScale.METERS_PER_UNIT
	_canonical_extent_units_z = ((_canonical_max_lat - _canonical_min_lat) * METERS_PER_DEG_LAT) / WorldScale.METERS_PER_UNIT
	return true

func _collect_envelope_rings(data: Dictionary, output: Array) -> void:
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if feature is Dictionary:
				_collect_envelope_geometry((feature as Dictionary).get("geometry", {}), output)
	elif data.get("type", "") == "Feature":
		_collect_envelope_geometry(data.get("geometry", {}), output)
	else:
		_collect_envelope_geometry(data, output)

func _collect_envelope_geometry(geometry: Variant, output: Array) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	match geometry_dict.get("type", ""):
		"Polygon":
			for ring in geometry_dict.get("coordinates", []) as Array:
				output.append(ring)
		"MultiPolygon":
			for polygon in geometry_dict.get("coordinates", []) as Array:
				for ring in polygon as Array:
					output.append(ring)

func _canonicalize_dataset_to_crs84(data: Dictionary, path: String, build_generation: int) -> Dictionary:
	if data.is_empty():
		return {}
	var crs: Dictionary = data.get("crs", {}) as Dictionary
	var properties: Dictionary = crs.get("properties", {}) as Dictionary
	var crs_name := str(properties.get("name", "")).to_upper()
	if crs_name.is_empty() or crs_name.contains("CRS84") or crs_name.contains("4326"):
		return data
	if crs_name.contains("26985"):
		# Convert the cached plain-data tree in bounded vertex chunks. No scene
		# resource is touched here, and the CRS tag makes a retry idempotent.
		var state := {"work": 0}
		await _convert_geojson_coordinates(data, "EPSG:26985", state, build_generation)
		if not _build_is_current(build_generation):
			return {}
		data["crs"] = {"type": "name", "properties": {"name": "urn:ogc:def:crs:OGC:1.3:CRS84"}}
		return data
	push_error("[GISOverlay] Unsupported CRS in %s: %s" % [path, crs_name])
	return {}

func _convert_geojson_coordinates(data: Dictionary, source_crs: String, state: Dictionary, build_generation: int) -> void:
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if feature is Dictionary:
				await _convert_geojson_coordinates(feature as Dictionary, source_crs, state, build_generation)
				if not _build_is_current(build_generation):
					return
	elif data.get("type", "") == "Feature":
		var geometry := data.get("geometry", {}) as Dictionary
		await _convert_geojson_coordinates(geometry, source_crs, state, build_generation)
		data["geometry"] = geometry
	elif data.has("coordinates"):
		data["coordinates"] = await _convert_coordinate_tree(data.get("coordinates", []), source_crs, state, build_generation)

func _convert_coordinate_tree(value: Variant, source_crs: String, state: Dictionary, build_generation: int) -> Variant:
	if not (value is Array):
		return value
	var values := value as Array
	if values.size() >= 2 and (values[0] is float or values[0] is int) and (values[1] is float or values[1] is int):
		if source_crs == "EPSG:26985":
			var lon_lat := _maryland_state_plane_to_crs84(float(values[0]), float(values[1]))
			var coordinate := values.duplicate()
			coordinate[0] = lon_lat.x
			coordinate[1] = lon_lat.y
			state["work"] = int(state.get("work", 0)) + 1
			if int(state["work"]) >= CANONICAL_VERTEX_CHUNK:
				state["work"] = 0
				await get_tree().process_frame
				if not _build_is_current(build_generation):
					return []
			return coordinate
	var converted: Array = []
	for child in values:
		converted.append(await _convert_coordinate_tree(child, source_crs, state, build_generation))
	return converted

func _maryland_state_plane_to_crs84(easting: float, northing: float) -> Vector2:
	# EPSG:26985 is NAD83 / Maryland (meters), the footprint source CRS.
	# Inverse Lambert Conformal Conic 2SP -> WGS84/CRS84; datum shift is below
	# the source precision for this visual overlay and is intentionally not applied.
	var semi_major := 6378137.0
	var flattening := 1.0 / 298.257222101
	var eccentricity := sqrt(flattening * (2.0 - flattening))
	var latitude_1 := deg_to_rad(38.3)
	var latitude_2 := deg_to_rad(39.45)
	var latitude_0 := deg_to_rad(37.6666666666667)
	var longitude_0 := deg_to_rad(-77.0)
	var false_easting := 400000.0
	var false_northing := 0.0
	var m1 := _lcc_m(latitude_1, eccentricity)
	var m2 := _lcc_m(latitude_2, eccentricity)
	var t1 := _lcc_t(latitude_1, eccentricity)
	var t2 := _lcc_t(latitude_2, eccentricity)
	var n := log(m1 / m2) / log(t1 / t2)
	var conformal_factor := m1 / (n * pow(t1, n))
	var t0 := _lcc_t(latitude_0, eccentricity)
	var rho0 := semi_major * conformal_factor * pow(t0, n)
	var x := easting - false_easting
	var y := northing - false_northing
	var rho: float = float(sign(n)) * sqrt(x * x + (rho0 - y) * (rho0 - y))
	var theta := atan2(x, rho0 - y) / n
	var t := pow(rho / (semi_major * conformal_factor), 1.0 / n)
	var latitude := PI * 0.5 - 2.0 * atan(t)
	for _iteration in range(8):
		var sine := sin(latitude)
		latitude = PI * 0.5 - 2.0 * atan(t * pow((1.0 - eccentricity * sine) / (1.0 + eccentricity * sine), eccentricity * 0.5))
	return Vector2(rad_to_deg(longitude_0 + theta), rad_to_deg(latitude))

func _lcc_m(latitude: float, eccentricity: float) -> float:
	return cos(latitude) / sqrt(1.0 - eccentricity * eccentricity * sin(latitude) * sin(latitude))

func _lcc_t(latitude: float, eccentricity: float) -> float:
	return tan(PI * 0.25 - latitude * 0.5) / pow((1.0 - eccentricity * sin(latitude)) / (1.0 + eccentricity * sin(latitude)), eccentricity * 0.5)

func _geo_point_in_envelope(point: Variant) -> bool:
	if not (point is Array) or (point as Array).size() < 2:
		return false
	var p := Vector2(float((point as Array)[0]), float((point as Array)[1]))
	for ring in _canonical_envelope_rings:
		var inside := false
		var ring_points := ring as Array
		for index in range(ring_points.size() - 1):
			var a := Vector2(float((ring_points[index] as Array)[0]), float((ring_points[index] as Array)[1]))
			var b := Vector2(float((ring_points[index + 1] as Array)[0]), float((ring_points[index + 1] as Array)[1]))
			if ((a.y > p.y) != (b.y > p.y)) and p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x:
				inside = not inside
		if inside:
			return true
	return false

func _geo_orientation(p: Vector2, q: Vector2, r: Vector2) -> float:
	return (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x)

func _geo_segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var o1 := _geo_orientation(a, b, c)
	var o2 := _geo_orientation(a, b, d)
	var o3 := _geo_orientation(c, d, a)
	var o4 := _geo_orientation(c, d, b)
	return ((o1 >= 0.0 and o2 <= 0.0) or (o1 <= 0.0 and o2 >= 0.0)) and ((o3 >= 0.0 and o4 <= 0.0) or (o3 <= 0.0 and o4 >= 0.0))

func _geo_segment_is_inside_envelope(first: Variant, second: Variant) -> bool:
	return _geo_point_in_envelope(first) and _geo_point_in_envelope(second)

func _geo_segment_overlaps_envelope(first: Variant, second: Variant) -> bool:
	if not (first is Array) or not (second is Array):
		return false
	if _geo_point_in_envelope(first) or _geo_point_in_envelope(second):
		return true
	var a := Vector2(float((first as Array)[0]), float((first as Array)[1]))
	var b := Vector2(float((second as Array)[0]), float((second as Array)[1]))
	for ring in _canonical_envelope_rings:
		var ring_points := ring as Array
		for index in range(ring_points.size() - 1):
			var c := Vector2(float((ring_points[index] as Array)[0]), float((ring_points[index] as Array)[1]))
			var d := Vector2(float((ring_points[index + 1] as Array)[0]), float((ring_points[index + 1] as Array)[1]))
			if _geo_segments_intersect(a, b, c, d):
				return true
	return false

func _build_variable_width_strip_mesh(segments: Array[Vector4], widths_meters: Array, y: float, build_generation: int) -> ArrayMesh:
	# Keep one Sector1RoadwayOverlay node while allowing each GIS feature its own width.
	# Grouping preserves the existing batched mesh path and avoids one node per feature.
	var grouped: Dictionary = {}
	for index in range(segments.size()):
		var width_m := ROAD_WIDTH_FALLBACK_M
		if index < widths_meters.size():
			var candidate := float(widths_meters[index])
			if is_finite(candidate) and candidate > 0.0:
				width_m = candidate
		var key := "%.6f" % width_m
		if not grouped.has(key):
			grouped[key] = {"width_m": width_m, "segments": []}
		(grouped[key]["segments"] as Array).append(segments[index])
	var combined := ArrayMesh.new()
	for entry in grouped.values():
		var group_segments: Array[Vector4] = []
		for value in entry["segments"] as Array:
			group_segments.append(value as Vector4)
		var piece := await _build_strip_mesh(group_segments, _meters_to_canvas_width(float(entry["width_m"])), y, build_generation)
		if not _build_is_current(build_generation):
			return null
		if piece == null:
			continue
		for surface_index in range(piece.get_surface_count()):
			combined.add_surface_from_arrays(piece.surface_get_primitive_type(surface_index), piece.surface_get_arrays(surface_index))
	return combined if combined.get_surface_count() > 0 else null

## Groups a flat segment array into connected polyline chains so each chain
## shares vertices and produces continuous mitered strip geometry.
func _group_segments_into_chains(segments: Array[Vector4]) -> Array[Array]:
	var chains: Array[Array] = []
	var current_chain: Array[Vector2] = []
	for seg in segments:
		var start := Vector2(seg.x, seg.y)
		var finish := Vector2(seg.z, seg.w)
		var delta := finish - start
		if delta.length_squared() < 0.000001:
			continue
		if current_chain.is_empty():
			current_chain.append(start)
			current_chain.append(finish)
		elif (current_chain[current_chain.size() - 1] as Vector2).distance_squared_to(start) < 0.000001:
			current_chain.append(finish)
		else:
			if current_chain.size() >= 2:
				chains.append(current_chain)
			current_chain = [start, finish]
	if current_chain.size() >= 2:
		chains.append(current_chain)
	return chains


func _build_strip_mesh(segments: Array[Vector4], width: float, y: float, build_generation: int) -> ArrayMesh:
	if segments.is_empty():
		return null

	var half_width := width * 0.5
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()

	# Step 1: Group segments into connected chains.
	# Segments within a GIS ring are emitted sequentially; between rings
	# the endpoint does not match the next start so we get chain breaks.
	var chains: Array[Array] = _group_segments_into_chains(segments)
	if chains.is_empty():
		return null

	var chain_processed := 0
	for chain in chains:
		var points := chain as Array[Vector2]
		if points.size() < 2:
			continue

		# Detect closed chain (first point equals last point).
		var is_closed := (points[0] as Vector2).distance_squared_to(points[points.size() - 1] as Vector2) < 0.000001
		# Remove duplicate last point from working set for closed chains.
		var working: Array[Vector2] = points.duplicate()
		if is_closed:
			working.pop_back()

		var n := working.size()
		if n < 2:
			continue

		var base := vertices.size()

		# Compute a mitered pair of vertices for every chain point.
		for i in range(n):
			var prev_dir: Vector2
			var next_dir: Vector2
			var point := working[i] as Vector2

			if is_closed:
				# Every vertex is an interior corner; wrap around.
				var prev_idx := (i - 1 + n) % n
				var next_idx := (i + 1) % n
				prev_dir = (point - working[prev_idx] as Vector2).normalized()
				next_dir = (working[next_idx] as Vector2 - point).normalized()
			else:
				if i == 0:
					next_dir = (working[i + 1] as Vector2 - point).normalized()
					prev_dir = next_dir
				elif i == n - 1:
					prev_dir = (point - working[i - 1] as Vector2).normalized()
					next_dir = prev_dir
				else:
					prev_dir = (point - working[i - 1] as Vector2).normalized()
					next_dir = (working[i + 1] as Vector2 - point).normalized()

			if prev_dir.length_squared() < 0.000001:
				prev_dir = next_dir
			if next_dir.length_squared() < 0.000001:
				next_dir = prev_dir

			# Left normals (perpendicular, CCW).
			var prev_left := Vector2(-prev_dir.y, prev_dir.x)
			var next_left := Vector2(-next_dir.y, next_dir.x)

			# Miter intersection of the two strip-edge lines.
			var miter_sum := prev_left + next_left
			if miter_sum.length_squared() < 0.000001:
				miter_sum = prev_left  # 180-degree fallback
			var miter_dir := miter_sum.normalized()
			var miter_denom := miter_dir.dot(next_left)
			# Guard against near-zero denominator on near-180 degree angles
			# while clamping the miter length to avoid extreme spikes.
			var miter_len := half_width / maxf(absf(miter_denom), 0.0005)
			miter_len = minf(miter_len, half_width * 3.0)

			var offset := miter_dir * miter_len
			vertices.append(Vector3(point.x + offset.x, y, point.y + offset.y))
			vertices.append(Vector3(point.x - offset.x, y, point.y - offset.y))

		# Create triangle indices connecting adjacent vertex pairs.
		for i in range(n):
			var j := i + 1
			if is_closed:
				j = (i + 1) % n
			elif i == n - 1:
				break  # Last segment of open chain already covered.

			var vi := base + i * 2
			var vj := base + j * 2
			indices.append(vi)       # left_i
			indices.append(vi + 1)   # right_i
			indices.append(vj + 1)   # right_j
			indices.append(vi)       # left_i
			indices.append(vj + 1)   # right_j
			indices.append(vj)       # left_j

		chain_processed += 1
		if chain_processed >= MESH_SEGMENT_CHUNK:
			chain_processed = 0
			await get_tree().process_frame
			if not _build_is_current(build_generation):
				return null

	if vertices.is_empty():
		return null

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## One-shot editor coroutine that regenerates all five baked line-overlay .res
## files from the local GeoJSON sources using the current strip builder.
## Called via call_deferred when regenerate_baked_line_meshes is set true.
func _regenerate_line_meshes_deferred() -> void:
	if not Engine.is_editor_hint():
		_bake_in_progress = false
		return

	var scene_root := get_tree().edited_scene_root
	if scene_root == null or scene_root.scene_file_path != "res://main.tscn":
		push_error("[GISLineRegen] Edited scene must be res://main.tscn")
		_bake_in_progress = false
		return

	print("[GISLineRegen] Preparing segment data from local GeoJSON ...")
	var paths := [BOUNDARY_PATH, ROAD_PATH, BUILDING_PATH, SQUARE_BOUNDARY_PATH, WATERBODY_PATH]
	var prepared: Variant = _prepare_overlay_thread(paths, building_feature_budget, building_edge_budget, lowrise_instance_budget)
	if not (prepared is Dictionary) or (prepared as Dictionary).get("error", "") != "":
		var err_msg := "unknown error"
		if prepared is Dictionary:
			err_msg = str((prepared as Dictionary).get("error", err_msg))
		push_error("[GISLineRegen] Preparation failed: %s" % err_msg)
		_bake_in_progress = false
		return

	var prepared_data := prepared as Dictionary
	_set_worker_envelope(prepared_data)

	var boundary_segments := _segments_from_worker(prepared_data.get("boundary_segments", []))
	var road_segments := _segments_from_worker(prepared_data.get("road_segments", []))
	var road_width_meters := prepared_data.get("road_width_meters", []) as Array
	var square_boundary_segments := _segments_from_worker(prepared_data.get("square_boundary_segments", []))
	var waterbody_segments := _segments_from_worker(prepared_data.get("waterbody_segments", []))
	var building_segments := _segments_from_worker(prepared_data.get("building_segments", []))

	print("[GISLineRegen] Building corrected meshes ...")
	var boundary_mesh := await _build_strip_mesh(boundary_segments, _meters_to_canvas_width(BOUNDARY_WIDTH_M), GROUND_Y + 0.002, -1)
	var road_mesh := await _build_variable_width_strip_mesh(road_segments, road_width_meters, GROUND_Y, -1)
	var square_boundary_mesh := await _build_strip_mesh(square_boundary_segments, _meters_to_canvas_width(SQUARE_BOUNDARY_WIDTH_M), GROUND_Y + 0.0014, -1)
	var waterbody_mesh := await _build_strip_mesh(waterbody_segments, _meters_to_canvas_width(WATERBODY_WIDTH_M), GROUND_Y + 0.0005, -1)
	var building_mesh := await _build_strip_mesh(building_segments, _meters_to_canvas_width(building_line_width), GROUND_Y + 0.0008, -1)

	var mesh_map := {
		"Sector1BoundaryOverlay": {"mesh": boundary_mesh, "path": "res://gis/sector1_boundary_overlay.res"},
		"Sector1RoadwayOverlay": {"mesh": road_mesh, "path": "res://gis/sector1_roadway_overlay.res"},
		"Sector1SquareBoundariesBatch": {"mesh": square_boundary_mesh, "path": "res://gis/sector1_square_boundaries_batch.res"},
		"Sector1WaterbodyMarginsBatch": {"mesh": waterbody_mesh, "path": "res://gis/sector1_waterbody_margins_batch.res"},
		"Sector1BuildingFootprintsBatch": {"mesh": building_mesh, "path": "res://gis/sector1_building_footprints_batch.res"},
	}

	var saved_count := 0
	for node_name in mesh_map:
		var entry: Dictionary = mesh_map[node_name] as Dictionary
		var m: ArrayMesh = entry["mesh"] as ArrayMesh
		if m == null:
			push_warning("[GISLineRegen] No mesh produced for %s; skipping save." % node_name)
			continue
		var save_path := str(entry["path"])
		var save_error: Error = ResourceSaver.save(m as Resource, save_path, ResourceSaver.FLAG_BUNDLE_RESOURCES)
		if save_error != OK or not FileAccess.file_exists(save_path):
			push_error("[GISLineRegen] ResourceSaver.save failed for %s: %s" % [save_path, save_error])
			continue
		saved_count += 1
		print("[GISLineRegen] Saved %s" % save_path)

	# Reload saved resources and assign them to scene nodes.
	for node_name in mesh_map:
		var entry: Dictionary = mesh_map[node_name] as Dictionary
		var node := get_node_or_null("../BakedMap/" + node_name)
		if node == null or not (node is MeshInstance3D):
			push_warning("[GISLineRegen] Node %s not found; skipping reload." % node_name)
			continue
		if entry["mesh"] == null:
			continue
		var save_path := str(entry["path"])
		var loaded: Resource = ResourceLoader.load(save_path) as Resource
		if loaded == null:
			push_error("[GISLineRegen] Could not reload saved resource: %s" % save_path)
			continue
		(node as MeshInstance3D).mesh = loaded as ArrayMesh

	# Persist the main scene with new external resource references.
	var packed_scene := PackedScene.new()
	var pack_error: Error = packed_scene.pack(scene_root)
	if pack_error != OK:
		push_error("[GISLineRegen] Could not pack main.tscn: %s" % pack_error)
		_bake_in_progress = false
		return
	var scene_save_error: Error = ResourceSaver.save(packed_scene, scene_root.scene_file_path)
	if scene_save_error != OK:
		push_error("[GISLineRegen] Could not save main.tscn: %s" % scene_save_error)
		_bake_in_progress = false
		return

	_bake_in_progress = false
	print("[GISLineRegen] Completed: %d line-overlay .res files regenerated and main.tscn saved." % saved_count)


func _make_material(color: Color, render_priority: int = -1) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = render_priority
	return material

func _collect_building_bounds(data: Dictionary, output: Array[Rect2], budget: int, build_generation: int) -> int:
	var state := {"features": 0, "vertices": 0}
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if output.size() >= budget:
				break
			if feature is Dictionary:
				await _collect_building_geometry_bounds((feature as Dictionary).get("geometry", {}), output, budget, state, build_generation)
				state["features"] = int(state["features"]) + 1
				if int(state["features"]) >= LOWRISE_FEATURE_CHUNK:
					state["features"] = 0
					await get_tree().process_frame
					if not _build_is_current(build_generation):
						return output.size()
	elif data.get("type", "") == "Feature":
		await _collect_building_geometry_bounds(data.get("geometry", {}), output, budget, state, build_generation)
	else:
		await _collect_building_geometry_bounds(data, output, budget, state, build_generation)
	return output.size()

func _collect_building_geometry_bounds(geometry: Variant, output: Array[Rect2], budget: int, state: Dictionary, build_generation: int) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	var geometry_type: String = geometry_dict.get("type", "")
	var coordinates: Variant = geometry_dict.get("coordinates", [])
	match geometry_type:
		"Polygon":
			if coordinates is Array and not (coordinates as Array).is_empty():
				await _append_building_bound((coordinates as Array)[0], output, state, build_generation)
		"MultiPolygon":
			for polygon in coordinates as Array:
				if output.size() >= budget:
					return
				if polygon is Array and not (polygon as Array).is_empty():
					await _append_building_bound((polygon as Array)[0], output, state, build_generation)

func _append_building_bound(points: Variant, output: Array[Rect2], state: Dictionary, build_generation: int) -> void:
	if not (points is Array) or (points as Array).size() < 3:
		return
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var has_inside_point := false
	for point in points as Array:
		if not (point is Array) or (point as Array).size() < 2 or not _geo_point_in_envelope(point):
			continue
		has_inside_point = true
		var canvas_point := _geo_to_canvas(point)
		min_x = minf(min_x, canvas_point.x)
		min_y = minf(min_y, canvas_point.y)
		max_x = maxf(max_x, canvas_point.x)
		max_y = maxf(max_y, canvas_point.y)
		state["vertices"] = int(state.get("vertices", 0)) + 1
		if int(state["vertices"]) >= LOWRISE_VERTEX_CHUNK:
			state["vertices"] = 0
			await get_tree().process_frame
			if not _build_is_current(build_generation):
				return
	if not has_inside_point or not is_finite(min_x) or not is_finite(min_y) or not is_finite(max_x) or not is_finite(max_y):
		return
	if max_x <= min_x or max_y <= min_y:
		return
	output.append(Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y)))

func _build_lowrise_multimesh(bounds: Array[Rect2], budget: int, build_generation: int) -> MultiMesh:
	if bounds.is_empty():
		return null
	var instance_count := mini(bounds.size(), budget)
	if instance_count <= 0:
		return null
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3.ONE
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = box_mesh
	multimesh.instance_count = instance_count
	for index in range(instance_count):
		var bound := bounds[index]
		var width := maxf(bound.size.x, LOWRISE_MIN_FOOTPRINT_SIZE)
		var depth := maxf(bound.size.y, LOWRISE_MIN_FOOTPRINT_SIZE)
		var height := LOWRISE_HEIGHT_MIN + (float((index * 37) % 100) / 100.0) * (LOWRISE_HEIGHT_MAX - LOWRISE_HEIGHT_MIN)
		var basis := Basis().scaled(Vector3(width, height, depth))
		var center := Vector3(bound.position.x + bound.size.x * 0.5, GROUND_Y + height * 0.5, bound.position.y + bound.size.y * 0.5)
		multimesh.set_instance_transform(index, Transform3D(basis, center))
		if (index + 1) % LOWRISE_INSTANCE_CHUNK == 0:
			await get_tree().process_frame
			if not _build_is_current(build_generation):
				return null
	return multimesh

func _collect_building_segments(data: Dictionary, output: Array[Vector4], build_generation: int) -> int:
	var drawn_features := 0
	var processed_features := 0
	var state := {"work": 0}
	if data.get("type", "") == "FeatureCollection":
		for feature in data.get("features", []) as Array:
			if drawn_features >= building_feature_budget or output.size() >= building_edge_budget:
				break
			processed_features += 1
			if feature is Dictionary:
				var before := output.size()
				await _collect_building_geometry_segments((feature as Dictionary).get("geometry", {}), output, state, build_generation)
				if output.size() > before:
					drawn_features += 1
			if processed_features >= LOWRISE_FEATURE_CHUNK:
				processed_features = 0
				await get_tree().process_frame
				if not _build_is_current(build_generation):
					return drawn_features
	elif data.get("type", "") == "Feature":
		await _collect_building_geometry_segments(data.get("geometry", {}), output, state, build_generation)
		if not output.is_empty():
			drawn_features = 1
	else:
		await _collect_building_geometry_segments(data, output, state, build_generation)
		if not output.is_empty():
			drawn_features = 1
	return drawn_features

func _collect_building_geometry_segments(geometry: Variant, output: Array[Vector4], state: Dictionary, build_generation: int) -> void:
	if not (geometry is Dictionary):
		return
	var geometry_dict := geometry as Dictionary
	var geometry_type: String = geometry_dict.get("type", "")
	var coordinates: Variant = geometry_dict.get("coordinates", [])
	match geometry_type:
		"Polygon":
			for ring in coordinates as Array:
				await _add_line(ring, output, true, building_edge_budget, true, state, build_generation)
				if output.size() >= building_edge_budget:
					return
		"MultiPolygon":
			for polygon in coordinates as Array:
				for ring in polygon as Array:
					await _add_line(ring, output, true, building_edge_budget, true, state, build_generation)
					if output.size() >= building_edge_budget:
						return

