extends Node
# Tool to migrate legacy .tres resources to unified EffectHandler types.
# Run from editor or via a small entrypoint.

var mapping := {
	# "LegacyClassName": {"type": "health", "field_map": {"heal_amount": "amount"}},
}

func migrate_resource(res: Resource) -> Resource:
	# TODO: detect type and map to new effect Resource
	return res

func migrate_all_in_dir(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var path = dir_path.path_join(fname)
			var res = ResourceLoader.load(path)
			if res:
				var migrated = migrate_resource(res)
				ResourceSaver.save(path, migrated)
		fname = dir.get_next()
	dir.list_dir_end()
