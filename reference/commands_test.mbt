///|
test "commands defer structural changes until apply" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  let first = world.spawn(key.entry(1))
  let buffer = world.command_buffer()
  let commands = buffer.emitter()
  world
  .query2(key, key)
  .for_each(fn(entity, _, _) {
    commands.despawn(entity)
    commands.spawn(key.entry(2))
  })
  assert_true(world.is_alive(first))
  assert_eq(world.get(first, key), Some(1))
  buffer.apply()
  assert_true(!world.is_alive(first))
  let values : Array[Int] = []
  world.query2(key, key).for_each(fn(_, value, _) { values.push(value) })
  assert_eq(values, [2])
}

///|
test "duplicate deferred despawns are harmless" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  let entity = world.spawn(key.entry(1))
  let buffer = world.command_buffer()
  let commands = buffer.emitter()
  commands.despawn(entity)
  commands.despawn(entity)
  buffer.apply()
  assert_true(!world.is_alive(entity))
}

///|
test "panic commands reject an entity from another world" {
  let first = @reference.World::new()
  let second = @reference.World::new()
  let key : @reference.ComponentKey[Int] = first.component()
  let entity = first.spawn(key.entry(1))
  second.command_buffer().emitter().despawn(entity)
}

///|
test "panic commands reject a component key from another world" {
  let first = @reference.World::new()
  let second = @reference.World::new()
  let key : @reference.ComponentKey[Int] = first.component()
  second.command_buffer().emitter().spawn(key.entry(1))
}

///|
test "panic command buffer cannot apply during a query" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  ignore(world.spawn(key.entry(1)))
  let buffer = world.command_buffer()
  world.query2(key, key).for_each(fn(_, _, _) { buffer.apply() })
}
