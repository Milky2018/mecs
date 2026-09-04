///|
test "slot reuse increments generation without changing old handles" {
  let world = World::new()
  let key : ComponentKey[Int] = world.component()
  let old = world.spawn(key.entry(1))
  assert_true(world.despawn(old))
  let fresh = world.spawn(key.entry(2))
  assert_eq(old.index, fresh.index)
  assert_eq(fresh.generation, old.generation + 1UL)
  assert_eq(world.slots.length(), 1)
  assert_true(!world.is_alive(old))
}

///|
test "exhausted generation retires its slot" {
  let world = World::new()
  let key : ComponentKey[Int] = world.component()
  let original = world.spawn(key.entry(1))
  let exhausted = Entity::{
    world_id: original.world_id,
    index: original.index,
    generation: 0xffffffffffffffffUL,
  }
  world.slots[original.index].generation = exhausted.generation
  world.archetypes[0].entities[0] = exhausted
  assert_true(world.despawn(exhausted))
  let fresh = world.spawn(key.entry(2))
  assert_true(fresh.index != exhausted.index)
  assert_true(!world.is_alive(original))
  assert_true(!world.is_alive(exhausted))
  assert_true(world.get(exhausted, key) is None)
}
