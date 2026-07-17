extends Node

## Sonidos procedurales básicos (sin archivos externos).

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE := 6


func _ready() -> void:
	_streams["shoot_player"] = _make_tone(920.0, 0.06, 0.22)
	_streams["shoot_enemy"] = _make_tone(520.0, 0.07, 0.18)
	_streams["hit"] = _make_tone(180.0, 0.05, 0.28)
	_streams["hurt"] = _make_tone(140.0, 0.12, 0.35)
	_streams["enemy_death"] = _make_tone(95.0, 0.18, 0.3)
	_streams["wave"] = _make_tone(440.0, 0.14, 0.25, true)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)


func play(sound_id: String) -> void:
	if not _streams.has(sound_id):
		return
	var player := _get_free_player()
	if player == null:
		return
	player.stream = _streams[sound_id]
	player.volume_db = -4.0
	player.pitch_scale = randf_range(0.94, 1.06)
	player.play()


func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]


func _make_tone(freq: float, duration: float, volume: float, rising: bool = false) -> AudioStreamWAV:
	var sample_hz := 22050
	var sample_count := maxi(int(sample_hz * duration), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_hz)
		var env := 1.0 - float(i) / float(sample_count)
		var f := freq * (1.0 + t * 0.8) if rising else freq
		var sample := sin(TAU * f * t) * volume * env
		var value := int(clampf(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	stream.stereo = false
	stream.data = data
	return stream
