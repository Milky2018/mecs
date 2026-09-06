///|
test "timer emits a deferred despawn when its delay elapses" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  let entity = world.spawn(key.entry(1))
  let buffer = world.command_buffer()
  let commands = buffer.emitter()
  let timers = @reference.Timers::new()
  ignore(timers.after(5.0, fn(commands) { commands.despawn(entity) }))
  timers.update(4.9, commands)
  buffer.apply()
  assert_true(world.is_alive(entity))
  timers.update(0.1, commands)
  assert_true(world.is_alive(entity))
  buffer.apply()
  assert_true(!world.is_alive(entity))
}

///|
test "timer cancellation prevents its action" {
  let world = @reference.World::new()
  let key : @reference.ComponentKey[Int] = world.component()
  let entity = world.spawn(key.entry(1))
  let buffer = world.command_buffer()
  let timers = @reference.Timers::new()
  let timer = timers.after(1.0, fn(commands) { commands.despawn(entity) })
  assert_true(timers.cancel(timer))
  assert_true(!timers.cancel(timer))
  timers.update(1.0, buffer.emitter())
  buffer.apply()
  assert_true(world.is_alive(entity))
}

///|
#valtype
priv struct TestLifetime {
  remaining : Double
}

///|
priv struct LifetimeSystem {
  query : @reference.Query2[TestLifetime, Int]
}

///|
fn LifetimeSystem::run(
  self : LifetimeSystem,
  delta_time : Double,
  commands : @reference.CommandEmitter,
) -> Unit {
  self.query.for_each_mut_a(fn(entity, lifetime, _) {
    let remaining = lifetime.remaining - delta_time
    if remaining <= 0.0 {
      commands.despawn(entity)
    }
    { remaining, }
  })
}

///|
test "a stateful system keeps its query and emits structural changes" {
  let world = @reference.World::new()
  let lifetime : @reference.ComponentKey[TestLifetime] = world.component()
  let tag : @reference.ComponentKey[Int] = world.component()
  let entity = world.spawn((lifetime.entry({ remaining: 1.0, }), tag.entry(0)))
  let system : LifetimeSystem = { query: world.query2(lifetime, tag), }
  let buffer = world.command_buffer()
  system.run(0.5, buffer.emitter())
  buffer.apply()
  assert_true(world.is_alive(entity))
  system.run(0.5, buffer.emitter())
  assert_true(world.is_alive(entity))
  buffer.apply()
  assert_true(!world.is_alive(entity))
}
