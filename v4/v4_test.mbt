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
extenum @v4.Component += {
  Position(Position)
  Velocity(Velocity)
  Health(Health)
}

///|
extenum @v4.Resource += {
  StepCount(StepCount)
}

///|
impl @v4.ComponentValue for Position with component_id() {
  "Position"
}

///|
impl @v4.ComponentValue for Position with to_component(self) {
  @v4.Component::Position(self)
}

///|
impl @v4.ComponentValue for Position with from_component(component) {
  match component {
    Position(value) => Some(value)
    _ => None
  }
}

///|
impl @v4.ComponentValue for Velocity with component_id() {
  "Velocity"
}

///|
impl @v4.ComponentValue for Velocity with to_component(self) {
  @v4.Component::Velocity(self)
}

///|
impl @v4.ComponentValue for Velocity with from_component(component) {
  match component {
    Velocity(value) => Some(value)
    _ => None
  }
}

///|
impl @v4.ComponentValue for Health with component_id() {
  "Health"
}

///|
impl @v4.ComponentValue for Health with to_component(self) {
  @v4.Component::Health(self)
}

///|
impl @v4.ComponentValue for Health with from_component(component) {
  match component {
    Health(value) => Some(value)
    _ => None
  }
}

///|
impl @v4.ResourceValue for StepCount with resource_id() {
  "StepCount"
}

///|
impl @v4.ResourceValue for StepCount with to_resource(self) {
  @v4.Resource::StepCount(self)
}

///|
impl @v4.ResourceValue for StepCount with from_resource(resource) {
  match resource {
    StepCount(value) => Some(value)
    _ => None
  }
}

///|
fn move_system(world : @v4.World) -> Unit {
  world.each2(fn(vel : Velocity, pos : Position) -> Unit {
    pos.x += vel.x
    pos.y += vel.y
  })
}

///|
fn count_system(world : @v4.World) -> Unit {
  let counter : StepCount = world.get_resource()
  world.set_resource(StepCount::{ value: counter.value + 1 })
}

///|
test "world stores extensible enum components and resources" {
  let world = @v4.World()
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
  world
  ..add_system(@v4.System(move_system))
  ..add_system(@v4.System(count_system))
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
  let world = @v4.World()
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
  let world = @v4.World()
  let complete = world.spawn_with(
    (Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: 2 }, Health::{ value: 7 }),
  )
  let partial = world.spawn_with(
    (Position::{ x: 5, y: 5 }, Health::{ value: 3 }),
  )
  ignore(partial)
  let rows : Array[(@v4.EntityId, Position, Velocity, Health)] = world
    .query3_entities()
    .to_array()
  inspect(rows.length(), content="1")
  let (entity, pos, vel, hp) = rows[0]
  inspect(entity == complete, content="true")
  inspect((pos.x, pos.y, vel.x, vel.y, hp.value), content="(0, 0, 1, 2, 7)")
}

///|
test "entity ops can dynamically add components" {
  let world = @v4.World()
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
