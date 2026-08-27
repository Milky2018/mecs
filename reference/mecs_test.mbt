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
