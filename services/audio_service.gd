extends Node
var enabled = true
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var tones = {}

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	tones.clear()

func _ready() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	music.stream = synth(130.81, 8.0, true)
	music.volume_db = -22
	music.play()
	for i in range(4):
		var voice = AudioStreamPlayer.new()
		voice.bus = "SFX"
		voice.volume_db = -13
		add_child(voice)
		voices.append(voice)
	for event in ["tap", "select", "fold", "invalid", "receiver", "complete", "hint", "unlock"]:
		var frequency = {"tap": 523.25, "select": 659.25, "fold": 392.0, "invalid": 196.0, "receiver": 783.99, "complete": 1046.5, "hint": 587.33, "unlock": 880.0}[event]
		tones[event] = synth(frequency, 0.45 if event == "complete" else 0.14, false)

func settings(value: Dictionary) -> void:
	enabled = value.sfx
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not value.music)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not value.sfx)

func play(event: String) -> void:
	if not enabled or not tones.has(event): return
	for voice in voices:
		if not voice.playing:
			voice.stream = tones[event]
			voice.play()
			return

func synth(frequency: float, duration: float, loop: bool) -> AudioStreamWAV:
	var rate = 22050
	var count = int(duration * rate)
	var samples = PackedByteArray()
	samples.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var envelope = pow(sin(PI * t / duration), 2) if loop else minf(t * 90, 1) * exp(-t * 18)
		var sample = sin(TAU * frequency * t) * 0.45 + sin(TAU * frequency * 1.5 * t) * 0.16
		samples.encode_s16(i * 2, int(sample * envelope * 26000))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = samples
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream
