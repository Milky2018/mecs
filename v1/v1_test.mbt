///|
priv struct Position {
  mut x : Double
  mut y : Double
}

///|
impl HasTypeId for Position

///|
impl Component for Position

///|
priv struct Velocity {
  x : Double
  y : Double
}

///|
impl HasTypeId for Velocity

///|
impl Component for Velocity

///|
// struct Name {
//   name : String
// }

///|
// test "basic usage" {
//   let world = @v1.World()
//   world.spawn((Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: -1 }))
// }

fn move_system(world : World) -> Unit {
  let query : Iter[(Velocity, Position)] = world.query()
  for comps in query {
    let (vel, pos) = comps
    pos.x += vel.x
    pos.y += vel.y
  }
}

///|
priv struct GlobalLog {
  content : Array[String]
}

///|
impl HasTypeId for GlobalLog

///|
impl Resource for GlobalLog

///|
fn print_system(world : World) -> Unit {
  let query : Iter[Position] = world.query1()
  let log : GlobalLog = world.get_resource()
  for pos in query {
    log.content.push("{ x : \{pos.x}, y : \{pos.y} }")
  }
}

///|
test "dynamic insert component" {
  let world = @v1.World()
  world.set_resource(GlobalLog::{ content: [] })
  let ent = world.spawn_entity()
  world
  .entity_ops(ent)
  ..insert_component(Position::{ x: 0, y: 0 })
  ..insert_component(Velocity::{ x: 1, y: -1 })
  |> ignore
  world..add_system(System(move_system))..add_system(System(print_system))
  |> ignore
  world.step()
  inspect(
    (world.get_resource() : GlobalLog).content,
    content=(
      #|["{ x : 1, y : -1 }"]
    ),
  )
  world.step()
  inspect(
    (world.get_resource() : GlobalLog).content,
    content=(
      #|["{ x : 1, y : -1 }", "{ x : 2, y : -2 }"]
    ),
  )
}
