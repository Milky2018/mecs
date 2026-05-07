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
  value : Int
}

///|
priv struct StepCount {
  value : Int
}

///|
extenum @mecs.Component += {
  Position(Position)
  Velocity(Velocity)
  Health(Health)
}

///|
extenum @mecs.Resource += {
  StepCount(StepCount)
}

///|
impl @mecs.ComponentValue for Position with component_id() {
  "Position"
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
  "Velocity"
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
  "Health"
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
  "StepCount"
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
fn move_system(world : @mecs.World) -> Unit {
  world.each2(fn(vel : Velocity, pos : Position) -> Unit {
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
test "world stores extensible enum components and resources" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 0 })
  let moving = world.spawn_with(
    (Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: -1 }, Health::{ value: 10 }),
  )
  let standing = world.spawn()
  ignore(world.insert_component(standing, Position::{ x: 10, y: 10 }))
  let moving_pos : Position? = world.get_component(moving)
  let moving_vel : Velocity? = world.get_component(moving)
  let standing_vel : Velocity? = world.get_component(standing)
  inspect(moving_pos is Some(_), content="true")
  inspect(moving_vel is Some(_), content="true")
  inspect(standing_vel is Some(_), content="false")
  world..add_system(System(move_system))..add_system(System(count_system))
  |> ignore
  world.step()
  let pos1 : Position = world.require_component(moving)
  inspect((pos1.x, pos1.y), content="(1, -1)")
  inspect((world.get_resource() : StepCount).value, content="1")
  world.step()
  let pos2 : Position = world.require_component(moving)
  inspect((pos2.x, pos2.y), content="(2, -2)")
  inspect((world.get_resource() : StepCount).value, content="2")
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
  let rows : Array[(@mecs.EntityId, Position, Velocity, Health)] = world
    .query3_entities()
    .to_array()
  inspect(rows.length(), content="1")
  let (entity, pos, vel, hp) = rows[0]
  inspect(entity == complete, content="true")
  inspect((pos.x, pos.y, vel.x, vel.y, hp.value), content="(0, 0, 1, 2, 7)")
}

///|
test "entity ops can dynamically add components" {
  let world = @mecs.World()
  let entity = world.spawn()
  world
  .entity_ops(entity)
  ..insert_component(Position::{ x: 1, y: 2 })
  ..insert_component(Velocity::{ x: 3, y: 4 })
  |> ignore
  let rows : Array[(Velocity, Position)] = world.query().to_array()
  inspect(rows.length(), content="1")
  let (vel, pos) = rows[0]
  inspect((pos.x, pos.y, vel.x, vel.y), content="(1, 2, 3, 4)")
}
