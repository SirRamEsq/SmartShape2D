extends GutTest

func _fill_cache(cache: SS2D_MeshCache, count: int) -> Array[SS2D_Mesh]:
	cache.meshes.resize(count)

	for i in count:
		var m := SS2D_Mesh.new()
		m.z_index = i
		cache.meshes[i] = m

	return cache.meshes


func test_init_default() -> void:
	var cache := SS2D_MeshCache.new()
	assert_null(cache._owner)
	assert_true(cache.meshes.is_empty())


func test_init_owner() -> void:
	var s: SS2D_Shape = autoqfree(SS2D_Shape.new())
	var cache := SS2D_MeshCache.new(s)
	assert_eq(cache._owner, s)
	assert_true(cache.meshes.is_empty())


func test_claim_ownership_or_copy_unowned() -> void:
	var s: SS2D_Shape = autoqfree(SS2D_Shape.new())
	var cache := SS2D_MeshCache.new()
	var meshes := _fill_cache(cache, 4)

	var returned := cache.claim_ownership_or_copy(s)

	assert_eq(returned, cache)
	assert_eq(cache._owner, s)
	assert_eq(cache.meshes, meshes)


func test_claim_ownership_or_copy_owned() -> void:
	var s: SS2D_Shape = autoqfree(SS2D_Shape.new())
	var s_owner: SS2D_Shape = autoqfree(SS2D_Shape.new())
	var owned_cache := SS2D_MeshCache.new(s_owner)
	var owned_meshes := _fill_cache(owned_cache, 4)

	var returned := owned_cache.claim_ownership_or_copy(s)

	# Original should remain untouched
	assert_eq(owned_cache._owner, s_owner)
	assert_eq(owned_cache.meshes, owned_meshes)

	# New cache should be created with copied meshes
	assert_eq(returned._owner, s)
	assert_ne(returned, owned_cache)

	assert_eq(returned.meshes.size(), owned_meshes.size())
	assert_ne(returned.meshes, owned_meshes)

	for i in returned.meshes.size():
		var a := returned.meshes[i]
		var b := owned_meshes[i]
		assert_eq(a.z_index, b.z_index)  # z_index is modified by _fill_cache
		assert_ne(a.mesh, b.mesh)


func test_claim_ownership_or_copy_self_owned() -> void:
	var s: SS2D_Shape = autoqfree(SS2D_Shape.new())
	var cache := SS2D_MeshCache.new(s)
	var meshes := _fill_cache(cache, 4)

	var returned := cache.claim_ownership_or_copy(s)

	assert_eq(returned, cache)
	assert_eq(cache._owner, s)
	assert_eq(cache.meshes, meshes)


func test_mesh_buffer_get_or_create() -> void:
	var cache := SS2D_MeshCache.new()
	var mesh := SS2D_Mesh.new()
	mesh.z_index = 999
	cache.meshes.push_back(mesh)

	assert_eq(cache.mesh_buffer_get_or_create(0), mesh)
	assert_eq(cache.meshes[0].z_index, 0)
	assert_eq(cache.meshes.size(), 1)

	assert_ne(cache.mesh_buffer_get_or_create(1), mesh)
	assert_eq(cache.meshes.size(), 2)
