///|
test "despawn preserves columns and invalidates reused handles" {
  let world = @reference.World::new()
  let position : @reference.ComponentKey[TestPosition] = world.component()
  let health : @reference.ComponentKey[TestHealth] = world.component()
  let tag : @reference.ComponentKey[Int] = world.component()
  let a = world.spawn(
    (position.entry({ x: 1, y: 2, }), health.entry({ value: 10, })),
  )
  let b = world.spawn(
    (position.entry({ x: 3, y: 4, }), health.entry({ value: 20, })),
  )
  let c = world.spawn(
    (position.entry({ x: 5, y: 6, }), health.entry({ value: 30, })),
  )
  let query = world.query2(position, health)
  let seen : Array[@reference.Entity] = []
  query.for_each(fn(entity, _, _) { seen.push(entity) })
  assert_eq(seen, [a, b, c])
  assert_true(world.despawn(b))
  assert_true(!world.is_alive(b))
  assert_true(!world.despawn(b))
  assert_true(world.get(b, position) is None)
  guard world.get(c, position) is Some(p) else {
    fail("moved position missing")
  }
  guard world.get(c, health) is Some(h) else { fail("moved health missing") }
  assert_eq(p.x, 5)
  assert_eq(p.y, 6)
  assert_eq(h.value, 30)
  // Reuse the deleted slot in a different archetype.
  let replacement = world.spawn(tag.entry(99))
  assert_true(replacement != b)
  assert_true(world.is_alive(replacement))
  assert_true(world.get(b, tag) is None)
  assert_true(!world.despawn(b))
  assert_eq(world.get(replacement, tag), Some(99))
  seen.clear()
  let rows : Array[(Int, Int)] = []
  query.for_each(fn(entity, p, h) {
    seen.push(entity)
    rows.push((p.x, h.value))
  })
  assert_eq(seen, [a, c])
  assert_eq(rows, [(1, 10), (5, 30)])
  // Delete the moved row, then the final row; reuse the empty archetype.
  assert_true(world.despawn(c))
  assert_true(world.despawn(a))
  seen.clear()
  query.for_each(fn(entity, _, _) { seen.push(entity) })
  assert_eq(seen.length(), 0)
  let fresh = world.spawn(
    (health.entry({ value: 40, }), position.entry({ x: 7, y: 8, })),
  )
  rows.clear()
  query.for_each_batch(fn(entities, positions, healths) {
    for row in 0..<entities.length() {
      seen.push(entities[row])
      rows.push((positions[row].x, healths[row].value))
    }
  })
  assert_eq(seen, [fresh])
  assert_eq(rows, [(7, 40)])
}

///|
test "entity operations reject foreign worlds and keys" {
  let a = @reference.World::new()
  let b = @reference.World::new()
  let ka : @reference.ComponentKey[Int] = a.component()
  let kb : @reference.ComponentKey[Int] = b.component()
  let ea = a.spawn(ka.entry(1))
  let eb = b.spawn(kb.entry(2))
  assert_true(ea != eb)
  assert_true(!b.is_alive(ea))
  assert_true(!b.despawn(ea))
  assert_true(b.get(ea, kb) is None)
  assert_true(b.get(eb, ka) is None)
  assert_eq(b.get(eb, kb), Some(2))
}

///|
test "nested queries release structural mutation guard" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  let first = world.spawn(key.entry(1))
  let second = world.spawn(key.entry(2))
  let query = world.query2(key, key)
  let count = Ref(0)
  query.for_each(fn(_, _, _) { query.for_each(fn(_, _, _) { count.val += 1 }) })
  assert_eq(count.val, 4)
  assert_true(world.despawn(first))
  assert_eq(world.get(second, key), Some(2))
  query.for_each_mut_a(fn(_, a, _) { a + 1 })
  query.for_each_batch_mut_a(fn(_, values, _) {
    for row in 0..<values.length() {
      values[row] += 1
    }
  })
  assert_eq(world.get(second, key), Some(4))
  assert_true(world.despawn(second))
  assert_true(world.is_alive(world.spawn(key.entry(5))))
}

///|
test "panic despawn during query is rejected" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  ignore(world.spawn(key.entry(1)))
  world
  .query2(key, key)
  .for_each(fn(entity, _, _) { ignore(world.despawn(entity)) })
}

///|
test "panic spawn during batch query is rejected" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  ignore(world.spawn(key.entry(1)))
  world
  .query2(key, key)
  .for_each_batch(fn(_, _, _) { ignore(world.spawn(key.entry(2))) })
}
