///|
#valtype
priv struct TestPosition {
  x : Int
  y : Int
}

///|
#valtype
priv struct TestVelocity {
  x : Int
  y : Int
}

///|
priv struct TestHealth {
  value : Int
}

///|
test "query2 keeps archetype rows aligned and refreshes new matches" {
  let world = @reference.World::new()
  let position : @reference.ComponentKey[TestPosition] = world.component()
  let velocity : @reference.ComponentKey[TestVelocity] = world.component()
  let health : @reference.ComponentKey[TestHealth] = world.component()
  let first = world.spawn(
    (position.entry({ x: 1, y: 2, }), velocity.entry({ x: 3, y: 4, })),
  )
  let query = world.query2(position, velocity)
  ignore(
    world.spawn(
      (
        (position.entry({ x: 10, y: 20, }), velocity.entry({ x: 1, y: 2, })),
        health.entry({ value: 100, }),
      ),
    ),
  )
  let count = Ref(0)
  query.for_each(fn(_, _, _) { count.val += 1 })
  assert_eq(count.val, 2)
  query.for_each_batch_mut_a(fn(_, positions, velocities) {
    for i in 0..<positions.length() {
      let p = positions[i]
      let v = velocities[i]
      positions[i] = { x: p.x + v.x, y: p.y + v.y, }
    }
  })
  guard world.get(first, position) is Some(updated) else {
    fail("position missing after batch write")
  }
  assert_eq(updated.x, 4)
  assert_eq(updated.y, 6)
}

///|
test "ordinary components use the same typed query path" {
  let world = @reference.World::new()
  let position : @reference.ComponentKey[TestHealth] = world.component()
  let velocity : @reference.ComponentKey[TestHealth] = world.component()
  ignore(
    world.spawn((position.entry({ value: 2, }), velocity.entry({ value: 5, }))),
  )
  let total = Ref(0)
  world
  .query2(position, velocity)
  .for_each(fn(_, a, b) { total.val += a.value + b.value })
  assert_eq(total.val, 7)
}

///|
test "panic spawn rejects a component key from another world" {
  let first = @reference.World::new()
  let second = @reference.World::new()
  let position : @reference.ComponentKey[TestPosition] = first.component()
  ignore(second.spawn(position.entry({ x: 1, y: 2, })))
}

///|
test "bitmask distinguishes archetypes across all 64 component ids" {
  let world = @reference.World::new()
  let keys : Array[@reference.ComponentKey[Int]] = []
  for _ in 0..<64 {
    keys.push(world.component())
  }
  ignore(world.spawn((keys[0].entry(1), keys[1].entry(2))))
  ignore(world.spawn((keys[0].entry(3), keys[1].entry(4))))
  ignore(world.spawn((keys[0].entry(10), keys[63].entry(20))))
  let old_archetype_count = Ref(0)
  world
  .query2(keys[0], keys[1])
  .for_each(fn(_, _, _) { old_archetype_count.val += 1 })
  assert_eq(old_archetype_count.val, 2)
  let total = Ref(0)
  world.query2(keys[0], keys[63]).for_each(fn(_, a, b) { total.val += a + b })
  assert_eq(total.val, 30)
}

///|
test "panic a world rejects a 65th component type" {
  let world = @reference.World::new()
  for _ in 0..<64 {
    let _ : @reference.ComponentKey[Int] = world.component()
  }
  let _ : @reference.ComponentKey[Int] = world.component()
}
