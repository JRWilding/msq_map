extends OmniLight3D

@export var torchStr := 1.0
@export var noise: NoiseTexture2D
var time_passed = 0.0
var random := RandomNumberGenerator.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta
	var sampled_noise = noise.noise.get_noise_1d(time_passed)
	sampled_noise = abs(sampled_noise)
	
	#var r = random.randf()
	light_energy = torchStr * lerpf(0.6, 1, sampled_noise)
