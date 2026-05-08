///|
priv struct Position {
  mut x : Int
  mut y : Int
}

///|
priv struct Velocity {
  x : Int
  y : Int
}

///|
priv struct Health {
  mut value : Int
}

///|
priv struct StepCount {
  value : Int
}

///|
priv struct PositionAlias {
  value : Int
}

///|
priv struct StepCountAlias {
  value : Int
}

///|
extenum @mecs.Component += {
  Position(Position)
  Velocity(Velocity)
  Health(Health)
  PositionAlias(PositionAlias)
}

///|
extenum @mecs.Resource += {
  StepCount(StepCount)
  StepCountAlias(StepCountAlias)
}

///|
impl @mecs.ComponentValue for Position with component_id() {
  ComponentId("Position")
}

///|
impl @mecs.ComponentValue for Position with to_component(self) {
  Position(self)
}

///|
impl @mecs.ComponentValue for Position with from_component(component) {
  match component {
    Position(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for Velocity with component_id() {
  ComponentId("Velocity")
}

///|
impl @mecs.ComponentValue for Velocity with to_component(self) {
  Velocity(self)
}

///|
impl @mecs.ComponentValue for Velocity with from_component(component) {
  match component {
    Velocity(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for Health with component_id() {
  ComponentId("Health")
}

///|
impl @mecs.ComponentValue for Health with to_component(self) {
  Health(self)
}

///|
impl @mecs.ComponentValue for Health with from_component(component) {
  match component {
    Health(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ResourceValue for StepCount with resource_id() {
  ResourceId("StepCount")
}

///|
impl @mecs.ResourceValue for StepCount with to_resource(self) {
  StepCount(self)
}

///|
impl @mecs.ResourceValue for StepCount with from_resource(resource) {
  match resource {
    StepCount(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for PositionAlias with component_id() {
  ComponentId("Position")
}

///|
impl @mecs.ComponentValue for PositionAlias with to_component(self) {
  PositionAlias(self)
}

///|
impl @mecs.ComponentValue for PositionAlias with from_component(component) {
  match component {
    PositionAlias(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ResourceValue for StepCountAlias with resource_id() {
  ResourceId("StepCount")
}

///|
impl @mecs.ResourceValue for StepCountAlias with to_resource(self) {
  StepCountAlias(self)
}

///|
impl @mecs.ResourceValue for StepCountAlias with from_resource(resource) {
  match resource {
    StepCountAlias(value) => Some(value)
    _ => None
  }
}

///|
fn has_position(world : @mecs.World, entity : @mecs.EntityId) -> Bool {
  let hint : Position? = None
  world.has_component(entity, _hint=hint)
}

///|
fn has_position_alias(world : @mecs.World, entity : @mecs.EntityId) -> Bool {
  let hint : PositionAlias? = None
  world.has_component(entity, _hint=hint)
}

///|
fn has_step_count(world : @mecs.World) -> Bool {
  let hint : StepCount? = None
  world.has_resource(_hint=hint)
}

///|
fn has_step_count_alias(world : @mecs.World) -> Bool {
  let hint : StepCountAlias? = None
  world.has_resource(_hint=hint)
}

///|
fn move_system(world : @mecs.World) -> Unit {
  try! world.each2(fn(vel : Velocity, pos : Position) -> Unit {
    pos.x += vel.x
    pos.y += vel.y
  })
}

///|
fn count_system(world : @mecs.World) -> Unit {
  let counter : StepCount = world.get_resource()
  world.set_resource(StepCount::{ value: counter.value + 1 })
}

///|
test "systems persist component and resource mutations" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 0 })
  let entity = world.spawn_with(
    (Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: -1 }),
  )
  world..add_system(System(move_system))..add_system(System(count_system))
  |> ignore
  world.step()
  let pos1 : Position = world.require_component(entity)
  inspect((pos1.x, pos1.y), content="(1, -1)")
  inspect((world.get_resource() : StepCount).value, content="1")
  world.step()
  let pos2 : Position = world.require_component(entity)
  inspect((pos2.x, pos2.y), content="(2, -2)")
  inspect((world.get_resource() : StepCount).value, content="2")
}

///|
test "each3 persists component mutations" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 1 }, Velocity::{ x: 2, y: 3 }, Health::{ value: 4 }),
  )
  try! world.each3(fn(vel : Velocity, pos : Position, health : Health) -> Unit {
    pos.x += vel.x
    pos.y += vel.y
    health.value += 10
  })
  let pos : Position = world.require_component(entity)
  let health : Health = world.require_component(entity)
  inspect((pos.x, pos.y, health.value), content="(3, 4, 14)")
}

///|
test "each2 snapshots rows and keeps nonqueried structural changes" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 1 }, Velocity::{ x: 0, y: 0 }, Health::{ value: 1 }),
  )
  let visited = Ref(0)
  try! world.each2(fn(_vel : Velocity, _pos : Position) -> Unit {
    visited.val += 1
    ignore(
      world.spawn_with((Position::{ x: 9, y: 9 }, Velocity::{ x: 1, y: 1 })),
    )
    world.remove_component(entity, _hint=(None : Health?))
  })
  let rows : Array[(Velocity, Position)] = world.query().to_array()
  let health : Health? = world.get_component(entity)
  inspect(visited.val, content="1")
  inspect(rows.length(), content="2")
  inspect(health is Some(_), content="false")
}

///|
test "each2 reports not spawned when yielded entity is despawned before writeback" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 1 }, Velocity::{ x: 0, y: 0 }),
  )
  let result = try? world.each2(fn(_vel : Velocity, _pos : Position) -> Unit {
    ignore(world.despawn(entity))
  })
  inspect(
    match result {
      Err(NotSpawned(id)) => id == entity
      _ => false
    },
    content="true",
  )
}

///|
test "despawn removes extensible enum components" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 3, y: 4 }, Velocity::{ x: 0, y: 0 }),
  )
  let before : Position? = world.get_component(entity)
  inspect(before is Some(_), content="true")
  inspect(world.despawn(entity), content="true")
  inspect(world.is_alive(entity), content="false")
  let after_pos : Position? = world.get_component(entity)
  let after_vel : Velocity? = world.get_component(entity)
  inspect(after_pos is Some(_), content="false")
  inspect(after_vel is Some(_), content="false")
}

///|
test "query3 only yields entities with all requested components" {
  let world = @mecs.World()
  let complete = world.spawn_with(
    (Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: 2 }, Health::{ value: 7 }),
  )
  let partial = world.spawn_with(
    (Position::{ x: 5, y: 5 }, Health::{ value: 3 }),
  )
  ignore(partial)
  let rows : Array[(@mecs.EntityId, (Position, Velocity, Health))] = world
    .query3_entities()
    .to_array()
  inspect(rows.length(), content="1")
  let (entity, (pos, vel, hp)) = rows[0]
  inspect(entity == complete, content="true")
  inspect((pos.x, pos.y, vel.x, vel.y, hp.value), content="(0, 0, 1, 2, 7)")
}

///|
test "entity ops can dynamically add components" {
  let world = @mecs.World()
  let entity = world.spawn()
  let ops = world.entity_ops(entity)
  try! ops.insert_component(Position::{ x: 1, y: 2 })
  try! ops.insert_component(Velocity::{ x: 3, y: 4 })
  let rows : Array[(Velocity, Position)] = world.query().to_array()
  inspect(rows.length(), content="1")
  let (vel, pos) = rows[0]
  inspect((pos.x, pos.y, vel.x, vel.y), content="(1, 2, 3, 4)")
}

///|
test "entity ops insert reports dead entity failure" {
  let world = @mecs.World()
  let ops = world.entity_ops(99)
  let result = try? ops.insert_component(Position::{ x: 0, y: 0 })
  inspect(
    match result {
      Err(NotSpawned(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
}

///|
test "component ids are opaque and use variant names" {
  let id : @mecs.ComponentId = ComponentId("Position")
  inspect(id.name(), content="Position")
  let resource_id : @mecs.ResourceId = ResourceId("StepCount")
  inspect(resource_id.name(), content="StepCount")
}

///|
test "component id collision overwrites one storage slot" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 2 }, Velocity::{ x: 0, y: 0 }),
  )
  inspect(has_position(world, entity), content="true")
  inspect(has_position_alias(world, entity), content="false")
  try! world.insert_component(entity, PositionAlias::{ value: 42 })
  let position : Position? = world.get_component(entity)
  let alias_pos : PositionAlias? = world.get_component(entity)
  inspect(position is Some(_), content="false")
  inspect(alias_pos is Some(_), content="true")
  inspect(
    match alias_pos {
      Some(value) => value.value
      None => -1
    },
    content="42",
  )
  inspect(has_position(world, entity), content="false")
  inspect(has_position_alias(world, entity), content="true")
}

///|
test "resource id collision overwrites one storage slot" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 1 })
  inspect(has_step_count(world), content="true")
  inspect(has_step_count_alias(world), content="false")
  world.set_resource(StepCountAlias::{ value: 9 })
  let counter : StepCount? = world.try_get_resource()
  let alias_resource : StepCountAlias? = world.try_get_resource()
  inspect(counter is Some(_), content="false")
  inspect(alias_resource is Some(_), content="true")
  inspect(
    match alias_resource {
      Some(value) => value.value
      None => -1
    },
    content="9",
  )
  inspect(has_step_count(world), content="false")
  inspect(has_step_count_alias(world), content="true")
}

///|
test "missing entity reads are safe and insert reports not spawned" {
  let world = @mecs.World()
  inspect(world.is_alive(99), content="false")
  let result = try? world.insert_component(99, Position::{ x: 1, y: 1 })
  inspect(
    match result {
      Err(NotSpawned(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  let pos : Position? = world.get_component(99)
  inspect(pos is Some(_), content="false")
  inspect(has_position(world, 99), content="false")
  let counter : StepCount? = world.try_get_resource()
  inspect(counter is Some(_), content="false")
  inspect(has_step_count(world), content="false")
}

///|
test "removed component and resource APIs return absence" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 7, y: 8 }, Velocity::{ x: 0, y: 0 }),
  )
  world.set_resource(StepCount::{ value: 3 })
  inspect(has_position(world, entity), content="true")
  inspect(has_step_count(world), content="true")
  world.remove_component(entity, _hint=(None : Position?))
  world.remove_resource(_hint=(None : StepCount?))
  inspect(has_position(world, entity), content="false")
  inspect(has_step_count(world), content="false")
  let pos : Position? = world.get_component(entity)
  let count : StepCount? = world.try_get_resource()
  inspect(pos is Some(_), content="false")
  inspect(count is Some(_), content="false")
}
