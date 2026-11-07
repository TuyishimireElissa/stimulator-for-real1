extends Node3D

const CATALOG_PATH := "res://data/equipment/catalog.json"
const PROJECT_VERSION := 1
const GRID_SPACING := 2.4
const EMPTY_INSPECTOR_TEXT := (
	"Select an object in the workshop to inspect it."
	+ "\n\n"
	+ "The current catalogue consists of visual-only generic placeholders."
)

var definitions: Array[Dictionary] = []
var placed: Dictionary = {}
var selected: Node3D
var next_id := 1
var simulation_running := false
var simulation_seconds := 0.0
var camera: Camera3D
var world_root: Node3D
var ui_layer: CanvasLayer
var search_box: LineEdit
var palette: VBoxContainer
var inspector_label: Label
var status_label: Label
var sim_label: Label
var sim_button: Button
var save_dialog: FileDialog
var load_dialog: FileDialog
var camera_dragging := false
var camera_panning := false
var last_mouse := Vector2.ZERO
var yaw := 0.0
var pitch := 0.28
var camera_target := Vector3.ZERO
var camera_distance := 12.0
var placement_counter := 0


func _ready() -> void:
	_load_catalog()
	_build_world()
	_build_interface()
	_refresh_palette()
	_update_camera()
	_set_status("Ready · %d generic catalogue entries" % definitions.size())
	set_process(true)


func _process(delta: float) -> void:
	if simulation_running:
		simulation_seconds += delta
		sim_label.text = "CLOCK  %s" % _format_time(simulation_seconds)


func _load_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Equipment catalogue is missing: " + CATALOG_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("equipment")) != TYPE_ARRAY:
		push_error("Equipment catalogue is malformed.")
		return
	var seen_ids := {}
	for item in parsed.equipment:
		if (
			typeof(item) != TYPE_DICTIONARY
			or typeof(item.get("id")) != TYPE_STRING
			or typeof(item.get("name")) != TYPE_STRING
			or str(item.get("id", "")).is_empty()
			or str(item.get("name", "")).is_empty()
		):
			push_warning("Skipping an equipment definition with missing identity fields.")
			continue
		if seen_ids.has(item.id):
			push_warning("Skipping duplicate equipment definition: " + item.id)
			continue
		seen_ids[item.id] = true
		definitions.append(item)


func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "EquipmentInstances"
	add_child(world_root)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("172432")
	sky_material.sky_horizon_color = Color("667687")
	sky_material.ground_bottom_color = Color("151c22")
	sky_material.ground_horizon_color = Color("59616a")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c6d5e3")
	env.ambient_light_energy = 0.55
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -28, 0)
	light.light_energy = 1.2
	add_child(light)
	var floor := MeshInstance3D.new()
	floor.name = "WorkshopFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	floor.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("26333d")
	floor_mat.roughness = 0.9
	floor.material_override = floor_mat
	floor.position.y = -0.05
	add_child(floor)
	var grid := MeshInstance3D.new()
	grid.name = "FloorGrid"
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color("42535e")
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var grid_mesh := ImmediateMesh.new()
	grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES, grid_mat)
	for index in range(-20, 21):
		var coordinate := float(index) * 2.0
		grid_mesh.surface_add_vertex(Vector3(coordinate, 0.0, -40.0))
		grid_mesh.surface_add_vertex(Vector3(coordinate, 0.0, 40.0))
		grid_mesh.surface_add_vertex(Vector3(-40.0, 0.0, coordinate))
		grid_mesh.surface_add_vertex(Vector3(40.0, 0.0, coordinate))
	grid_mesh.surface_end()
	grid.mesh = grid_mesh
	grid.position.y = 0.005
	add_child(grid)
	camera = Camera3D.new()
	camera.name = "WorkshopCamera"
	camera.fov = 58.0
	add_child(camera)


func _build_interface() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_layer.add_child(root)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = 60
	top.add_theme_stylebox_override("panel", _panel_style(Color("121b24"), Color("344652")))
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top.add_child(top_row)
	var title := Label.new()
	title.text = "  FIELDWORK  /  VIRTUAL ENGINEERING WORKSHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("dce7ed"))
	title.add_theme_font_size_override("font_size", 16)
	top_row.add_child(title)
	sim_label = Label.new()
	sim_label.text = "CLOCK  00:00.0"
	sim_label.add_theme_color_override("font_color", Color("80d6c3"))
	top_row.add_child(sim_label)
	sim_button = _add_button(top_row, "Start", _toggle_simulation)
	sim_button.add_to_group("simulation_toggle")
	_add_button(top_row, "Save", _save_project)
	_add_button(top_row, "Load", _load_project)
	var left := _make_panel(
		root, Control.PRESET_LEFT_WIDE, Vector2(285, 0), Vector2(12, 76), Vector2(300, -16)
	)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 9)
	left.add_child(left_box)
	left_box.add_child(_label("EQUIPMENT LIBRARY", 13, Color("84d5c3")))
	search_box = LineEdit.new()
	search_box.placeholder_text = "Search equipment..."
	search_box.text_changed.connect(func(_text: String): _refresh_palette())
	left_box.add_child(search_box)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_child(scroll)
	palette = VBoxContainer.new()
	palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette.add_theme_constant_override("separation", 5)
	scroll.add_child(palette)
	var right := _make_panel(
		root, Control.PRESET_RIGHT_WIDE, Vector2(300, 0), Vector2(-312, 76), Vector2(-12, -16)
	)
	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 10)
	right.add_child(right_box)
	right_box.add_child(_label("OBJECT INSPECTOR", 13, Color("84d5c3")))
	inspector_label = _label(EMPTY_INSPECTOR_TEXT, 12, Color("c1ccd3"))
	inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_child(inspector_label)
	_add_button(right_box, "Focus selected   F", _focus_selected)
	_add_button(right_box, "Duplicate   Ctrl+D", _duplicate_selected)
	_add_button(right_box, "Remove   Delete", _remove_selected)
	_add_button(right_box, "Rotate   R", _rotate_selected)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -42
	bottom.custom_minimum_size.y = 42
	bottom.add_theme_stylebox_override("panel", _panel_style(Color("121b24"), Color("344652")))
	root.add_child(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 18)
	bottom.add_child(bottom_row)
	status_label = _label("Ready", 11, Color("acbbc4"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(status_label)
	bottom_row.add_child(
		_label(
			"Orbit: right-drag   Pan: middle-drag   Zoom: wheel   Move: WASD / arrows",
			11,
			Color("82939d")
		)
	)
	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.json", "Virtual workshop project")
	save_dialog.current_file = "workshop-project.json"
	save_dialog.file_selected.connect(_write_project)
	root.add_child(save_dialog)
	load_dialog = FileDialog.new()
	load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_dialog.access = FileDialog.ACCESS_FILESYSTEM
	load_dialog.add_filter("*.json", "Virtual workshop project")
	load_dialog.file_selected.connect(_read_project)
	root.add_child(load_dialog)


func _make_panel(
	parent: Control,
	preset: Control.LayoutPreset,
	minimum: Vector2,
	position: Vector2,
	size: Vector2
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(preset)
	panel.offset_left = position.x
	panel.offset_top = position.y
	panel.offset_right = size.x
	panel.offset_bottom = size.y
	panel.custom_minimum_size = minimum
	panel.add_theme_stylebox_override("panel", _panel_style(Color("17222c"), Color("344652")))
	parent.add_child(panel)
	return panel


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _label(value: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


func _add_button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", Color("dce7ed"))
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _refresh_palette() -> void:
	if palette == null:
		return
	for child in palette.get_children():
		child.queue_free()
	var query := ""
	if search_box != null:
		query = search_box.text.strip_edges().to_lower()
	for item in definitions:
		var searchable := (
			(str(item.get("name", "")) + " " + str(item.get("category", ""))).to_lower()
		)
		if not searchable.contains(query):
			continue
		var caption := (
			str(item.get("name", "Unnamed"))
			+ "\n"
			+ str(item.get("category", "unknown")).to_upper()
		)
		var b := _add_button(palette, caption, func(): _place_equipment(item))
		b.custom_minimum_size.y = 50
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = (
			str(item.get("description", "")) + "\nVisual placeholder only — no simulation model."
		)
	if palette.get_child_count() == 0:
		palette.add_child(_label("No matching equipment.", 12, Color("acbbc4")))


func _place_equipment(definition: Dictionary, at: Vector3 = Vector3.INF) -> void:
	var body := StaticBody3D.new()
	var instance_id := "equipment-%04d" % next_id
	next_id += 1
	body.name = instance_id
	body.set_meta("instance_id", instance_id)
	body.set_meta("definition_id", str(definition.id))
	body.set_meta("display_name", str(definition.name))
	var mesh_instance := MeshInstance3D.new()
	var equipment_mesh := _equipment_mesh(str(definition.id))
	mesh_instance.mesh = equipment_mesh
	mesh_instance.position.y = equipment_mesh.size.y * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _equipment_color(str(definition.id))
	mat.metallic = 0.18
	mat.roughness = 0.55
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = equipment_mesh.size + Vector3(0.08, 0.08, 0.08)
	collision.position.y = equipment_mesh.size.y * 0.5
	collision.shape = shape
	body.add_child(collision)
	world_root.add_child(body)
	if at == Vector3.INF:
		var column := placement_counter % 4
		var row := floori(float(placement_counter) / 4.0)
		at = Vector3((column - 1.5) * GRID_SPACING, 0.01, row * GRID_SPACING)
		placement_counter += 1
	body.position = at
	placed[instance_id] = body
	_select(body)
	_set_status("Placed %s · visual-only placeholder" % definition.name)


func _equipment_mesh(definition_id: String) -> BoxMesh:
	var mesh := BoxMesh.new()
	if definition_id == "generic_workbench":
		mesh.size = Vector3(2.1, 0.18, 1.15)
	elif definition_id == "generic_digital_multimeter":
		mesh.size = Vector3(0.45, 0.7, 0.22)
	elif definition_id == "generic_network_switch":
		mesh.size = Vector3(1.35, 0.2, 0.72)
	else:
		mesh.size = Vector3(1.05, 0.7, 0.8)
	return mesh


func _equipment_color(definition_id: String) -> Color:
	match definition_id:
		"generic_workbench":
			return Color("90734e")
		"generic_desktop_pc":
			return Color("45545f")
		"generic_network_switch":
			return Color("527178")
		"generic_digital_multimeter":
			return Color("bd734c")
		_:
			return Color("71828a")


func _select(body: Node3D) -> void:
	if selected != null and is_instance_valid(selected):
		var previous_mesh := selected.get_child(0) as MeshInstance3D
		if previous_mesh and previous_mesh.material_override is StandardMaterial3D:
			(previous_mesh.material_override as StandardMaterial3D).emission_enabled = false
	selected = body
	if selected != null and is_instance_valid(selected):
		var mesh := selected.get_child(0) as MeshInstance3D
		if mesh and mesh.material_override is StandardMaterial3D:
			var material := mesh.material_override as StandardMaterial3D
			material.emission_enabled = true
			material.emission = Color("51d5b5")
	_update_inspector()


func _update_inspector() -> void:
	if inspector_label == null:
		return
	if selected == null or not is_instance_valid(selected):
		inspector_label.text = EMPTY_INSPECTOR_TEXT
		return
	var pos := selected.position
	inspector_label.text = (
		PackedStringArray(
			[
				"NAME",
				str(selected.get_meta("display_name")),
				"",
				"INSTANCE",
				str(selected.get_meta("instance_id")),
				"",
				"DEFINITION",
				str(selected.get_meta("definition_id")),
				"",
				"POSITION (m)",
				"X %.2f   Y %.2f   Z %.2f" % [pos.x, pos.y, pos.z],
				"",
				"CAPABILITY",
				"Visual representation only",
				"No ports · no simulation · no measurements",
				"",
				"Use WASD / arrow keys to move, R to rotate.",
				"Save and Load preserve this arrangement.",
			]
		)
		. join("\n")
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_RIGHT:
			camera_dragging = mouse.pressed
			last_mouse = mouse.position
		elif mouse.button_index == MOUSE_BUTTON_MIDDLE:
			camera_panning = mouse.pressed
			last_mouse = mouse.position
			if mouse.pressed:
				get_viewport().set_input_as_handled()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			camera_distance = maxf(3.0, camera_distance - 0.9)
			_update_camera()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			camera_distance = minf(45.0, camera_distance + 0.9)
			_update_camera()
		elif mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_pick_object(mouse.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if camera_dragging:
			var delta := motion.position - last_mouse
			yaw -= delta.x * 0.006
			pitch = clampf(pitch - delta.y * 0.004, -1.15, 0.2)
			_update_camera()
			last_mouse = motion.position
		elif camera_panning:
			var delta := motion.position - last_mouse
			var right := camera.global_basis.x
			var up := camera.global_basis.y
			camera_target += (-right * delta.x + up * delta.y) * camera_distance * 0.0015
			_update_camera()
			last_mouse = motion.position
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
			_remove_selected()
		elif key.keycode == KEY_R:
			_rotate_selected()
		elif key.keycode == KEY_F:
			_focus_selected()
		elif key.ctrl_pressed and key.keycode == KEY_D:
			_duplicate_selected()
		elif selected != null:
			var direction := Vector3.ZERO
			if key.keycode in [KEY_W, KEY_UP]:
				direction.z -= 0.25
			if key.keycode in [KEY_S, KEY_DOWN]:
				direction.z += 0.25
			if key.keycode in [KEY_A, KEY_LEFT]:
				direction.x -= 0.25
			if key.keycode in [KEY_D, KEY_RIGHT]:
				direction.x += 0.25
			if direction != Vector3.ZERO:
				selected.position += direction
				_update_inspector()


func _pick_object(screen_position: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 200.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider is StaticBody3D and hit.collider.has_meta("instance_id"):
		_select(hit.collider as Node3D)
	else:
		_select(null)


func _update_camera() -> void:
	if camera == null:
		return
	var direction := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
	camera.position = camera_target + direction * camera_distance
	camera.look_at(camera_target, Vector3.UP)


func _focus_selected() -> void:
	if selected != null and is_instance_valid(selected):
		camera_target = selected.position
		_update_camera()


func _rotate_selected() -> void:
	if selected != null and is_instance_valid(selected):
		selected.rotate_y(deg_to_rad(15.0))
		_set_status("Rotated %s" % selected.get_meta("display_name"))


func _duplicate_selected() -> void:
	if selected == null or not is_instance_valid(selected):
		_set_status("Select an object before duplicating.")
		return
	var definition := _definition_for_id(str(selected.get_meta("definition_id")))
	if not definition.is_empty():
		_place_equipment(definition, selected.position + Vector3(1.5, 0.0, 0.0))


func _remove_selected() -> void:
	if selected == null or not is_instance_valid(selected):
		return
	var id := str(selected.get_meta("instance_id"))
	selected.queue_free()
	placed.erase(id)
	selected = null
	_update_inspector()
	_set_status("Removed %s" % id)


func _toggle_simulation() -> void:
	simulation_running = not simulation_running
	if sim_button != null:
		sim_button.text = "Pause" if simulation_running else "Start"
	_set_status(
		(
			"Simulation clock running"
			if simulation_running
			else "Simulation clock paused · no engineering models are active"
		)
	)


func _save_project() -> void:
	var directory := OS.get_user_data_dir().path_join("projects")
	DirAccess.make_dir_recursive_absolute(directory)
	save_dialog.current_dir = directory
	save_dialog.current_file = "workshop-project.json"
	save_dialog.popup_centered_ratio(0.75)


func _write_project(path: String) -> void:
	var objects: Array[Dictionary] = []
	for id in placed:
		var body: Node3D = placed[id]
		if is_instance_valid(body):
			objects.append(
				{
					"instance_id": id,
					"definition_id": body.get_meta("definition_id"),
					"position": [body.position.x, body.position.y, body.position.z],
					"rotation": [body.rotation.x, body.rotation.y, body.rotation.z]
				}
			)
	var data := {
		"format": "virtual-equipment-project",
		"schema_version": PROJECT_VERSION,
		"simulation_seconds": simulation_seconds,
		"equipment": objects
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	_set_status("Saved %d equipment instance(s)" % objects.size())


func _load_project() -> void:
	var directory := OS.get_user_data_dir().path_join("projects")
	DirAccess.make_dir_recursive_absolute(directory)
	load_dialog.current_dir = directory
	load_dialog.popup_centered_ratio(0.75)


func _read_project(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("Load failed: %s" % error_string(FileAccess.get_open_error()))
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	var validation_error := _validate_project(parsed)
	if not validation_error.is_empty():
		_set_status("Load failed: " + validation_error)
		return
	for body in placed.values():
		if is_instance_valid(body):
			body.queue_free()
	placed.clear()
	selected = null
	next_id = 1
	placement_counter = 0
	for item in parsed.equipment:
		if (
			typeof(item) != TYPE_DICTIONARY
			or not item.has("definition_id")
			or not item.has("position")
			or not item.has("rotation")
		):
			continue
		var definition := _definition_for_id(str(item.definition_id))
		if definition.is_empty() or item.position.size() != 3 or item.rotation.size() != 3:
			continue
		_place_equipment(
			definition,
			Vector3(float(item.position[0]), float(item.position[1]), float(item.position[2]))
		)
		var body: Node3D = selected
		body.rotation = Vector3(
			float(item.rotation[0]), float(item.rotation[1]), float(item.rotation[2])
		)
		_update_next_id(str(item.get("instance_id", "")))
	simulation_seconds = maxf(0.0, float(parsed.get("simulation_seconds", 0.0)))
	_update_inspector()
	_set_status(
		"Loaded %d equipment instance(s) · project schema %d" % [placed.size(), PROJECT_VERSION]
	)


func _validate_project(parsed: Variant) -> String:
	var error_message := ""
	if (
		typeof(parsed) != TYPE_DICTIONARY
		or parsed.get("format") != "virtual-equipment-project"
		or parsed.get("schema_version") != PROJECT_VERSION
		or typeof(parsed.get("equipment")) != TYPE_ARRAY
	):
		error_message = "unsupported project format or schema version."
	elif parsed.equipment.size() > 1000:
		error_message = "project exceeds the 1000-object safety limit."
	elif (
		typeof(parsed.get("simulation_seconds", 0.0)) not in [TYPE_FLOAT, TYPE_INT]
		or not is_finite(float(parsed.get("simulation_seconds", 0.0)))
		or float(parsed.get("simulation_seconds", 0.0)) < 0.0
	):
		error_message = "project clock value is invalid."
	else:
		var seen_ids := {}
		for item in parsed.equipment:
			if typeof(item) != TYPE_DICTIONARY:
				error_message = "equipment entries must be objects."
				break
			var instance_id := str(item.get("instance_id", ""))
			if (
				not instance_id.begins_with("equipment-")
				or instance_id.trim_prefix("equipment-").to_int() < 1
			):
				error_message = "an equipment instance has an invalid identifier."
				break
			if seen_ids.has(instance_id):
				error_message = "duplicate equipment instance identifier: " + instance_id
				break
			seen_ids[instance_id] = true
			if _definition_for_id(str(item.get("definition_id", ""))).is_empty():
				error_message = "unknown equipment definition in project."
				break
			for field in ["position", "rotation"]:
				var coordinates = item.get(field)
				if typeof(coordinates) != TYPE_ARRAY or coordinates.size() != 3:
					error_message = (
						"equipment %s must contain three %s values." % [instance_id, field]
					)
					break
				for value in coordinates:
					if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)):
						error_message = (
							"equipment %s contains an invalid %s value." % [instance_id, field]
						)
						break
				if not error_message.is_empty():
					break
			if not error_message.is_empty():
				break
	return error_message


func _update_next_id(instance_id: String) -> void:
	if instance_id.begins_with("equipment-"):
		var number := instance_id.trim_prefix("equipment-").to_int()
		if number > 0:
			var body: Node3D = selected
			var old_id := str(body.get_meta("instance_id"))
			body.set_meta("instance_id", instance_id)
			body.name = instance_id
			placed.erase(old_id)
			placed[instance_id] = body
			next_id = maxi(next_id, number + 1)


func _definition_for_id(definition_id: String) -> Dictionary:
	for item in definitions:
		if str(item.id) == definition_id:
			return item
	return {}


func _set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message


func _format_time(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	var remainder := fmod(seconds, 60.0)
	return "%02d:%04.1f" % [minutes, remainder]
