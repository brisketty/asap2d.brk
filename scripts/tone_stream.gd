class_name ToneStream
## Builds short procedural sine-tone `AudioStreamWAV`s. For demos and tests that
## need an audible stream without shipping audio files. Not part of the runtime
## framework - real games map real streams through ThemeProfile.

const SAMPLE_RATE := 22050


static func make(p_frequency: float, p_seconds: float, p_volume: float = 0.4) -> AudioStreamWAV:
	var sample_count := maxi(int(p_seconds * SAMPLE_RATE), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i: int in sample_count:
		var time := float(i) / float(SAMPLE_RATE)
		var envelope := 1.0 - float(i) / float(sample_count)
		var sample := int(sin(TAU * p_frequency * time) * envelope * p_volume * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
