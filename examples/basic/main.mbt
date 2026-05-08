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
priv struct Frame {
  value : Int
}

///|
extenum @mecs.Component += {
  Position(Position)
  Velocity(Velocity)
}

///|
extenum @mecs.Resource += {
  Frame(Frame)
}

///|
impl @mecs.ComponentValue for Position with component_id() {
  @mecs.component_id("Position")
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
  @mecs.component_id("Velocity")
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
impl @mecs.ResourceValue for Frame with resource_id() {
  @mecs.resource_id("Frame")
}

///|
impl @mecs.ResourceValue for Frame with to_resource(self) {
  Frame(self)
}

///|
impl @mecs.ResourceValue for Frame with from_resource(resource) {
  match resource {
    Frame(value) => Some(value)
    _ => None
  }
}

///|
fn move_system(world : @mecs.World) -> Unit {
  try! world.each2(fn(velocity : Velocity, position : Position) -> Unit {
    position.x += velocity.x
    position.y += velocity.y
  })
}

///|
fn tick_system(world : @mecs.World) -> Unit {
  let frame : Frame = world.get_resource()
  world.set_resource(Frame::{ value: frame.value + 1 })
}

///|
fn build_world() -> (@mecs.World, @mecs.EntityId) {
  let world = @mecs.World()
  world.set_resource(Frame::{ value: 0 })
  let entity = world.spawn_with(
    (Position::{ x: 0, y: 0 }, Velocity::{ x: 2, y: -1 }),
  )
  world
  ..add_system(System(move_system, name="move"))
  ..add_system(System(tick_system, name="tick"))
  |> ignore
  (world, entity)
}

///|
test "basic example runs systems" {
  let (world, entity) = build_world()
  try! world.step()
  let position : Position = world.get_component_checked(entity)
  let frame : Frame = world.get_resource_checked()
  inspect((position.x, position.y, frame.value), content="(2, -1, 1)")
}
