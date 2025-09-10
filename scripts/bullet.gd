extends CharacterBody3D

@export var speed: float = 343
@export var bounces: int = 1

var ricochet_threshold: float = 0.1

var last_pos: Vector3

const sfx_ricochet := [
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_1.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_2.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_3.wav"),
	preload("res://assets/audio/sfx/weapons/bullet/ricochet/bullet_ricochet_4.wav"),
]

func _ready() -> void:
	last_pos = global_position

func _physics_process(delta: float) -> void:
	var motion = transform.basis.x * speed * delta
	var collision = move_and_collide(motion)
	var new_pos = global_position

	_draw_segment(last_pos, new_pos)

	last_pos = new_pos

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

	var normal = collision.get_normal()
	var incidence = velocity.normalized().dot(normal)

	if bounces > 0 and abs(incidence) < ricochet_threshold:
		velocity = velocity.bounce(normal)
		velocity *= 0.8  # optional: lose speed on bounce
		bounces -= 1
		global_transform.origin = collision.get_position() + normal * 0.01
		play_random_sfx(sfx_ricochet, 16)
	else:
		place_decal(collision)
		queue_free()

func play_random_sfx(sound_list, volume: float=0):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], volume)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer3D.new()
	ap.max_db = volume
	get_tree().current_scene.add_child(ap)
	ap.global_transform = global_transform
	ap.stream = stream
	ap.bus = "SFX"
	ap.play()
	await ap.finished
	ap.queue_free()

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

	# auto-delete after 1s
	var t = Timer.new()
	t.wait_time = 3.0
	t.one_shot = true
	mi.add_child(t)
	t.timeout.connect(mi.queue_free)
	t.start()
