class_name GameEnums
extends RefCounted

## GameEnums
## Central repository for game-wide enumerations to avoid cyclic dependencies.

enum EnemyType {
	NORMAL,
	ELITE,
	BOSS
}

enum AIType {
	AGGRESSIVE,
	DEFENSIVE,
	BALANCED,
	CUNNING
}

enum EnemyFaction {
	NONE,
	ELDRITCH,
	WILDLIFE,
	LAWMAN,
	MINING
}

enum ResourceType {
	ENERGY,
	SANITY,
	GOLD,
	CUSTOM
}

enum CustomResourceType {
	NONE,
	AMMO,
	FAITH,
	FEVER,
	SCENT,
	BREW
}
