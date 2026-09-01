extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: Achievements
## ----------------------------------------------------------------------------
## Conquistas 100% offline, persistidas em user://achievements.json.
## Gatilhos são chamados pelo jogo (derrotar chefe, desbloquear habilidade...).
## A lista de conquistas oficial do GDD: O Primeiro Tombo, Luz Ressoante,
## Misericórdia ou Maldição?, Mestre das Relíquias, Soberano do Vazio e
## A Verdadeira Libertação.
## ============================================================================

signal achievement_unlocked(id: String)

const SAVE_PATH := "user://achievements.json"

const DEFS: Array = [
	{"id": "first_tomb", "name": "O Primeiro Tombo", "desc": "Desperte na Cripta das Estrelas Caídas."},  # Bronze
	{"id": "blade_fragments", "name": "Luz Ressoante", "desc": "Reúna os 12 fragmentos da Lâmina do Alvorecer."},  # Prata
	{"id": "azazel_quest", "name": "Misericórdia ou Maldição?", "desc": "Complete a linha de quests de Azazel."},  # Prata
	{"id": "sigils_master", "name": "Mestre das Relíquias", "desc": "Obtenha todos os Sigilos do Banimento."},  # Ouro
	{"id": "mammon_slain", "name": "Soberano do Vazio", "desc": "Derrote Mammon, o Ingestionável, e reivindique o Trono de Aeterna."},  # Ouro
	{"id": "abilities_all", "name": "Anjo Reascendido", "desc": "Desbloqueie as 4 habilidades de exploração de Aeterna."},
	{"id": "void_sovereign", "name": "O Trono do Abismo", "desc": "Atravesse a Catedral da Avareza e enfrente o regente usurpador do Vazio."},
	{"id": "true_freedom", "name": "A Verdadeira Libertação", "desc": "Final Verdadeiro: recuse o trono, destrua Aeterna e liberte todas as almas do Limbo."},  # Platina (100%)
]

var unlocked: Dictionary = {}


func _ready() -> void:
	_load()


func unlock(id: String) -> void:
	if unlocked.has(id):
		return
	unlocked[id] = true
	_save()
	achievement_unlocked.emit(id)
	print("[ARCANJO CAIDO] Conquista desbloqueada: %s" % id)


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": unlocked.keys()}))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("unlocked"):
		for id in parsed["unlocked"]:
			unlocked[id] = true
