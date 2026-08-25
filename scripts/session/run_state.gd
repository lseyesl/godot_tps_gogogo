extends Node

var current_seed: int = 0
var has_active_seed := false

func get_or_create_seed() -> int:
	if not has_active_seed:
		begin_new_game()
	return current_seed

func begin_new_game() -> int:
	var generator := RandomNumberGenerator.new()
	generator.randomize()
	current_seed = int(generator.randi())
	if current_seed == 0:
		current_seed = 1
	has_active_seed = true
	return current_seed

func begin_new_game_with_seed(seed_value: int) -> int:
	current_seed = seed_value
	has_active_seed = true
	return current_seed

func retry_current_game() -> int:
	return get_or_create_seed()
