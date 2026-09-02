class_name DestructibleProp
extends StaticBody2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 18: Elementos destruíveis do cenário.
## ----------------------------------------------------------------------------
## Estátuas pequenas, vasos e caixas velhas que se quebram em vários pedaços
## com físicas de gravidade ao serem atingidos pelos ataques do Lúcifer
## (Lâmina, ground pound, dash venenoso etc. — tudo via take_hit).
## ============================================================================

@export_group("Pedacos")
@export var shards_count: int = 6
@export var shard_velocity: float = 240.0
@export var shard_color: Color = Color(0.22, 0.18, 0.1, 1.0)

var destroyed := false

@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	hurtbox.add_to_group("destructible")
	## Passo 21: culling da câmera (partículas de pedaços param fora da tela).
	Culling.register(self)


func _exit_tree() -> void:
	Culling.unregister(self)


func take_hit(_damage: int, _from_position: Vector2) -> void:
	smash()


## Quebra o prop em pedaços físicos e remove o objeto.
func smash() -> void:
	if destroyed:
		return
	destroyed = true
	# Passo 19: SFX de quebra de vaso/estátua.
	AudioManager.sfx("vase_break")
	for i in shards_count:
		var shard := RigidBody2D.new()
		shard.global_position = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-12.0, 0.0))
		shard.linear_velocity = Vector2(randf_range(-1.0, 1.0) * shard_velocity,
				randf_range(-1.5, -0.6) * shard_velocity)
		shard.angular_velocity = randf_range(-6.0, 6.0)
		shard.gravity_scale = 1.2
		shard.collision_layer = 0
		shard.collision_mask = 1

		var sz := randf_range(4.0, 8.0)
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(sz, sz)
		col.shape = rect
		shard.add_child(col)

		var vis := Polygon2D.new()
		vis.polygon = PackedVector2Array([
			Vector2(-sz, -sz) * 0.5, Vector2(sz, -sz) * 0.5,
			Vector2(sz, sz) * 0.5, Vector2(-sz, sz) * 0.5])
		vis.color = shard_color
		shard.add_child(vis)

		get_parent().add_child(shard)
		get_tree().create_timer(1.4).timeout.connect(shard.queue_free)
	queue_free()