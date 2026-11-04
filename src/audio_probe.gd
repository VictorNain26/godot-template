class_name AudioProbe

## Measures captured audio frames (stereo, -1..1, e.g. from AudioEffectCapture)
## so a test or /verify can check what the game actually plays.


static func peak(frames: PackedVector2Array) -> float:
	var top := 0.0
	for f in frames:
		top = maxf(top, maxf(absf(f.x), absf(f.y)))
	return top


static func rms(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 0.0
	var sum := 0.0
	for f in frames:
		var mono := (f.x + f.y) * 0.5
		sum += mono * mono
	return sqrt(sum / frames.size())


## Candidate frequency with the most energy, by the Goertzel algorithm;
## 0.0 for an empty buffer.
static func dominant_frequency(frames: PackedVector2Array, rate: float, candidates: Array) -> float:
	if frames.is_empty():
		return 0.0
	var best := 0.0
	var best_power := -1.0
	for candidate: float in candidates:
		var power := _goertzel_power(frames, rate, candidate)
		if power > best_power:
			best_power = power
			best = candidate
	return best


static func _goertzel_power(frames: PackedVector2Array, rate: float, freq: float) -> float:
	var coeff := 2.0 * cos(TAU * freq / rate)
	var s1 := 0.0
	var s2 := 0.0
	for f in frames:
		var s0 := (f.x + f.y) * 0.5 + coeff * s1 - s2
		s2 = s1
		s1 = s0
	return s1 * s1 + s2 * s2 - coeff * s1 * s2
