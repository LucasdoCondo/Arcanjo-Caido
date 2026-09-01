class_name Cape2D
extends Node2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 17: Física da capa carcomida de Lúcifer.
## ----------------------------------------------------------------------------
## Simulação de juntas (cadena de ossos "finos"): vários segmentos conectados
## responden ao vento, à gravidade e à velocidade dos saltos e se desenham
## como uma cinta elástica detrás do sprite. Reacciona ao facing e à corrente
## do movimento para dar sensação de tecido vivo.
## ============================================================================

@export_group("Capa")
@export var segments: int = 6
@export var segment_length: float = 10.0
@export var width: float = 7.0
@export var color: Color = Color(0.22, 0.07, 0.09, 0.9)
@export var gravity_strength: float = 420.0
@export var wind_strength: float = 40.0
@export var wind_sway: float = 3.0
@export var drag: float = 0.86
@export var draft_scale: float = 0.02        ## Quanto o vento do movimento o empuja
@export var anchor_offset: Vector2 = Vector2(0.0, -12.0)  ## Punto de anclaje (detrás)

var _points: Array[Vector2] = []
var _vels: Array[Vector2] = []
var _time: float = 0.0


func _ready() -> void:
	z_index = -1  ## detrás do sprite (deformação/lean não o afetan)
	_points.resize(segments)
	_vels.resize(segments)
	for i in segments:
		_points[i] = Vector2(anchor_offset.x, anchor_offset.y + float(i) * segment_length)
		_vels[i] = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var parent := get_parent() as CharacterBody2D
	if parent == null:
		return
	var facing := 1
	var vel := Vector2.ZERO
	if parent.has_method("get_facing"):
		facing = parent.get_facing()
	if parent is CharacterBody2D:
		vel = parent.linear_velocity

	# Anclaje detrás do sprite segundo o facing.
	var anchor := anchor_offset
	anchor.x = -facing * absf(anchor_offset.x)
	_points[0] = anchor

	# Viento ambiente + corrente do movimento horizontal do Lúcifer.
	var wy := wind_strength * sin(_time * 2.2 + anchor.x * 0.02)
	var wind := Vector2(wind_sway * sin(_time * 1.6 + 0.7), wy)

	for i in range(1, segments):
		var pvel := _vels[i]
		# Gravedad + viento + corriente do salto/movimento.
		pvel += Vector2((wind.x + vel.x * draft_scale) * delta,
				(gravity_strength * 0.06 + wind.y) * delta)
		pvel.y -= vel.y * draft_scale * delta * 0.5
		pvel *= drag
		var cand := _points[i] + pvel * delta
		var to_prev := cand - _points[i - 1]
		if to_prev.length() > segment_length:
			cand = _points[i - 1] + to_prev.normalized() * segment_length
		_vels[i] = pvel
		_points[i] = cand
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return
	var ribbon := PackedVector2Array()
	for p in _points:
		ribbon.append(p + Vector2(-width, 0.0))
		ribbon.append(p + Vector2(width, 0.0))
	draw_colored_polygon(ribbon, color)