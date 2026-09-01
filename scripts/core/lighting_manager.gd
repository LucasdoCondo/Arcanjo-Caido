class_name LightingManager
extends Node2D
## ============================================================================
## [ARCANJO CAIDO] — TECH ART: Gestor de iluminación global.
## ----------------------------------------------------------------------------
## Añadido por `Room` (nodo "Lighting") para centralizar:
##   - Normal maps: aplica el mapa neutro a todos los sprites del mundo.
##   - Emissão con Bloom: amplifica la energía de todas las PointLight2D del
##     grupo "emissive" (Chama Negra, ojos de jefes, ataques, tochas, auras)
##     para que brillen pasado el umbral HDR del glow.
##   - Flicker ambiental global (pulso suave opcional).
## ----------------------------------------------------------------------------

@export_group("Iluminación Global (Tech Art)")
@export var emissive_boost: float = 1.35   ## Multiplica la energía de luces "emissive"
@export var ambient_flicker: float = 0.0   ## 0 = off; pulso suave senoidal global

var _emissive_lights: Array[PointLight2D] = []
var _base_energy: Dictionary = {}
var _time: float = 0.0


func _ready() -> void:
	# Recolecta todas las luces del grupo "emissive" del árbol y guarda su energía base.
	var all := get_tree().get_nodes_in_group("emissive")
	for n in all:
		var light := n as PointLight2D
		if light == null:
			continue
		_emissive_lights.append(light)
		_base_energy[light.get_instance_id()] = light.energy

	# Aplica normal maps a TODA la sala (jogador, cenário, inimigos).
	var room := get_parent()
	if room != null:
		FxUtil.apply_normal_maps(room)


func _process(delta: float) -> void:
	_time += delta
	var flicker := 1.0 + ambient_flicker * sin(_time * 3.0)
	for light in _emissive_lights:
		var base: float = _base_energy.get(light.get_instance_id(), 1.0)
		light.energy = base * emissive_boost * flicker


## [API] Fuerza la energía de una luz emissive puntual (ojos, Chama Negra).
## Útil para cambios dinámicos por juego (Fase 2, cura canalizada, etc.).
static func set_emission(light: PointLight2D, energy: float) -> void:
	if light == null:
		return
	light.energy = energy