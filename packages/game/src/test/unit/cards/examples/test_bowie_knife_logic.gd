extends GdUnitTestSuite
class_name TestBowieKnifeLogic

var _player_data: PlayerData
var _enemy_data: EnemyState
var _card_resolver: CardResolver
var _duel_state: DuelState
var _duel_manager: DuelManager

const BOWIE_KNIFE_PATH = "res://data/cards/player/attack/bowie_knife.tres"

func before_test():
	# Setup isolated environment
	_player_data = auto_free(PlayerData.new())
	
	# Setup Enemy
	_enemy_data = auto_free(EnemyState.new())
	# Manually init stats if needed, though EnemyState._init does it
	if not _enemy_data.stats:
		_enemy_data.stats = auto_free(Stats.new())
	
	_duel_state = auto_free(DuelState.new())
	_duel_state.player_data = _player_data
	_duel_state.enemy_data = _enemy_data
	
	# Set up minimal DuelManager (not added to tree, so _ready logic skipped)
	_duel_manager = auto_free(DuelManager.new())
	_duel_manager.duel_state = _duel_state
	
	# Initialize resolver with dependencies
	_card_resolver = auto_free(CardResolver.new(_duel_state, _duel_manager))

func test_bowie_knife_bonus_damage():
	# Load the actual card resource
	var card_data = load(BOWIE_KNIFE_PATH)
	var instance = auto_free(CardInstance.new(card_data))
	
	# Setup initial state
	_enemy_data.stats.max_health = 20
	_enemy_data.stats.current_health = 20
	_enemy_data.stats.defense = 0
	
	# Verify initial assumptions
	assert_int(_enemy_data.current_health).is_equal(20)
	
	# Play card as FIRST card (bonus condition met)
	# cards_played_before = 0
	_card_resolver.resolve_card(instance, true, 0)
	
	# Verify damage
	# Bowie Knife: Deal 4. Quick Draw: +2 (Total 6).
	assert_int(_enemy_data.current_health).is_equal(14)

func test_bowie_knife_base_damage():
	var card_data = load(BOWIE_KNIFE_PATH)
	var instance = auto_free(CardInstance.new(card_data))
	
	# Setup initial state
	_enemy_data.stats.max_health = 20
	_enemy_data.stats.current_health = 20
	
	# Play card as SECOND card (bonus condition FAILED)
	# cards_played_before = 1
	# Must also update player data as HandlerCondition falls back to it
	_player_data.cards_played_this_turn = 1
	_card_resolver.resolve_card(instance, true, 1)
	
	# Verify damage
	# Bowie Knife base: 4
	assert_int(_enemy_data.current_health).is_equal(16)
	
func test_resource_validity():
	var card_data = load(BOWIE_KNIFE_PATH)
	assert_object(card_data).is_not_null()
	assert_str(card_data.card_name).is_equal("Bowie Knife")
	assert_int(card_data.energy_cost).is_equal(1)
	assert_str(card_data.card_type).is_equal("Attack")
