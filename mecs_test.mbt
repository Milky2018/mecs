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
  mut value : Int
}

///|
priv struct Mana {
  value : Int
}

///|
priv struct Armor {
  value : Int
}

///|
priv struct StepCount {
  value : Int
}

///|
priv struct PositionAlias {
  value : Int
}

///|
priv struct StepCountAlias {
  value : Int
}

///|
extenum @mecs.Component += {
  Position(Position)
  Velocity(Velocity)
  Health(Health)
  Mana(Mana)
  Armor(Armor)
  PositionAlias(PositionAlias)
}

///|
extenum @mecs.Resource += {
  StepCount(StepCount)
  StepCountAlias(StepCountAlias)
}

///|
impl @mecs.ComponentValue for Position with component_id() {
  ComponentId("Position")
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
  ComponentId("Velocity")
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
  ComponentId("Health")
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
impl @mecs.ComponentValue for Mana with component_id() {
  ComponentId("Mana")
}

///|
impl @mecs.ComponentValue for Mana with to_component(self) {
  Mana(self)
}

///|
impl @mecs.ComponentValue for Mana with from_component(component) {
  match component {
    Mana(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for Armor with component_id() {
  ComponentId("Armor")
}

///|
impl @mecs.ComponentValue for Armor with to_component(self) {
  Armor(self)
}

///|
impl @mecs.ComponentValue for Armor with from_component(component) {
  match component {
    Armor(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ResourceValue for StepCount with resource_id() {
  ResourceId("StepCount")
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
impl @mecs.ComponentValue for PositionAlias with component_id() {
  ComponentId("Position")
}

///|
impl @mecs.ComponentValue for PositionAlias with to_component(self) {
  PositionAlias(self)
}

///|
impl @mecs.ComponentValue for PositionAlias with from_component(component) {
  match component {
    PositionAlias(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ResourceValue for StepCountAlias with resource_id() {
  ResourceId("StepCount")
}

///|
impl @mecs.ResourceValue for StepCountAlias with to_resource(self) {
  StepCountAlias(self)
}

///|
impl @mecs.ResourceValue for StepCountAlias with from_resource(resource) {
  match resource {
    StepCountAlias(value) => Some(value)
    _ => None
  }
}

///|
fn has_position(world : @mecs.World, entity : @mecs.EntityId) -> Bool {
  let hint : Position? = None
  world.has_component(entity, _hint=hint)
}

///|
fn has_position_alias(world : @mecs.World, entity : @mecs.EntityId) -> Bool {
  let hint : PositionAlias? = None
  world.has_component(entity, _hint=hint)
}

///|
fn has_step_count(world : @mecs.World) -> Bool {
  let hint : StepCount? = None
  world.has_resource(_hint=hint)
}

///|
fn has_step_count_alias(world : @mecs.World) -> Bool {
  let hint : StepCountAlias? = None
  world.has_resource(_hint=hint)
}

///|
fn move_system(world : @mecs.World) -> Unit {
  try! world.each2(fn(vel : Velocity, pos : Position) -> Unit {
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
fn add_step_count(world : @mecs.World, amount : Int) -> Unit {
  let counter : StepCount = world.get_resource()
  world.set_resource(StepCount::{ value: counter.value + amount })
}

///|
fn startup_counter(world : @mecs.World) -> Unit {
  add_step_count(world, 100)
}

///|
fn update_counter(world : @mecs.World) -> Unit {
  add_step_count(world, 10)
}

///|
fn fixed_counter(world : @mecs.World) -> Unit {
  add_step_count(world, 1000)
}

///|
fn cleanup_counter(world : @mecs.World) -> Unit {
  add_step_count(world, 1)
}

///|
fn order_first(world : @mecs.World) -> Unit {
  let counter : StepCount = world.get_resource()
  world.set_resource(StepCount::{ value: counter.value * 10 + 1 })
}

///|
fn order_middle(world : @mecs.World) -> Unit {
  let counter : StepCount = world.get_resource()
  world.set_resource(StepCount::{ value: counter.value * 10 + 2 })
}

///|
fn order_last(world : @mecs.World) -> Unit {
  let counter : StepCount = world.get_resource()
  world.set_resource(StepCount::{ value: counter.value * 10 + 3 })
}

///|
fn step_count_is_zero(world : @mecs.World) -> Bool {
  let counter : StepCount? = world.try_get_resource()
  match counter {
    Some(counter) => counter.value == 0
    None => false
  }
}

///|
fn set_count_command_system(
  _world : @mecs.World,
  commands : @mecs.Commands,
) -> Unit {
  commands.set_resource(StepCount::{ value: 10 })
}

///|
test "systems persist component and resource mutations" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 0 })
  let entity = world.spawn_with(
    (Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: -1 }),
  )
  world..add_system(System(move_system))..add_system(System(count_system))
  |> ignore
  try! world.step()
  let pos1 : Position = world.require_component(entity)
  inspect((pos1.x, pos1.y), content="(1, -1)")
  inspect((world.get_resource() : StepCount).value, content="1")
  try! world.step()
  let pos2 : Position = world.require_component(entity)
  inspect((pos2.x, pos2.y), content="(2, -2)")
  inspect((world.get_resource() : StepCount).value, content="2")
}

///|
test "commands apply deferred spawn insert and resources in order" {
  let world = @mecs.World()
  let commands = world.commands()
  let entity = commands.spawn()
  commands.insert_component(entity, Position::{ x: 1, y: 1 })
  commands.insert_component(entity, Position::{ x: 2, y: 3 })
  commands.insert_component(entity, Velocity::{ x: 4, y: 5 })
  commands.set_resource(StepCount::{ value: 1 })
  commands.set_resource(StepCount::{ value: 2 })
  try! world.apply_commands(commands)
  inspect(world.is_alive(entity), content="true")
  let pos : Position = world.require_component(entity)
  let vel : Velocity = world.require_component(entity)
  inspect((pos.x, pos.y, vel.x, vel.y), content="(2, 3, 4, 5)")
  inspect((world.get_resource() : StepCount).value, content="2")
  try! world.apply_commands(commands)
  inspect(world.is_alive(entity), content="true")
  inspect((world.get_resource() : StepCount).value, content="2")
}

///|
test "commands remove and despawn duplicate operations deterministically" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 2 }, Velocity::{ x: 3, y: 4 }),
  )
  world.set_resource(StepCount::{ value: 9 })
  let commands = world.commands()
  commands.remove_component(entity, _hint=(None : Velocity?))
  commands.remove_component(entity, _hint=(None : Velocity?))
  commands.remove_resource(_hint=(None : StepCount?))
  commands.remove_resource(_hint=(None : StepCount?))
  commands.despawn(entity)
  commands.despawn(entity)
  try! world.apply_commands(commands)
  inspect(world.is_alive(entity), content="false")
  let pos : Position? = world.get_component(entity)
  let vel : Velocity? = world.get_component(entity)
  let count : StepCount? = world.try_get_resource()
  inspect(pos is Some(_), content="false")
  inspect(vel is Some(_), content="false")
  inspect(count is Some(_), content="false")
}

///|
test "commands targeting dead entities report not spawned on insert" {
  let world = @mecs.World()
  let commands = world.commands()
  commands.despawn(99)
  commands.insert_component(99, Position::{ x: 1, y: 1 })
  let result = try? world.apply_commands(commands)
  inspect(
    match result {
      Err(NotSpawned(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
}

///|
test "command systems apply after each system" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 0 })
  world
  ..add_command_system(CommandSystem(set_count_command_system))
  ..add_system(System(count_system))
  |> ignore
  try! world.step()
  inspect((world.get_resource() : StepCount).value, content="11")
}

///|
test "scheduler runs named stages deterministically" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 0 })
  world
  ..add_system_to_stage(Startup, System(startup_counter, name="startup"))
  ..add_system_to_stage(Update, System(update_counter, name="update"))
  ..add_system_to_stage(FixedUpdate, System(fixed_counter, name="fixed"))
  ..add_system_to_stage(Cleanup, System(cleanup_counter, name="cleanup"))
  |> ignore
  try! world.step()
  inspect((world.get_resource() : StepCount).value, content="111")
  try! world.fixed_step()
  inspect((world.get_resource() : StepCount).value, content="1111")
  try! world.step()
  inspect((world.get_resource() : StepCount).value, content="1122")
}

///|
test "scheduler orders systems by labels and exposes metadata" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 0 })
  world.add_system_to_stage(Update, System(order_last, name="last"), after=[
    SystemLabel("middle"),
  ])
  world.add_system_to_stage(Update, System(order_first, name="first"), before=[
    SystemLabel("middle"),
  ])
  world.add_system_to_stage(Update, System(order_middle, name="middle"))
  let order = world.system_order(stage=Update)
  inspect(
    (order[0].name(), order[1].name(), order[2].name()),
    content="(\"first\", \"middle\", \"last\")",
  )
  try! world.step()
  inspect((world.get_resource() : StepCount).value, content="123")
}

///|
test "scheduler run conditions can read resources" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 0 })
  world.add_system_to_stage(
    Update,
    System(count_system, name="conditional"),
    run_if=step_count_is_zero,
  )
  try! world.step()
  inspect((world.get_resource() : StepCount).value, content="1")
  try! world.step()
  inspect((world.get_resource() : StepCount).value, content="1")
}

///|
test "each3 persists component mutations" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 1 }, Velocity::{ x: 2, y: 3 }, Health::{ value: 4 }),
  )
  try! world.each3(fn(vel : Velocity, pos : Position, health : Health) -> Unit {
    pos.x += vel.x
    pos.y += vel.y
    health.value += 10
  })
  let pos : Position = world.require_component(entity)
  let health : Health = world.require_component(entity)
  inspect((pos.x, pos.y, health.value), content="(3, 4, 14)")
}

///|
test "for_each3 streams rows without snapshot writeback" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 1 }, Velocity::{ x: 2, y: 3 }, Health::{ value: 4 }),
  )
  let total = Ref(0)
  world.for_each3(fn(pos : Position, vel : Velocity, health : Health) -> Unit {
    total.val += pos.x + pos.y + vel.x + vel.y + health.value
    pos.x = 99
    health.value = 99
  })
  let pos : Position = world.require_component(entity)
  let health : Health = world.require_component(entity)
  inspect(total.val, content="11")
  inspect((pos.x, pos.y, health.value), content="(99, 1, 99)")
}

///|
test "for_each1 streams single component rows" {
  let world = @mecs.World()
  let entity = world.spawn()
  try! world.insert_component(entity, Position::{ x: 1, y: 2 })
  let total = Ref(0)
  world.for_each1(fn(pos : Position) -> Unit {
    total.val += pos.x + pos.y
    pos.x = 10
  })
  let pos : Position = world.require_component(entity)
  inspect(total.val, content="3")
  inspect((pos.x, pos.y), content="(10, 2)")
}

///|
test "for_each4 and for_each5 stream wide rows" {
  let world4 = @mecs.World()
  let entity4 = world4.spawn_with(
    (
      Position::{ x: 1, y: 2 },
      Velocity::{ x: 3, y: 4 },
      Health::{ value: 5 },
      Mana::{ value: 6 },
    ),
  )
  let total4 = Ref(0)
  world4.for_each4(fn(
    pos : Position,
    vel : Velocity,
    health : Health,
    mana : Mana,
  ) -> Unit {
    total4.val += pos.x + pos.y + vel.x + vel.y + health.value + mana.value
    pos.x = 40
    health.value = 50
  })
  let pos4 : Position = world4.require_component(entity4)
  let health4 : Health = world4.require_component(entity4)
  inspect(total4.val, content="21")
  inspect((pos4.x, pos4.y, health4.value), content="(40, 2, 50)")

  let world5 = @mecs.World()
  let entity5 = world5.spawn_with(
    (
      Position::{ x: 1, y: 2 },
      Velocity::{ x: 3, y: 4 },
      Health::{ value: 5 },
      Mana::{ value: 6 },
    ),
  )
  try! world5.insert_component(entity5, Armor::{ value: 7 })
  let total5 = Ref(0)
  world5.for_each5(fn(
    pos : Position,
    vel : Velocity,
    health : Health,
    mana : Mana,
    armor : Armor,
  ) -> Unit {
    total5.val += pos.x +
      pos.y +
      vel.x +
      vel.y +
      health.value +
      mana.value +
      armor.value
    pos.x = 60
    health.value = 70
  })
  let pos5 : Position = world5.require_component(entity5)
  let health5 : Health = world5.require_component(entity5)
  inspect(total5.val, content="28")
  inspect((pos5.x, pos5.y, health5.value), content="(60, 2, 70)")
}

///|
test "each2 snapshots rows and keeps nonqueried structural changes" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 1 }, Velocity::{ x: 0, y: 0 }, Health::{ value: 1 }),
  )
  let visited = Ref(0)
  try! world.each2(fn(_vel : Velocity, _pos : Position) -> Unit {
    visited.val += 1
    ignore(
      world.spawn_with((Position::{ x: 9, y: 9 }, Velocity::{ x: 1, y: 1 })),
    )
    world.remove_component(entity, _hint=(None : Health?))
  })
  let rows : Array[(Velocity, Position)] = world.query().to_array()
  let health : Health? = world.get_component(entity)
  inspect(visited.val, content="1")
  inspect(rows.length(), content="2")
  inspect(health is Some(_), content="false")
}

///|
test "each2 reports not spawned when yielded entity is despawned before writeback" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 1 }, Velocity::{ x: 0, y: 0 }),
  )
  let result = try? world.each2(fn(_vel : Velocity, _pos : Position) -> Unit {
    ignore(world.despawn(entity))
  })
  inspect(
    match result {
      Err(NotSpawned(id)) => id == entity
      _ => false
    },
    content="true",
  )
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
  let rows : Array[(@mecs.EntityId, (Position, Velocity, Health))] = world
    .query3_entities()
    .to_array()
  inspect(rows.length(), content="1")
  let (entity, (pos, vel, hp)) = rows[0]
  inspect(entity == complete, content="true")
  inspect((pos.x, pos.y, vel.x, vel.y, hp.value), content="(0, 0, 1, 2, 7)")
}

///|
test "query4 and query5 yield consistent entity rows" {
  let world = @mecs.World()
  let complete5 = world.spawn_with(
    (
      Position::{ x: 1, y: 2 },
      Velocity::{ x: 3, y: 4 },
      Health::{ value: 5 },
      Mana::{ value: 6 },
    ),
  )
  try! world.insert_component(complete5, Armor::{ value: 7 })
  let complete4 = world.spawn_with(
    (
      Position::{ x: 8, y: 9 },
      Velocity::{ x: 10, y: 11 },
      Health::{ value: 12 },
      Mana::{ value: 13 },
    ),
  )
  let partial = world.spawn_with(
    (Position::{ x: 14, y: 15 }, Velocity::{ x: 16, y: 17 }),
  )
  ignore(partial)
  let rows4 : Array[(@mecs.EntityId, (Position, Velocity, Health, Mana))] = world
    .query4_entities()
    .to_array()
  let rows5 : Array[(Position, Velocity, Health, Mana, Armor)] = world
    .query()
    .to_array()
  let rows5_entities : Array[
    (@mecs.EntityId, (Position, Velocity, Health, Mana, Armor)),
  ] = world.query5_entities().to_array()
  inspect(rows4.length(), content="2")
  inspect(rows5.length(), content="1")
  inspect(rows5_entities.length(), content="1")
  inspect(rows5_entities[0].0 == complete5, content="true")
  let complete4_mana = Ref(-1)
  for row in rows4 {
    let (entity4, (_pos4, _vel4, _hp4, mana4)) = row
    if entity4 == complete4 {
      complete4_mana.val = mana4.value
    }
  }
  inspect(complete4_mana.val, content="13")
  let (pos5, vel5, hp5, mana5, armor5) = rows5[0]
  inspect(
    (pos5.x, pos5.y, vel5.x, vel5.y, hp5.value, mana5.value, armor5.value),
    content="(1, 2, 3, 4, 5, 6, 7)",
  )
}

///|
test "duplicate component types in queries are repeated reads" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 3, y: 4 }, Velocity::{ x: 0, y: 0 }),
  )
  let rows : Array[(@mecs.EntityId, (Position, Position))] = world
    .query2_entities()
    .to_array()
  inspect(rows.length(), content="1")
  let (row_entity, (first, second)) = rows[0]
  inspect(row_entity == entity, content="true")
  inspect((first.x, first.y, second.x, second.y), content="(3, 4, 3, 4)")
}

///|
test "entity ops can dynamically add components" {
  let world = @mecs.World()
  let entity = world.spawn()
  let ops = world.entity_ops(entity)
  try! ops.insert_component(Position::{ x: 1, y: 2 })
  try! ops.insert_component(Velocity::{ x: 3, y: 4 })
  let rows : Array[(Velocity, Position)] = world.query().to_array()
  inspect(rows.length(), content="1")
  let (vel, pos) = rows[0]
  inspect((pos.x, pos.y, vel.x, vel.y), content="(1, 2, 3, 4)")
}

///|
test "entity ops insert reports dead entity failure" {
  let world = @mecs.World()
  let ops = world.entity_ops(99)
  let result = try? ops.insert_component(Position::{ x: 0, y: 0 })
  inspect(
    match result {
      Err(NotSpawned(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
}

///|
test "component ids are opaque and use variant names" {
  let id : @mecs.ComponentId = ComponentId("Position")
  inspect(id.name(), content="Position")
  inspect(@mecs.component_id("Velocity").name(), content="Velocity")
  let resource_id : @mecs.ResourceId = ResourceId("StepCount")
  inspect(resource_id.name(), content="StepCount")
  inspect(@mecs.resource_id("StepCount").name(), content="StepCount")
}

///|
test "component id collision overwrites one storage slot" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 2 }, Velocity::{ x: 0, y: 0 }),
  )
  inspect(has_position(world, entity), content="true")
  inspect(has_position_alias(world, entity), content="false")
  try! world.insert_component(entity, PositionAlias::{ value: 42 })
  let position : Position? = world.get_component(entity)
  let alias_pos : PositionAlias? = world.get_component(entity)
  inspect(position is Some(_), content="false")
  inspect(alias_pos is Some(_), content="true")
  inspect(
    match alias_pos {
      Some(value) => value.value
      None => -1
    },
    content="42",
  )
  inspect(has_position(world, entity), content="false")
  inspect(has_position_alias(world, entity), content="true")
}

///|
test "resource id collision overwrites one storage slot" {
  let world = @mecs.World()
  world.set_resource(StepCount::{ value: 1 })
  inspect(has_step_count(world), content="true")
  inspect(has_step_count_alias(world), content="false")
  world.set_resource(StepCountAlias::{ value: 9 })
  let counter : StepCount? = world.try_get_resource()
  let alias_resource : StepCountAlias? = world.try_get_resource()
  inspect(counter is Some(_), content="false")
  inspect(alias_resource is Some(_), content="true")
  inspect(
    match alias_resource {
      Some(value) => value.value
      None => -1
    },
    content="9",
  )
  inspect(has_step_count(world), content="false")
  inspect(has_step_count_alias(world), content="true")
}

///|
test "missing entity reads are safe and insert reports not spawned" {
  let world = @mecs.World()
  inspect(world.is_alive(99), content="false")
  let result = try? world.insert_component(99, Position::{ x: 1, y: 1 })
  inspect(
    match result {
      Err(NotSpawned(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  let pos : Position? = world.get_component(99)
  inspect(pos is Some(_), content="false")
  inspect(has_position(world, 99), content="false")
  let counter : StepCount? = world.try_get_resource()
  inspect(counter is Some(_), content="false")
  inspect(has_step_count(world), content="false")
}

///|
test "removed component and resource APIs return absence" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 7, y: 8 }, Velocity::{ x: 0, y: 0 }),
  )
  world.set_resource(StepCount::{ value: 3 })
  inspect(has_position(world, entity), content="true")
  inspect(has_step_count(world), content="true")
  world.remove_component(entity, _hint=(None : Position?))
  world.remove_resource(_hint=(None : StepCount?))
  inspect(has_position(world, entity), content="false")
  inspect(has_step_count(world), content="false")
  let pos : Position? = world.get_component(entity)
  let count : StepCount? = world.try_get_resource()
  inspect(pos is Some(_), content="false")
  inspect(count is Some(_), content="false")
}

///|
test "checked entity APIs report entity missing" {
  let world = @mecs.World()
  let insert_result = try? world.insert_component_checked(99, Position::{
    x: 0,
    y: 0,
  })
  let component_result = try? (world.get_component_checked(99) : Position)
  let remove_result = try? world.remove_component_checked(
    99,
    _hint=(None : Position?),
  )
  let despawn_result = try? world.despawn_checked(99)
  inspect(
    match insert_result {
      Err(EntityMissing(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  inspect(
    match component_result {
      Err(EntityMissing(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  inspect(
    match remove_result {
      Err(EntityMissing(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  inspect(
    match despawn_result {
      Err(EntityMissing(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
}

///|
test "checked component APIs report missing and variant mismatch" {
  let world = @mecs.World()
  let entity = world.spawn_with(
    (Position::{ x: 1, y: 2 }, Velocity::{ x: 0, y: 0 }),
  )
  let missing_result = try? (world.get_component_checked(entity) : Health)
  inspect(
    match missing_result {
      Err(ComponentMissing(id_entity, id)) =>
        id_entity == entity && id.name() == "Health"
      _ => false
    },
    content="true",
  )
  try! world.insert_component(entity, PositionAlias::{ value: 7 })
  let mismatch_result = try? (world.get_component_checked(entity) : Position)
  let remove_mismatch_result = try? world.remove_component_checked(
    entity,
    _hint=(None : Position?),
  )
  inspect(
    match mismatch_result {
      Err(ComponentVariantMismatch(id_entity, id)) =>
        id_entity == entity && id.name() == "Position"
      _ => false
    },
    content="true",
  )
  inspect(
    match remove_mismatch_result {
      Err(ComponentVariantMismatch(id_entity, id)) =>
        id_entity == entity && id.name() == "Position"
      _ => false
    },
    content="true",
  )
  try! world.remove_component_checked(entity, _hint=(None : PositionAlias?))
  inspect(has_position_alias(world, entity), content="false")
}

///|
test "checked resource APIs report missing and variant mismatch" {
  let world = @mecs.World()
  let missing_result = try? (world.get_resource_checked() : StepCount)
  let remove_missing_result = try? world.remove_resource_checked(
    _hint=(None : StepCount?),
  )
  inspect(
    match missing_result {
      Err(ResourceMissing(id)) => id.name() == "StepCount"
      _ => false
    },
    content="true",
  )
  inspect(
    match remove_missing_result {
      Err(ResourceMissing(id)) => id.name() == "StepCount"
      _ => false
    },
    content="true",
  )
  world.set_resource(StepCountAlias::{ value: 3 })
  let mismatch_result = try? (world.get_resource_checked() : StepCount)
  let remove_mismatch_result = try? world.remove_resource_checked(
    _hint=(None : StepCount?),
  )
  inspect(
    match mismatch_result {
      Err(ResourceVariantMismatch(id)) => id.name() == "StepCount"
      _ => false
    },
    content="true",
  )
  inspect(
    match remove_mismatch_result {
      Err(ResourceVariantMismatch(id)) => id.name() == "StepCount"
      _ => false
    },
    content="true",
  )
  try! world.remove_resource_checked(_hint=(None : StepCountAlias?))
  inspect(has_step_count_alias(world), content="false")
}

///|
test "checked entity ops report failures and mutate live entities" {
  let world = @mecs.World()
  let missing_ops = world.entity_ops(99)
  let missing_insert = try? missing_ops.insert_component_checked(Position::{
    x: 1,
    y: 1,
  })
  let missing_remove = try? missing_ops.remove_component_checked(
    _hint=(None : Position?),
  )
  let missing_despawn = try? missing_ops.despawn_checked()
  inspect(
    match missing_insert {
      Err(EntityMissing(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  inspect(
    match missing_remove {
      Err(EntityMissing(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  inspect(
    match missing_despawn {
      Err(EntityMissing(entity)) => entity == 99
      _ => false
    },
    content="true",
  )
  let entity = world.spawn()
  let ops = world.entity_ops(entity)
  try! ops.insert_component_checked(Position::{ x: 4, y: 5 })
  inspect(has_position(world, entity), content="true")
  try! ops.remove_component_checked(_hint=(None : Position?))
  inspect(has_position(world, entity), content="false")
  try! ops.despawn_checked()
  inspect(world.is_alive(entity), content="false")
}
