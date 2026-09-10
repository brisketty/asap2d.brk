class_name ToneStream
## Builds short procedural sine-tone `AudioStreamWAV`s. For demos and tests that
## need an audible stream without shipping audio files. Not part of the runtime
## framework - real games map real streams through ThemeProfile.

const SAMPLE_RATE := 22050


## `p_loop` skips the decay envelope and marks the WAV as forward-looping (for
## music stems / ambience beds); the tone length is snapped to a whole number of
## cycles so the loop is click-free.
static func make(
	p_frequency: float,
	p_seconds: float,
	p_volume: float = 0.4,
	p_loop: bool = false,
) -> AudioStreamWAV:
	var sample_count := maxi(int(p_seconds * SAMPLE_RATE), 1)
	if p_loop:
		var samples_per_cycle := float(SAMPLE_RATE) / maxf(p_frequency, 1.0)
		var cycles := maxi(int(float(sample_count) / samples_per_cycle), 1)
		sample_count = int(round(cycles * samples_per_cycle))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i: int in sample_count:
		var time := float(i) / float(SAMPLE_RATE)
		var envelope := 1.0 if p_loop else 1.0 - float(i) / float(sample_count)
		var sample := int(sin(TAU * p_frequency * time) * envelope * p_volume * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	if p_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream
