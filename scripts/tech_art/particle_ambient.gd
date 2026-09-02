# ============================================================================
# [ARCANJOS CAIDOS] — Particle Ambient System
# ----------------------------------------------------------------------------
# Sistema de partículas ambientais para atmosfera.
# Uso: Anexe a um nó Node2D na cena.
# ============================================================================

class_name ParticleAmbientSystem
extends Node2D

@export_group("Configuração")
@export var particle_type: ParticleType = ParticleType.DUST
@export var max_particles: int = 50
@export var emission_area: Vector2 = Vector2(1920, 1080)

@export_group("Movimento")
@export var drift_speed: Vector2 = Vector2(5.0, 2.0)
@export var lifetime_min: float = 3.0
@export var lifetime_max: float = 8.0

@export_group("Aparência")
@export var particle_color: Color = Color(1.0, 0.95, 0.8, 0.6)
@export var particle_size_min: float = 1.0
@export var particle_size_max: float = 3.0

enum ParticleType {
	DUST, FIREFLIES, SPARKS, MOTES, ASH, SNOW
}

var _particles: Array[CPUParticles2D] = []


func _ready() -> void:
	_create_particle_system()


func _create_particle_system() -> void:
	match particle_type:
		ParticleType.DUST: _create_dust()
		ParticleType.FIREFLIES: _create_fireflies()
		ParticleType.SPARKS: _create_sparks()
		ParticleType.MOTES: _create_motes()
		ParticleType.ASH: _create_ash()
		ParticleType.SNOW: _create_snow()


func _create_dust() -> void:
	var p := CPUParticles2D.new()
	p.name = "DustParticles"
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = drift_speed.x * 0.5
	p.initial_velocity_max = drift_speed.x
	p.gravity = Vector2(drift_speed.x * 0.1, -drift_speed.y * 0.2)
	p.scale_amount_min = particle_size_min
	p.scale_amount_max = particle_size_max
	p.color = particle_color
	_setup_fade_gradient(p)
	add_child(p)
	_particles.append(p)


func _create_fireflies() -> void:
	var p := CPUParticles2D.new()
	p.name = "FireflyParticles"
	p.amount = max_particles / 2
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, -1)
	p.spread = 360.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.gravity = Vector2(0, -10.0)
	p.scale_amount_min = particle_size_min * 1.5
	p.scale_amount_max = particle_size_max * 2.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.2, 1.0, 0.4, 0.0), Color(0.8, 1.0, 0.3, 1.0), Color(0.2, 1.0, 0.4, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = g
	add_child(p)
	_particles.append(p)


func _create_sparks() -> void:
	var p := CPUParticles2D.new()
	p.name = "SparkParticles"
	p.amount = max_particles / 3
	p.lifetime = lifetime_min * 0.5
	p.emitting = true
	p.direction = Vector2(0, 1)
	p.spread = 30.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, 100.0)
	p.scale_amount_min = particle_size_min
	p.scale_amount_max = particle_size_max * 0.5
	p.color = Color(1.0, 0.8, 0.4, 1.0)
	add_child(p)
	_particles.append(p)


func _create_motes() -> void:
	var p := CPUParticles2D.new()
	p.name = "MoteParticles"
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 15.0
	p.gravity = Vector2(0, -20.0)
	p.scale_amount_min = particle_size_min * 2.0
	p.scale_amount_max = particle_size_max * 3.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.0, 0.8, 1.0, 0.0), Color(0.3, 0.9, 1.0, 0.8), Color(0.0, 0.8, 1.0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = g
	add_child(p)
	_particles.append(p)


func _create_ash() -> void:
	var p := CPUParticles2D.new()
	p.name = "AshParticles"
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min, lifetime_max)
	p.emitting = true
	p.direction = Vector2(0, 1)
	p.spread = 45.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.gravity = Vector2(0, 50.0)
	p.scale_amount_min = particle_size_min
	p.scale_amount_max = particle_size_max
	p.color = Color(0.3, 0.3, 0.3, 0.7)
	add_child(p)
	_particles.append(p)


func _create_snow() -> void:
	var p := CPUParticles2D.new()
	p.name = "SnowParticles"
	p.amount = max_particles
	p.lifetime = randf_range(lifetime_min * 2.0, lifetime_max * 2.0)
	p.emitting = true
	p.direction = Vector2(0, 1)
	p.spread = 30.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.gravity = Vector2(0, 80.0)
	p.scale_amount_min = particle_size_min * 1.5
	p.scale_amount_max = particle_size_max * 2.0
	p.color = Color(0.95, 0.95, 1.0, 0.8)
	add_child(p)
	_particles.append(p)


func _setup_fade_gradient(p: CPUParticles2D) -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([
		Color(particle_color.r, particle_color.g, particle_color.b, 0.0),
		particle_color,
		Color(particle_color.r, particle_color.g, particle_color.b, 0.0)
	])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = g


## API: Atualiza tipo de partícula em runtime
func set_particle_type(new_type: ParticleType) -> void:
	particle_type = new_type
	for p in _particles:
		p.queue_free()
	_particles.clear()
	_create_particle_system()


## API: Atualiza cor das partículas
func set_color(new_color: Color) -> void:
	particle_color = new_color
	for p in _particles:
		p.color = new_color


## API: Pausa/retoma emissão
func set_emitting(enabled: bool) -> void:
	for p in _particles:
		p.emitting = enabled