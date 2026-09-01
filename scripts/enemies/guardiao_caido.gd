class_name GuardiaoCaido
extends EnemyBase
## ============================================================================
## [ARCANJO CAIDO] — Passo 3: "Guardião Caído" — inimigo da Cripta das
## Estrelas Caídas. Um anjo da guarda de Lúcifer deformado pelo Vazio, que
## ainda patrulha os salões que jurou proteger.
## Comportamento herdado do EnemyBase (patrulha/perseguição/ataque).
## Toque próprio: o flash de telegraph fica mais claro (anticipação visível).
## ============================================================================


func _physics_process(delta: float) -> void:
	# O EnemyBase reseta o modulate no início do frame; aplicamos o telegraph
	# DEPOIS do super para que o tint de antecipação permaneça visível.
	super(delta)

	# Passo "animação": frames da sheet conforme a IA.
	match ai_state:
		AIState.ATTACK:
			visual.frame = 2  ## Telegraph: braço erguido
		AIState.HURT:
			visual.frame = 3  ## Ferido/abatido
		_:
			_anim_t += delta
			visual.frame = 0 if fmod(_anim_t, 0.6) < 0.3 else 1

	if ai_state == AIState.ATTACK:
		visual.modulate = Color(1.6, 1.4, 1.0)


var _anim_t: float = 0.0


func _ready() -> void:
	super()
	FxUtil.apply_flat_normal(visual)
