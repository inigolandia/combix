extends Node3D

## Shared terrain builder for the scene-authored map and runtime fallback.
## In the editor, the same generator bakes owned nodes into main.tscn; at runtime,
## the saved MapGeneratedBaked hierarchy is consumed without rebuilding a duplicate.
## The plugin calls generate_baked_map() explicitly; runtime never rebuilds a baked root.
const BAKED_ROOT_NAME := "MapGeneratedBaked"
const BAKED_METADATA_KEY := "map_baked"
const BAKED_GENERATOR_VERSION := 1

var _generation_root: Node3D
var _editor_owner: Node

const LAND := Color("#7f9d70")
const BLOCK_A := Color("#b9b69f")
const BLOCK_B := Color("#a9ad95")
const ROAD := Color("#303b46")
const SIDEWALK := Color("#aaa59d")
const ROAD_LINE := Color("#e2c96f")
const MALL := Color("#b9cf98")
const WATER_POTOMAC := Color("#3e91aa")
const WATER_ANACOSTIA := Color("#347f99")
const SHORE := Color("#d9c68f")
const STONE := Color("#eee8d6")
const STONE_SHADE := Color("#c8c0a9")
const WHITE := Color("#f7f1dc")
const ROOF := Color("#625f68")
const ACCENT := Color("#d9b84d")

var materials: Dictionary = {}

func _ready() -> void:
	_generation_root = self
	_editor_owner = null
	if not _has_baked_map():
		# The persisted scene is the single source for both workspace and runtime.
		# Never rebuild or replace the editable hierarchy during scene startup.
		push_error("[DCMap] MapGeneratedBaked is missing or incomplete; refusing a runtime rebuild.")
		return
	var camera := get_node_or_null("TopDownCamera") as Camera3D
	if camera:
		camera.position = Vector3(27, 26, 27)
		camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
		camera.size = 44.0

func _is_current_baked_root(baked_root: Node) -> bool:
	if baked_root == null:
		return false
	if not bool(baked_root.get_meta(BAKED_METADATA_KEY, false)):
		return false
	# The editor may repair an older landmark-only bake, while a current bake is
	# always consumed as-is. This predicate is shared by startup and explicit bakes.
	if Engine.is_editor_hint():
		return baked_root.get_node_or_null("Block_-4200_-900") != null and baked_root.get_node_or_null("EastBankLand") != null
	return baked_root.get_child_count() > 0

func _has_baked_map() -> bool:
	return _is_current_baked_root(get_node_or_null(BAKED_ROOT_NAME))

## Called explicitly by the Map God Mode editor plugin. The returned root is owned by
## the edited scene and is therefore persisted with main.tscn when the user saves it.
func generate_baked_map(target: Node3D, scene_owner: Node) -> Node3D:
	if target == null:
		return null
	var previous := target.get_node_or_null(BAKED_ROOT_NAME) as Node3D
	if _is_current_baked_root(previous):
		# Idempotent explicit bake: viewport/editor refreshes must not rebuild a
		# complete persisted hierarchy that is already current.
		return previous
	if previous != null:
		previous.free()
	var baked_root := Node3D.new()
	baked_root.name = BAKED_ROOT_NAME
	baked_root.set_meta(BAKED_METADATA_KEY, true)
	baked_root.set_meta("map_generator", "res://dc_map_runtime.gd")
	baked_root.set_meta("map_generator_version", BAKED_GENERATOR_VERSION)
	baked_root.add_to_group("map_generated_baked", true)
	target.add_child(baked_root)
	baked_root.owner = scene_owner if scene_owner != null else target
	_generation_root = baked_root
	_editor_owner = scene_owner if scene_owner != null else target
	_setup_environment()
	_build_map()
	_generation_root = self
	_editor_owner = null
	return baked_root

func clear_baked_map(target: Node3D) -> bool:
	if target == null:
		return false
	var baked_root := target.get_node_or_null(BAKED_ROOT_NAME)
	if baked_root == null:
		return false
	baked_root.free()
	return true

func _attach_generated(node: Node) -> void:
	_generation_root.add_child(node)
	if _editor_owner != null:
		node.owner = _editor_owner

func _attach_generated_child(parent: Node, node: Node) -> void:
	parent.add_child(node)
	if _editor_owner != null:
		node.owner = _editor_owner

func _setup_environment() -> void:
	# main.tscn already owns the active environment; do not serialize a second one
	# inside the baked map when the editor is materializing the shared source.
	var scene_root := self if _generation_root == self else _generation_root.get_parent()
	if scene_root != null and scene_root.get_node_or_null("DayEnvironment") != null:
		return
	var world := WorldEnvironment.new()
	world.name = "DayEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#aebfc4")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#dce8e4")
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	_attach_generated(world)

## Metric geometry uses the single canonical WorldScale conversion source.
## Arbitrary gameplay constants (camera tuning, labels, and editor-only layout values)
## are intentionally not scaled here.
const ORIGIN_LAT := 38.8899
const ORIGIN_LON := -77.0091
const METERS_PER_DEG_LAT := 111320.0
const METERS_PER_DEG_LON := 98200.0

func _geo_pos(latitude: float, longitude: float) -> Vector3:
	# Local origin is the US Capitol (38.8899, -77.0091), WGS84 rounded.
	# x = east, z = south; geographic metres use the canonical WorldScale conversion.
	return Vector3(WorldScale.meters_to_units((longitude - ORIGIN_LON) * METERS_PER_DEG_LON), 0.0, WorldScale.meters_to_units(-(latitude - ORIGIN_LAT) * METERS_PER_DEG_LAT))

func _road_between(node_name: String, start: Vector3, finish: Vector3, width: float) -> MeshInstance3D:
	var delta := finish - start
	var midpoint := Vector3((start.x + finish.x) * 0.5, 0.10, (start.z + finish.z) * 0.5)
	var road := _box(node_name, midpoint, Vector3(width, 0.12, delta.length()), ROAD, "road")
	var direction := Vector3(delta.x, 0.0, delta.z).normalized()
	var right := Vector3(direction.z, 0.0, -direction.x)
	var yaw := atan2(delta.x, delta.z)
	road.rotation.y = yaw
	_sidewalk_strip(node_name + "SidewalkEast", midpoint + right * (width * 0.5 + 2.5), delta.length(), yaw)
	_sidewalk_strip(node_name + "SidewalkWest", midpoint - right * (width * 0.5 + 2.5), delta.length(), yaw)
	return road

func _sidewalk_strip(node_name: String, center: Vector3, length: float, yaw: float) -> MeshInstance3D:
	var sidewalk := _box(node_name, Vector3(center.x, 0.22, center.z), Vector3(4.0, 0.18, length), SIDEWALK, "sidewalk")
	sidewalk.rotation.y = yaw
	return sidewalk

func _crosswalk_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#3a4147")
	mat.roughness = 0.98
	mat.metallic = 0.0
	mat.specular = 0.0
	return mat

func _crosswalk_stripe_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WHITE
	mat.roughness = 0.96
	mat.metallic = 0.0
	mat.specular = 0.0
	return mat

func _crosswalk_vertical(node_name: String, center: Vector3, road_width: float) -> void:
	# Procedural zebra: its asphalt base is local matte material, never a road or sidewalk texture.
	_box(node_name + "Asphalt", center + Vector3(0, 0.18, 0), Vector3(road_width, 0.08, 12.0), Color("#3a4147"), "crosswalk")
	for index in range(6):
		var stripe_z := center.z - 5.0 + float(index) * 2.0
		_box(node_name + "Stripe%s" % index, Vector3(center.x, 0.24, stripe_z), Vector3(max(road_width - 3.0, 4.0), 0.04, 1.15), WHITE, "crosswalk_stripe")

func _crosswalk_horizontal(node_name: String, center: Vector3, road_width: float) -> void:
	_box(node_name + "Asphalt", center + Vector3(0, 0.18, 0), Vector3(12.0, 0.08, road_width), Color("#3a4147"), "crosswalk")
	for index in range(6):
		var stripe_x := center.x - 5.0 + float(index) * 2.0
		_box(node_name + "Stripe%s" % index, Vector3(stripe_x, 0.24, center.z), Vector3(1.15, 0.04, max(road_width - 3.0, 4.0)), WHITE, "crosswalk_stripe")

func _build_map() -> void:
	# Real-scale DC core blockout. Metric dimensions are converted with WorldScale.
	var capitol := _geo_pos(38.8899, -77.0091)
	var loc := _geo_pos(38.8887, -77.0047)
	var union_station := _geo_pos(38.8971, -77.0064)
	var white_house := _geo_pos(38.8977, -77.0365)
	var washington_monument := _geo_pos(38.8895, -77.0353)
	var lincoln := _geo_pos(38.8893, -77.0502)
	var jefferson := _geo_pos(38.8814, -77.0365)
	var smithsonian := _geo_pos(38.8882, -77.0282)
	var archives := _geo_pos(38.8923, -77.0261)

	# Central land, river silhouettes and a navigable land collision.
	_box("LandMass", Vector3(-350, -0.55, 120), Vector3(8300, 1.0, 3300), LAND)
	_box("EastBankLand", Vector3(5600, -0.55, 180), Vector3(1100, 1.0, 3000), LAND)
	_add_navigable_floor_collision()
	_box("Potomac", Vector3(-5100, -0.02, 120), Vector3(1200, 0.16, 3300), WATER_POTOMAC)
	_box("Anacostia", Vector3(4500, -0.02, 180), Vector3(900, 0.16, 3000), WATER_ANACOSTIA)
	_box("PotomacShore", Vector3(-4470, 0.12, 120), Vector3(18, 0.20, 3300), SHORE)
	_box("AnacostiaShore", Vector3(4028, 0.12, 180), Vector3(18, 0.20, 3000), SHORE)
	_label("POTOMAC", Vector3(-5100, 0.45, 500), Color("#e7f5f2"))
	_label("ANACOSTIA", Vector3(4500, 0.45, 500), Color("#e7f5f2"))

	# Major avenues and a legible street grid for the central 1:1 blockout.
	_road_between("PennsylvaniaAvenue", capitol, white_house, 32.0)
	_road_between("ConstitutionAvenue", _geo_pos(38.8920, -77.0091), _geo_pos(38.8920, -77.0500), 28.0)
	_road_between("IndependenceAvenue", _geo_pos(38.8870, -77.0091), _geo_pos(38.8870, -77.0500), 28.0)
	_road_between("MassachusettsAvenue", union_station, _geo_pos(38.9050, -77.0500), 24.0)
	for x in range(-4200, 801, 400):
		_box("AvenueE%s" % x, Vector3(float(x), 0.08, 120), Vector3(22, 0.12, 3000), ROAD, "road")
		_box("AvenueE%sSidewalkEast" % x, Vector3(float(x) + 14.5, 0.22, 120), Vector3(4.0, 0.18, 3000), SIDEWALK, "sidewalk")
		_box("AvenueE%sSidewalkWest" % x, Vector3(float(x) - 14.5, 0.22, 120), Vector3(4.0, 0.18, 3000), SIDEWALK, "sidewalk")
	for z in range(-900, 1201, 400):
		_box("AvenueN%s" % z, Vector3(-1750, 0.08, float(z)), Vector3(5200, 0.12, 22), ROAD, "road")
		_box("AvenueN%sSidewalkNorth" % z, Vector3(-1750, 0.22, float(z) - 14.5), Vector3(5200, 0.18, 4.0), SIDEWALK, "sidewalk")
		_box("AvenueN%sSidewalkSouth" % z, Vector3(-1750, 0.22, float(z) + 14.5), Vector3(5200, 0.18, 4.0), SIDEWALK, "sidewalk")
	for x in range(-4000, 401, 800):
		_box("LaneE%s" % x, Vector3(float(x), 0.16, 120), Vector3(3, 0.035, 3000), ROAD_LINE)
	for z in range(-700, 1001, 800):
		_box("LaneN%s" % z, Vector3(-1750, 0.16, float(z)), Vector3(5200, 0.035, 3), ROAD_LINE)

	# Dedicated zebra crossings: local asphalt plus regular white stripes, never sidewalk texture.
	_crosswalk_vertical("CrosswalkCentralVertical", Vector3(-2200, 0.0, -500), 22.0)
	_crosswalk_horizontal("CrosswalkCentralHorizontal", Vector3(-2200, 0.0, -500), 22.0)
	_crosswalk_vertical("CrosswalkMallVertical", Vector3(-1800, 0.0, 300), 22.0)
	_crosswalk_horizontal("CrosswalkMallHorizontal", Vector3(-1800, 0.0, 300), 22.0)

	# A broad west-east National Mall axis: Capitol -> Monument -> Lincoln.
	_box("NationalMall", Vector3(-2030, 0.20, 35), Vector3(4100, 0.24, 190), MALL)
	_box("MallReflectingPool", Vector3(-3300, 0.34, 56), Vector3(2900, 0.10, 62), Color("#7bbbc0"))
	_box("MallPathNorth", Vector3(-2030, 0.38, -65), Vector3(4100, 0.06, 8), SHORE)
	_box("MallPathSouth", Vector3(-2030, 0.38, 135), Vector3(4100, 0.06, 8), SHORE)
	_label("NATIONAL MALL", Vector3(-2100, 0.55, 35), Color("#35563d"))

	# Principal blocks: deliberately secondary and procedural, but metrically spaced.
	for x in range(-4200, 801, 400):
		for z in range(-900, 1201, 400):
			if x < 100 and abs(float(z) - 35.0) < 150.0:
				continue
			var height := 8.0 + float((abs(x) + abs(z)) % 13)
			var colour := BLOCK_A if ((x / 400 + z / 400) as int) % 2 == 0 else BLOCK_B
			_box("Block_%s_%s" % [x, z], Vector3(float(x), 0.34, float(z)), Vector3(300, 0.45, 290), colour)
			_box("Building_%s_%s" % [x, z], Vector3(float(x), 0.60 + height * 0.5, float(z)), Vector3(230, height, 220), colour)
			_box("Roof_%s_%s" % [x, z], Vector3(float(x), 0.70 + height, float(z)), Vector3(190, 0.18, 180), ROOF)

	# Bridges: Potomac crossings and Anacostia crossings are visible at core scale.
	for z in [-620.0, 620.0]:
		_box("PotomacBridge%s" % z, Vector3(-4510, 0.52, z), Vector3(1200, 0.28, 48), ROAD, "road")
		_box("PotomacBridgeMark%s" % z, Vector3(-4510, 0.70, z), Vector3(1040, 0.04, 4), ROAD_LINE)
	for z in [-520.0, 520.0]:
		_box("AnacostiaBridge%s" % z, Vector3(4070, 0.52, z), Vector3(900, 0.28, 48), ROAD, "road")
		_box("AnacostiaBridgeMark%s" % z, Vector3(4070, 0.70, z), Vector3(760, 0.04, 4), ROAD_LINE)

	# Landmark volumes use rounded real dimensions from the brief.
	_box("Capitol", capitol + Vector3(0, 6, 0), Vector3(229, 12, 107), STONE)
	_cylinder("CapitolDome", capitol + Vector3(0, 22, 0), 34, 20, STONE_SHADE)
	_cylinder("CapitolLantern", capitol + Vector3(0, 36, 0), 8, 8, ACCENT)
	_label("US CAPITOL 229m x 107m", capitol + Vector3(0, 45, 0), Color("#3d3a35"))

	_box("LibraryOfCongress", loc + Vector3(0, 10, 0), Vector3(157, 20, 90), STONE_SHADE)
	_label("LIBRARY OF CONGRESS", loc + Vector3(0, 34, 0), Color("#3d3a35"))
	_box("UnionStation", union_station + Vector3(0, 12, 0), Vector3(220, 24, 120), STONE)
	_label("UNION STATION", union_station + Vector3(0, 38, 0), Color("#3d3a35"))

	_box("WhiteHouse", white_house + Vector3(0, 4, 0), Vector3(51, 8, 26), WHITE)
	_box("WhiteHouseLawn", white_house + Vector3(0, 0.18, 90), Vector3(150, 0.36, 90), MALL)
	_label("WHITE HOUSE 51m x 26m", white_house + Vector3(0, 20, 0), Color("#3d3a35"))

	_box("WashingtonMonumentBase", washington_monument + Vector3(0, 1.0, 0), Vector3(16.8, 2.0, 16.8), STONE)
	_box("WashingtonMonument", washington_monument + Vector3(0, 84.65, 0), Vector3(5.0, 169.3, 5.0), STONE)
	_box("MonumentTip", washington_monument + Vector3(0, 170.5, 0), Vector3(6.0, 2.4, 6.0), ACCENT)
	_label("WASHINGTON MONUMENT 169.3m", washington_monument + Vector3(0, 185, 0), Color("#3d3a35"))

	_box("LincolnMemorial", lincoln + Vector3(0, 15, 0), Vector3(58, 30, 36), STONE)
	_box("LincolnSteps", lincoln + Vector3(0, 1.0, 28), Vector3(96, 2.0, 56), STONE_SHADE)
	_label("LINCOLN MEMORIAL 58m x 36m", lincoln + Vector3(0, 42, 0), Color("#3d3a35"))

	_cylinder("JeffersonMemorial", jefferson + Vector3(0, 19.5, 0), 25, 39, STONE)
	_cylinder("JeffersonDome", jefferson + Vector3(0, 42, 0), 21, 8, STONE_SHADE)
	_label("JEFFERSON MEMORIAL 50m dia x 39m", jefferson + Vector3(0, 57, 0), Color("#3d3a35"))

	_box("SmithsonianCastle", smithsonian + Vector3(0, 7.5, 0), Vector3(150, 15, 50), STONE_SHADE)
	_label("SMITHSONIAN CASTLE", smithsonian + Vector3(0, 28, 0), Color("#3d3a35"))
	_box("NationalArchives", archives + Vector3(0, 9, 0), Vector3(100, 18, 80), STONE)
	_label("NATIONAL ARCHIVES", archives + Vector3(0, 32, 0), Color("#3d3a35"))

func _add_navigable_floor_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "NavigableGroundCollision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(8300, 0.4, 3300)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	_attach_generated_child(body, collision)
	_attach_generated(body)
	var east_body := StaticBody3D.new()
	east_body.name = "EastBankGroundCollision"
	var east_shape := BoxShape3D.new()
	east_shape.size = Vector3(1100, 0.4, 3000)
	var east_collision := CollisionShape3D.new()
	east_collision.shape = east_shape
	_attach_generated_child(east_body, east_collision)
	east_body.position = Vector3(5600, 0, 180)
	_attach_generated(east_body)

func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	materials[key] = mat
	return mat

func _box(node_name: String, pos: Vector3, size: Vector3, color: Color, surface_kind: String = "") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	# Every surface uses a cached solid-color StandardMaterial3D; markings keep their own distinctions.
	if surface_kind == "crosswalk":
		node.material_override = _crosswalk_material()
		node.set_surface_override_material(0, _crosswalk_material())
	elif surface_kind == "crosswalk_stripe":
		node.material_override = _crosswalk_stripe_material()
		node.set_surface_override_material(0, _crosswalk_stripe_material())
	else:
		node.material_override = _material(color)
	node.set_surface_override_material(0, _material(color))
	node.position = pos
	_attach_generated(node)
	return node

func _cylinder(node_name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = pos
	_attach_generated(node)
	return node

func _label(text_value: String, pos: Vector3, color: Color) -> void:
	var node := Label3D.new()
	node.text = text_value
	node.name = text_value.replace(" ", "_")
	node.position = pos
	node.rotation_degrees = Vector3(-90, 0, 0)
	node.font_size = 32
	node.outline_size = 6
	node.modulate = color
	node.no_depth_test = true
	_attach_generated(node)
