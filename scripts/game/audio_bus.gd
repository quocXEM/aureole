extends Node
## Soft procedural blips — safe for mobile.

var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback


func _ready() -> void:
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050.0
	_gen.buffer_length = 0.3
	_player = AudioStreamPlayer.new()
	_player.stream = _gen
	_player.volume_db = -10.0
	add_child(_player)
	_player.play()
	call_deferred("_bind_playback")


func _bind_playback() -> void:
	if _player:
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func play_tap() -> void:
	_blip(660.0, 0.04, 0.14)


func play_land() -> void:
	_blip(240.0, 0.06, 0.18)


func play_perfect() -> void:
	_blip(880.0, 0.035, 0.12)
	_blip(1240.0, 0.045, 0.09)


func play_fail() -> void:
	_blip(100.0, 0.14, 0.2)


func play_ui() -> void:
	_blip(520.0, 0.03, 0.09)


func _blip(freq: float, dur: float, amp: float) -> void:
	if _playback == null:
		_bind_playback()
	if _playback == null:
		return
	var avail := _playback.get_frames_available()
	if avail < 64:
		return
	var rate := _gen.mix_rate
	var n := mini(int(dur * rate), avail)
	for i in n:
		var t := float(i) / rate
		var env := 1.0 - t / dur
		var s := sin(TAU * freq * t) * amp * env * env
		_playback.push_frame(Vector2(s, s))
