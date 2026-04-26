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
  mut x : Double
  mut y : Double
}

///|
impl @v1.Component for Velocity with component_id() {
  "velocity"
}

///|
struct Name {
  name : String
}

///|
// test "basic usage" {
//   let world = @v1.World()
//   world.spawn((Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: -1 }))
// }

///|
// test "dynamic insert component" {
//   let world = @v1.World()
//   let ent = world.spawn_entity()
//   world
//   .entity_ops(ent)
//   ..insert_component(Position::{ x: 0, y: 0 })
//   ..insert_component(Velocity::{ x: 1, y: -1 })
//   |> ignore 
  
// }

