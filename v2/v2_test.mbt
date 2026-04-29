///|
priv struct Position {
  mut x : Double
  mut y : Double
}

///|
priv struct Velocity {
  x : Double
  y : Double
}

///|
priv struct Health {
  value : Int
}

///|
priv struct GlobalLog {
  content : Array[String]
}

///|
test "typed stores support movement systems and resources" {
  let world = @v2.World()
  let positions : @v2.ComponentStore[Position] = @v2.component_store()
  let velocities : @v2.ComponentStore[Velocity] = @v2.component_store()
  let log : @v2.Resource[GlobalLog] = @v2.resource()
  world.register_component_store(positions)
  world.register_component_store(velocities)
  log.set(GlobalLog::{ content: [] })
  let moving = world.spawn()
  ignore(world.insert_component(moving, positions, Position::{ x: 0, y: 0 }))
  ignore(world.insert_component(moving, velocities, Velocity::{ x: 1, y: -1 }))
  let standing = world.spawn()
  ignore(
    world.insert_component(standing, positions, Position::{ x: 10, y: 10 }),
  )
  let movement_system = @v2.System(fn(_world : @v2.World) -> Unit {
    for row in @v2.query2(velocities, positions) {
      let (vel, pos) = row
      pos.x += vel.x
      pos.y += vel.y
    }
  })
  world.add_system(movement_system)
  let print_system = @v2.System(fn(_world : @v2.World) -> Unit {
    let global_log = log.get()
    for pos in @v2.query1(positions) {
      global_log.content.push("{ x : \{pos.x}, y : \{pos.y} }")
    }
  })
  world.add_system(print_system)
  world.step()
  inspect(
    log.get().content,
    content=(
      #|["{ x : 1, y : -1 }", "{ x : 10, y : 10 }"]
    ),
  )
  world.step()
  inspect(
    log.get().content,
    content=(
      #|["{ x : 1, y : -1 }", "{ x : 10, y : 10 }", "{ x : 2, y : -2 }", "{ x : 10, y : 10 }"]
    ),
  )
}

///|
test "despawn cleans registered component stores" {
  let world = @v2.World()
  let positions : @v2.ComponentStore[Position] = @v2.component_store()
  let health : @v2.ComponentStore[Health] = @v2.component_store()
  world.register_component_store(positions)
  world.register_component_store(health)
  let entity = world.spawn()
  ignore(world.insert_component(entity, positions, Position::{ x: 3, y: 4 }))
  ignore(world.insert_component(entity, health, Health::{ value: 10 }))
  inspect(positions.contains(entity), content="true")
  inspect(health.contains(entity), content="true")
  inspect(world.despawn(entity), content="true")
  inspect(world.is_alive(entity), content="false")
  inspect(positions.contains(entity), content="false")
  inspect(health.contains(entity), content="false")
  inspect(world.despawn(entity), content="false")
}

///|
test "query3 only yields entities with all requested components" {
  let world = @v2.World()
  let positions : @v2.ComponentStore[Position] = @v2.component_store()
  let velocities : @v2.ComponentStore[Velocity] = @v2.component_store()
  let health : @v2.ComponentStore[Health] = @v2.component_store()
  let complete = world.spawn()
  ignore(world.insert_component(complete, positions, Position::{ x: 0, y: 0 }))
  ignore(world.insert_component(complete, velocities, Velocity::{ x: 1, y: 2 }))
  ignore(world.insert_component(complete, health, Health::{ value: 7 }))
  let partial = world.spawn()
  ignore(world.insert_component(partial, positions, Position::{ x: 5, y: 5 }))
  ignore(world.insert_component(partial, health, Health::{ value: 3 }))
  let rows = @v2.query3_entities(positions, velocities, health).to_array()
  inspect(rows.length(), content="1")
  let (entity, pos, vel, hp) = rows[0]
  inspect(entity == complete, content="true")
  inspect((pos.x, pos.y, vel.x, vel.y, hp.value), content="(0, 0, 1, 2, 7)")
}
