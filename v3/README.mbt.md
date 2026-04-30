ECS v3

`v3` is native-only. It uses C FFI for the heterogeneous component and resource
registry, so `World` owns component stores without MoonBit compiler primitives
such as `%identity`.

Components and resources are stored as MoonBit object references in C `void*`
slots. `v3` uses a private `%identity` cast layer to erase and restore
`Ref[T]`, so normal component types only need a `type_id` and an empty
`Component`/`Resource` impl. Systems can mutate queried components directly.

```mbt nocheck
test {
  struct Position {
    mut x : Int
    mut y : Int
  }

  impl @v3.HasTypeId for Position with type_id() {
    "Position"
  }

  impl @v3.Component for Position

  struct Velocity {
    x : Int
    y : Int
  }

  impl @v3.HasTypeId for Velocity with type_id() {
    "Velocity"
  }

  impl @v3.Component for Velocity

  let world = @v3.World()
  let entity = world.spawn_with((
    Position::{ x: 0, y: 0 },
    Velocity::{ x: 1, y: -1 },
  ))

  world.add_system(@v3.System(fn(world : @v3.World) -> Unit {
    world.each2(fn(vel : Velocity, pos : Position) -> Unit {
      pos.x += vel.x
      pos.y += vel.y
    })
  }))

  world.step()
  let pos : Position = world.require_component(entity)
  inspect((pos.x, pos.y), content="(1, -1)")
}
```
