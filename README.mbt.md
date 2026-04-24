# Milky2018/mecs

An experimental ECS (Entity-Component-System) library in MoonBit. 

```mbt check 
struct Position {
  mut x : Double 
  mut y : Double 
}

struct Velocity {
  mut x : Double 
  mut y : Double 
}

struct Name {
  name : String 
}

///|
test "basic usage" {
  let world = @mecs.World()
  world.spawn((Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: -1 }))

}

///|
test "dynamic insert component" {
  let world = @mecs.World()
  let ent = world.spawn_entity()
  world
  .entity_ops(ent)
  .insert_component(Position::{ x: 0, y: 0 })
  ..insert_component(Velocity::{ x: 1, y: -1 })
}
```