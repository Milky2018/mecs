ECS v2

`v2` avoids type-erased component storage. Components live in typed
`ComponentStore[T]` handles, resources live in typed `Resource[T]` handles, and
systems capture the handles they need.

```mbt check
///|
test {
  struct Position {
    mut x : Double
    mut y : Double
  }
  struct Velocity {
    x : Double
    y : Double
  }
  let world = @v2.World()
  let positions : @v2.ComponentStore[Position] = @v2.component_store()
  let velocities : @v2.ComponentStore[Velocity] = @v2.component_store()
  world.register_component_store(positions)
  world.register_component_store(velocities)

  let entity = world.spawn()
  ignore(world.insert_component(entity, positions, Position::{ x: 0, y: 0 }))
  ignore(world.insert_component(entity, velocities, Velocity::{ x: 1, y: -1 }))

  let movement_system = @v2.System(fn(_world : @v2.World) -> Unit {
    for row in @v2.query2(velocities, positions) {
      let (vel, pos) = row
      pos.x += vel.x
      pos.y += vel.y
    }
  })
  world.add_system(movement_system)

  world.step()
  let pos = positions.require(entity)
  inspect((pos.x, pos.y), content="(1, -1)")
}
```
