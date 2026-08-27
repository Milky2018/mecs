///|
test "archived package smoke" {
  let world = @archived.World()
  let entity = world.spawn()
  assert_true(world.is_alive(entity))
  assert_true(world.despawn(entity))
  assert_true(!world.is_alive(entity))
}
