extends Node
## ============================================================================
## [ARCANJO CAIDO] — Autoload: AudioManager (Passo 11)
## ----------------------------------------------------------------------------
## Gerenciador central de áudio 100% offline:
##   - Buses separados: "Music" (BGM), "SFX" e "Ambience"
##   - Crossfade suave entre trilhas ao mudar de região / entrar em chefe
##   - SFX globais: AudioManager.sfx("jump" | "sword" | "hurt" | "coin" ...)
##   - Como o projeto ainda não tem assets de áudio, os sons e as trilhas são
##     SINTETIZADOS em tempo real (AudioStreamWAV gerado por código). Quando
##     os .ogg/.wav reais chegarem, basta trocar os streams deste arquivo.
## ============================================================================

signal bus_volume_changed(bus_name: String, linear: float)

const SAMPLE_RATE := 22050
const SFX_POOL_SIZE := 10

## Definição das trilhas: id -> [freq base, "calmo"|"tenso"]
const TRACK_DEFS := {
	"menu": [98.0, "calmo"],
	"cripta_estrelas": [146.83, "calmo"],
	"corredor_cinzas": [110.0, "calmo"],
	"jardim_adonai": [130.81, "calmo"],
	"mar_de_vidro": [123.47, "calmo"],
	"catedral_avareza": [87.31, "tenso"],
	"boss": [65.41, "tenso"],
}

var _sounds: Dictionary = {}
var _tracks: Dictionary = {}
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0
var _using_a: bool = false
var _current_track: String = ""
var _player: Node = null
var _hooks_connected: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_build_players()
	_synth_sounds()


# ---------------------------------------------------------------------------
# BUSES
# ---------------------------------------------------------------------------
func _setup_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _build_players() -> void:
	_bgm_a = _make_player("Music")
	_bgm_b = _make_player("Music")
	_ambience_player = _make_player("Ambience")
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player("SFX"))


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


## Volume de um bus em escala linear (0.0 a 1.0) — usado pelas Opções.
func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	linear = clampf(linear, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
	bus_volume_changed.emit(bus_name, linear)


func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	var db := AudioServer.get_bus_volume_db(idx)
	return clampf(db_to_linear(db), 0.0, 1.0)


# ===========================================================================
# SINTETIZADOR (substituível por assets reais no futuro)
# ===========================================================================
func _make_tone(freq: float, dur: float, kind: String = "sine", vol: float = 0.5) -> AudioStreamWAV:
	var n := int(dur * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var s: float
		match kind:
			"square":
				s = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
			"saw":
				s = fmod(t * freq, 1.0) * 2.0 - 1.0
			"noise":
				s = randf_range(-1.0, 1.0)
			_:
				s = sin(TAU * freq * t)
		var env := 1.0 - float(i) / n  ## Envelope de decaimento
		var v := int(clampf(s * env * vol, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _wav_from_data(data, false)


func _make_track(base_freq: float, mood: String = "calmo") -> AudioStreamWAV:
	## Trilha em loop: camadas de senoides com LFOs lentos (protótipo de BGM).
	var dur := 12.0 if mood == "calmo" else 9.0
	var n := int(dur * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var s := 0.22 * sin(TAU * base_freq * t)
		s += 0.16 * sin(TAU * base_freq * 1.5 * t) * (0.5 + 0.5 * sin(TAU * 0.125 * t))
		s += 0.12 * sin(TAU * base_freq * 2.0 * t) * (0.5 + 0.5 * sin(TAU * 0.25 * t + 1.0))
		s += 0.2 * sin(TAU * base_freq * 0.5 * t)  ## Baixo
		if mood == "tenso":
			s += 0.08 * sin(TAU * base_freq * 3.0 * t) * (0.5 + 0.5 * sin(TAU * 0.75 * t))
		var v := int(clampf(s, -1.0, 1.0) * 32767.0 * 0.55)
		data.encode_s16(i * 2, v)
	return _wav_from_data(data, true)


func _wav_from_data(data: PackedByteArray, looping: bool) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	if looping:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = data.size() / 2
	return wav


func _synth_sounds() -> void:
	_sounds = {
		"jump": _make_tone(520.0, 0.16, "square", 0.3),
		"dash": _make_tone(300.0, 0.14, "saw", 0.28),
		"sword": _make_tone(900.0, 0.09, "noise", 0.32),
		"hurt": _make_tone(170.0, 0.3, "square", 0.45),
		"coin": _make_tone(1250.0, 0.12, "sine", 0.35),
		"step": _make_tone(140.0, 0.06, "noise", 0.2),
		"death": _make_tone(110.0, 0.6, "saw", 0.45),
		"heal": _make_tone(660.0, 0.4, "sine", 0.35),
		"unlock": _make_tone(880.0, 0.5, "sine", 0.4),
		"achievement": _make_tone(1040.0, 0.35, "sine", 0.4),
		"parry": _make_tone(1500.0, 0.12, "square", 0.35),
	}

# ===========================================================================
# API PÚBLICA
# ===========================================================================
func sfx(sound_name: String) -> void:
	## Trigger global de efeito sonoro: AudioManager.sfx("sword")
	var stream: AudioStreamWAV = _sounds.get(sound_name)
	if stream == null:
		return
	var p := _sfx_players[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_players.size()
	p.stream = stream
	p.play()


func play_music(track_id: String, fade: float = 1.5) -> void:
	## Troca de trilha com CROSSFADE (região nova / arena de chefe).
	if _current_track == track_id:
		return
	_current_track = track_id

	var incoming := _bgm_b if _using_a else _bgm_a
	var outgoing := _bgm_a if _using_a else _bgm_b
	_using_a = not _using_a

	incoming.stream = _get_track(track_id)
	incoming.volume_db = -40.0
	incoming.play()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(incoming, "volume_db", 0.0, fade)
	tw.tween_property(outgoing, "volume_db", -40.0, fade)
	tw.chain().tween_callback(outgoing.stop)


func _get_track(track_id: String) -> AudioStreamWAV:
	if _tracks.has(track_id):
		return _tracks[track_id]
	var def: Array = TRACK_DEFS.get(track_id, [110.0, "calmo"])
	var track: AudioStreamWAV = _make_track(def[0], def[1])
	_tracks[track_id] = track
	return track


func play_ambience(sound_name: String = "wind") -> void:
	## Camada de ambiente contínua (vento do Vazio etc.).
	if _ambience_player.playing:
		return
	var stream: AudioStreamWAV = _sounds.get(sound_name)
	if stream == null:
		stream = _make_tone(90.0, 3.0, "noise", 0.12)
		_sounds[sound_name] = stream
	_ambience_player.stream = stream
	_ambience_player.volume_db = -8.0
	_ambience_player.play()


# ===========================================================================
# HOOKS AUTOMÁTICOS — conecta os sinais do Lúcifer aos SFX
# ===========================================================================
func _process(_delta: float) -> void:
	if _hooks_connected and (not is_instance_valid(_player) or _player == null):
		_hooks_connected = false
		_player = null
	if not _hooks_connected:
		_player = get_tree().get_first_node_in_group("player")
		if _player and _player.has_signal("dashed"):
			_player.dashed.connect(func(): sfx("dash"))
			_player.damaged.connect(func(_amount): sfx("hurt"))
			_player.died.connect(func(): sfx("death"))
			_player.state_changed.connect(_on_player_state)
			if _player.has_signal("coin_collected"):
				_player.coin_collected.connect(func(): sfx("coin"))
			_hooks_connected = true


func _on_player_state(new_state: int) -> void:
	match new_state:
		PlayerController.State.JUMP:
			sfx("jump")
		PlayerController.State.ATTACK:
			sfx("sword")
