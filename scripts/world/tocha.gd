extends Node2D
## ============================================================================
## [ARCANJO CAIDO] — Passo 12: Tocha da Cripta.
## Ponto de luz 2D quente com flicker orgânico + brasas subindo (partículas).
## Espalhe instâncias pelas salas para pontuar a atmosfera.
## ============================================================================

var _time: float = 0.0

@onready var light: PointLight2D = $Light


func _ready() -> void:
	_time = randf() * TAU  ## Dessincroniza o flicker entre tochas
	Culling.register(self)


func _exit_tree() -> void:
	Culling.unregister(self)


func _process(delta: float) -> void:
	_time += delta * 6.0
	light.energy = 1.3 + 0.18 * sin(_time) + 0.09 * sin(_time * 2.7)
