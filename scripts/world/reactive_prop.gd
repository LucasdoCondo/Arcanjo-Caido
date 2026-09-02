class_name ReactiveProp
extends Node2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 18: Vegetação e cenários reativos.
## ----------------------------------------------------------------------------
## Plantas, cadeias e mantas de pano penduradas que balançam com o vento e se
## entortam suavemente quando Lúcifer ou inimigos passam por perto.
## O desenho é procedural (placeholder) e pivota pela base (origem do nó).
## ============================================================================

@export_group("Visual (placeholder)")
@export var visual_type: String = "plant"   ## plant | chain | cloth | grass
@export var height: float = 28.0
@export var amplitude: float = 0.10          ## balanço ambiental (rad)
@export var sway_speed: float = 1.8
@export var phase: float = 0.0

@export_group("Reação ao passar")
@export var influence_radius: float = 70.0   ## distância para reagir
@export var max_bend: float = 0.6            ## ângulo máximo por interação (rad)
@export var bend_speed: float = 5.0          ## suavização (recuperação)

var _bend: float = 0.0
var _push_dir: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	## Passo 21: registra no culling da câmera (desliga _process fora da tela).
	Culling.register(self)


func _exit_tree() -> void:
	Culling.unregister(self)


func _process(delta: float) -> void:
	_time += delta

	# Detecta atores próximos (Lúcifer e inimigos).
	var push := 0.0
	for gid in ["player", "enemy"]:
		for n in get_tree().get_nodes_in_group(gid):
			var n2 := n as Node2D
			if n2 == null:
				continue
			var d := global_position.distance_to(n2.global_position)
			if d <= influence_radius:
				var strength := 1.0 - d / influence_radius
				if absf(strength) > absf(push):
					push = signf(n2.global_position.x - global_position.x) * strength
	if push != 0.0:
		_push_dir = push
	else:
		_push_dir = move_toward(_push_dir, 0.0, bend_speed * 0.5 * delta)

	# Alvo: balanço ambiental + empurrão de quem passa.
	var sway := sin(_time * sway_speed + phase) * amplitude
	var target := sway + _push_dir * max_bend
	_bend = lerpf(_bend, target, 1.0 - pow(0.001, delta * bend_speed))
	rotation = _bend
	queue_redraw()


func _draw() -> void:
	var h := height
	var w := 4.0
	match visual_type:
		"chain":
			draw_line(Vector2.ZERO, Vector2(0.0, h), Color(0.45, 0.42, 0.5, 1.0), 2.0)
			draw_circle(Vector2(0.0, h), 3.0, Color(0.55, 0.5, 0.6, 1.0))
		"cloth":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-w * 1.6, 0.0), Vector2(w * 1.6, 0.0),
				Vector2(-w * 0.7, h), Vector2(w * 0.7, h)]),
				Color(0.32, 0.11, 0.13, 0.9))
		"grass":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-1.5, 0.0), Vector2(1.5, 0.0), Vector2(0.0, h)]),
				Color(0.2, 0.35, 0.2, 1.0))
		"plant":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-w, 0.0), Vector2(w, 0.0), Vector2(0.0, h)]),
				Color(0.16, 0.3, 0.18, 1.0))
		_:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-w, 0.0), Vector2(w, 0.0), Vector2(0.0, h)]),
				Color(0.16, 0.3, 0.18, 1.0))