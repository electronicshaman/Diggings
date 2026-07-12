extends RefCounted
class_name RewardOfferGenerator

static func load_candidates(root_path: String) -> Array[CardData]:
	var paths: Array[String] = []
	_collect_paths(root_path, paths)
	paths.sort()
	var cards: Array[CardData] = []
	for path in paths:
		var card := load(path) as CardData
		if card:
			cards.append(card)
	return cards

static func _collect_paths(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if not directory:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_paths(child, output)
		elif entry.ends_with(".tres"):
			output.append(child)
		entry = directory.get_next()
	directory.list_dir_end()

static func generate(character: CharacterClass, candidates: Array[CardData], count: int, rng: RandomNumberGenerator) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in candidates:
		if is_instance_valid(card) and character.can_use_card(card):
			pool.append(card)
	pool.sort_custom(func(a: CardData, b: CardData): return a.resource_path < b.resource_path)
	var offers: Array[CardData] = []
	while offers.size() < count and not pool.is_empty():
		var total_weight := 0.0
		for card in pool:
			total_weight += maxf(0.0, character.get_card_preference_weight(card))
		if total_weight <= 0.0:
			break
		var roll := rng.randf() * total_weight
		var selected_index := pool.size() - 1
		for index in range(pool.size()):
			roll -= maxf(0.0, character.get_card_preference_weight(pool[index]))
			if roll <= 0.0:
				selected_index = index
				break
		offers.append(pool[selected_index])
		pool.remove_at(selected_index)
	return offers
