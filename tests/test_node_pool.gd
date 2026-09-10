extends SceneTree

const NodePoolScript := preload("res://prefabs/node_pool.gd")


func make_leaf_scene() -> PackedScene:
	var leaf := Node2D.new()
	leaf.name = "Leaf"
	var packed := PackedScene.new()
	packed.pack(leaf)
	leaf.free()
	return packed


func _initialize() -> void:
	var failure_count := 0

	var pool: Node = NodePoolScript.new()
	pool.pool_scene = make_leaf_scene()
	pool.pool_prewarm_count = 3
	pool.pool_max_count = 4

	pool.prewarm()
	pool.prewarm()
	failure_count += expect_int("prewarm fills available and does not overshoot on repeat", pool.available.size(), 3)

	var a: Node = pool.acquire()
	var b: Node = pool.acquire()
	failure_count += expect_true("acquired node is parented to pool", a.get_parent() == pool)
	failure_count += expect_int("acquire draws from available", pool.available.size(), 1)
	failure_count += expect_int("two nodes in use", pool.in_use.size(), 2)

	pool.release(a)
	failure_count += expect_int("release returns node to available", pool.available.size(), 2)
	failure_count += expect_int("released node leaves in_use", pool.in_use.size(), 1)
	failure_count += expect_true("released node detached from pool", a.get_parent() == null)

	pool.release(a)
	failure_count += expect_int("double release is a no-op", pool.available.size(), 2)

	# Drain to the ceiling, then one more must recycle the oldest in-use node.
	var acquired: Array[Node] = [b]
	while acquired.size() < pool.pool_max_count:
		acquired.append(pool.acquire())
	failure_count += expect_int("at ceiling, in_use == max", pool.in_use.size(), pool.pool_max_count)
	var oldest: Node = acquired[0]
	var recycled: Node = pool.acquire()
	failure_count += expect_true("ceiling acquire recycles oldest in-use", recycled == oldest)
	failure_count += expect_int("in_use stays at ceiling", pool.in_use.size(), pool.pool_max_count)

	pool.clear_pool()
	failure_count += expect_int("clear empties available", pool.available.size(), 0)
	failure_count += expect_int("clear empties in_use", pool.in_use.size(), 0)
	pool.free()

	if failure_count > 0:
		push_error("%d node-pool test(s) failed." % failure_count)
		quit(1)
		return
	print("All node-pool tests passed.")
	quit(0)


func expect_int(p_label: String, p_actual: int, p_expected: int) -> int:
	if p_actual == p_expected:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s (expected %d, got %d)" % [p_label, p_expected, p_actual])
	return 1


func expect_true(p_label: String, p_actual: bool) -> int:
	if p_actual:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s" % p_label)
	return 1
