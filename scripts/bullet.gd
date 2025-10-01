extends CharacterBody3D

@export var speed: float = 360
@export var max_spread := Vector2(0.01, 0.01)
@export var bounces: int = 1

var last_pos: Vector3

const sfx_ricochet := [
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_1.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_2.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_3.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_4.wav"),
]

const sfx_supersonic_crack := [
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_01.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_02.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_03.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_04.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_05.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_06.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_07.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_07.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_08.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_09.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_10.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_11.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/snap/supersonic_snap_12.wav")
]

var crack_played := false

func _ready() -> void:
	last_pos = global_position
	rotate_y(randf_range(-max_spread.x, max_spread.x))
	rotate_z(randf_range(-max_spread.y, max_spread.y))

func _physics_process(delta: float) -> void:
	var motion = transform.basis.x * speed * delta
	var new_pos = global_position + motion

	if speed > 343.0: # supersonic
		if not crack_played:
			var closest = Geometry3D.get_closest_point_to_segment(Global.player.global_position, global_position, new_pos)
			var dist = Global.player.global_position.distance_to(closest)
			if dist < 5.0:
				play_random_sfx(sfx_supersonic_crack)
				Global.player.healthCtl.adrenaline += 0.01
				Global.player.healthCtl.consciousness -= 0.05
				Global.playerGUI.shock()
				crack_played = true

	var collision = move_and_collide(motion)

	#_draw_segment(last_pos, new_pos)
	#last_pos = new_pos

	if collision:
		_on_hit(collision)

func place_decal(collision: KinematicCollision3D):
	var pos := collision.get_position()
	var n := collision.get_normal().normalized()

	var decal := Decal.new()
	get_tree().current_scene.add_child(decal)
	decal.texture_albedo = preload("res://assets/textures/decals/bullet_hole.png")
	var up := n
	var right := up.cross(Vector3.FORWARD)
	if right.length() < 0.001:
		right = up.cross(Vector3.RIGHT)
	right = right.normalized()
	var forward := right.cross(up).normalized()

	var decalbasis := Basis(right, up, forward)

	decal.global_transform = Transform3D(decalbasis, pos + n * 0.01)
	decal.size = Vector3(0.05, 0.5, 0.05)
	decal.reparent(collision.get_collider())

func _on_hit(collision: KinematicCollision3D) -> void:
	var collider = collision.get_collider()
	if collider and collider.has_method("hit"):
		collider.hit(self)
	place_decal(collision)
	queue_free()

func play_random_sfx(sound_list, volume: float=0, pos: Vector3=global_position):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], volume, pos)

func playsound(stream: AudioStream, volume: float=0, pos: Vector3=global_position):
	var ap = AudioStreamPlayer3D.new()
	ap.max_db = volume
	get_tree().current_scene.add_child(ap)
	ap.global_position = pos
	ap.stream = stream
	ap.bus = "SFX"
	ap.play()
	ap.finished.connect(ap.queue_free)

func _draw_segment(from: Vector3, to: Vector3):
	var line = ImmediateMesh.new()
	line.surface_begin(Mesh.PRIMITIVE_LINES)
	line.surface_set_color(Color(1, 0, 0, 1))
	line.surface_add_vertex(from)
	line.surface_add_vertex(to)
	line.surface_end()

	var mi = MeshInstance3D.new()
	mi.mesh = line
	get_tree().current_scene.add_child(mi)

	var t = Timer.new()
	t.wait_time = 10.0
	t.one_shot = true
	mi.add_child(t)
	t.timeout.connect(mi.queue_free)
	t.start()
