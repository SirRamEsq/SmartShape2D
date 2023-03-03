var are_equal = null : get = get_are_equal, set = set_are_equal
var summary = null : get = get_summary, set = set_summary
var max_differences = 30 : get = get_max_differences, set = set_max_differences
var differences = {} : get = get_differences, set = set_differences

func _block_set(which, val):
	push_error(str('cannot set ', which, ', value [', val, '] ignored.'))

func _to_string():
	return str(get_summary()) # could be null, gotta str it.

func get_are_equal():
	return are_equal

func set_are_equal(r_eq):
	are_equal = r_eq

func get_summary():
	return summary

func set_summary(smry):
	summary = smry

func get_total_count():
	pass

func get_different_count():
	pass

func get_short_summary():
	return summary

func get_max_differences():
	return max_differences

func set_max_differences(max_diff):
	max_differences = max_diff

func get_differences():
	return differences

func set_differences(diffs):
	_block_set('differences', diffs)

func get_brackets():
	return null

