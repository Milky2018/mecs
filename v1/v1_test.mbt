///|
priv struct Position {
  mut x : Double
  mut y : Double
}

///|
impl @v1.Component for Position with component_id() {
  "position"
}

///|
priv struct Velocity {
  x : Double
  y : Double
}

///|
impl @v1.Component for Velocity with component_id() {
  "velocity"
}

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
let global_log : Array[String] = []

///|
fn print_system(world : World) -> Unit {
  let query : Iter[Position] = world.query1()
  for pos in query {
    global_log.push("x : \{pos.x}, y : \{pos.y}")
  }
}

///|
test "dynamic insert component" {
  let world = @v1.World()
  let ent = world.spawn_entity()
  world
  .entity_ops(ent)
  ..insert_component(Position::{ x: 0, y: 0 })
  ..insert_component(Velocity::{ x: 1, y: -1 })
  |> ignore
  world..add_system(System(move_system))..add_system(System(print_system))
  |> ignore
  world.step()
  inspect(global_log)
  world.step()
  inspect(global_log)
}
