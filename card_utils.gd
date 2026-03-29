class_name CardUtils
enum Suit {
	NEUTRAL = -1,
	GOLD = 0,
	CUPS = 1,
	SWORDS = 2,
	CLUBS = 3
}
static func gen_card(value:int, suit:int) -> Dictionary:
	return {
		value = value,
		suit = suit as Suit
	}
static func gen_garbage_card(rng: RandomNumberGenerator) -> Dictionary:
	return { value = rng.randi_range(1, 10), suit = Suit.NEUTRAL }

static func is_garbage(card: Dictionary) -> bool:
	if card != {}:
		return card["suit"] == Suit.NEUTRAL
	return true

static func is_jolly(card: Dictionary) -> bool:
	return card["value"] == 11
