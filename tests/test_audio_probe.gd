extends GutTest

# AudioProbe measures captured audio (stereo frames, -1..1): peak, RMS and the
# dominant frequency among candidates (Goertzel).

const RATE := 44100.0
const EPSILON := 0.001
const CANDIDATES := [220.0, 440.0, 880.0]


func _sine(freq: float, amplitude: float, frames: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(frames)
	for i in frames:
		var v := amplitude * sin(TAU * freq * i / RATE)
		out[i] = Vector2(v, v)
	return out


func test_peak_of_half_amplitude_sine_is_half() -> void:
	assert_almost_eq(AudioProbe.peak(_sine(440.0, 0.5, 4410)), 0.5, EPSILON)


func test_rms_of_half_amplitude_sine() -> void:
	assert_almost_eq(AudioProbe.rms(_sine(440.0, 0.5, 4410)), 0.354, EPSILON)


func test_dominant_frequency_finds_the_played_tone() -> void:
	var found := AudioProbe.dominant_frequency(_sine(440.0, 0.5, 4410), RATE, CANDIDATES)
	assert_eq(found, 440.0)


func test_silence_has_zero_rms_and_peak() -> void:
	var silence := PackedVector2Array()
	silence.resize(1000)
	assert_eq(AudioProbe.rms(silence), 0.0)
	assert_eq(AudioProbe.peak(silence), 0.0)


func test_empty_buffer_measures_zero() -> void:
	var empty := PackedVector2Array()
	assert_eq(AudioProbe.rms(empty), 0.0)
	assert_eq(AudioProbe.peak(empty), 0.0)
	assert_eq(AudioProbe.dominant_frequency(empty, RATE, CANDIDATES), 0.0)
