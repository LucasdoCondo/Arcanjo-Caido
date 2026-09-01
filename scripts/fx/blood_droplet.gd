class_name BloodDroplet
extends RigidBody2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 17: gota de sangue negro que cae, colide com as
## plataformas e se queda pegada (gruda) para depois desaparecer lentamente.
## ============================================================================

const FADE_DELAY := 1.1
const FADE_TIME := 0.7

var _stuck := false
var _fade_timer := 0.0
var _fading := false


func _ready() -> void:
	gravity_scale = 1.5
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_contact)
	collision_layer = 0
	collision_mask = 1  ## colide com o solo/paredes (capa 1)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.5
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	if _fading:
		_fade_timer -= delta
		modulate.a = clampf(_fade_timer / FADE_TIME, 0.0, 1.0)
		if _fade_timer <= 0.0:
			queue_free()
	elif _stuck:
		_fade_timer -= delta
		if _fade_timer <= 0.0:
			_fading = true
			_fade_timer = FADE_TIME


func _on_contact(_body: Node) -> void:
	if _stuck:
		return
	_stuck = true
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	_fade_timer = FADE_DELAY


func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.5, Color(0.06, 0.04, 0.05, 0.9))