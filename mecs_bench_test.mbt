///|
priv struct BenchPosition {
  x : Int
  y : Int
}

///|
priv struct BenchVelocity {
  x : Int
  y : Int
}

///|
priv struct BenchHealth {
  value : Int
}

///|
priv struct BenchArmor {
  value : Int
}

///|
priv struct BenchMana {
  value : Int
}

///|
priv struct BenchFrame {
  value : Int
}

///|
extenum @mecs.Component += {
  BenchPosition(BenchPosition)
  BenchVelocity(BenchVelocity)
  BenchHealth(BenchHealth)
  BenchArmor(BenchArmor)
  BenchMana(BenchMana)
}

///|
extenum @mecs.Resource += {
  BenchFrame(BenchFrame)
}

///|
impl @mecs.ComponentValue for BenchPosition with component_id() {
  @mecs.component_id("BenchPosition")
}

///|
impl @mecs.ComponentValue for BenchPosition with to_component(self) {
  BenchPosition(self)
}

///|
impl @mecs.ComponentValue for BenchPosition with from_component(component) {
  match component {
    BenchPosition(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for BenchVelocity with component_id() {
  @mecs.component_id("BenchVelocity")
}

///|
impl @mecs.ComponentValue for BenchVelocity with to_component(self) {
  BenchVelocity(self)
}

///|
impl @mecs.ComponentValue for BenchVelocity with from_component(component) {
  match component {
    BenchVelocity(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for BenchHealth with component_id() {
  @mecs.component_id("BenchHealth")
}

///|
impl @mecs.ComponentValue for BenchHealth with to_component(self) {
  BenchHealth(self)
}

///|
impl @mecs.ComponentValue for BenchHealth with from_component(component) {
  match component {
    BenchHealth(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for BenchArmor with component_id() {
  @mecs.component_id("BenchArmor")
}

///|
impl @mecs.ComponentValue for BenchArmor with to_component(self) {
  BenchArmor(self)
}

///|
impl @mecs.ComponentValue for BenchArmor with from_component(component) {
  match component {
    BenchArmor(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for BenchMana with component_id() {
  @mecs.component_id("BenchMana")
}

///|
impl @mecs.ComponentValue for BenchMana with to_component(self) {
  BenchMana(self)
}

///|
impl @mecs.ComponentValue for BenchMana with from_component(component) {
  match component {
    BenchMana(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ResourceValue for BenchFrame with resource_id() {
  @mecs.resource_id("BenchFrame")
}

///|
impl @mecs.ResourceValue for BenchFrame with to_resource(self) {
  BenchFrame(self)
}

///|
impl @mecs.ResourceValue for BenchFrame with from_resource(resource) {
  match resource {
    BenchFrame(value) => Some(value)
    _ => None
  }
}

///|
let bench_size : Int = 1000

///|
fn build_bench_world(size : Int) -> @mecs.World {
  let world = @mecs.World()
  for i in 0..<size {
    ignore(
      world.spawn_with(
        (
          BenchPosition::{ x: i, y: i },
          BenchVelocity::{ x: 1, y: -1 },
          BenchHealth::{ value: i },
        ),
      ),
    )
  }
  world
}

///|
fn build_bench_world4(size : Int) -> @mecs.World {
  let world = @mecs.World()
  for i in 0..<size {
    ignore(
      world.spawn_with(
        (
          BenchPosition::{ x: i, y: i },
          BenchVelocity::{ x: 1, y: -1 },
          BenchHealth::{ value: i },
          BenchArmor::{ value: i % 7 },
        ),
      ),
    )
  }
  world
}

///|
fn build_bench_world5(size : Int) -> @mecs.World {
  let world = build_bench_world4(size)
  let rows : Array[(@mecs.EntityId, BenchPosition)] = world
    .query1_entities()
    .to_array()
  for row in rows {
    let (entity, position) = row
    try! world.insert_component(entity, BenchMana::{ value: position.x % 11 })
  }
  world
}

///|
fn build_sparse_bench_world(size : Int, health_stride : Int) -> @mecs.World {
  let world = @mecs.World()
  for i in 0..<size {
    let entity = world.spawn_with(
      (BenchPosition::{ x: i, y: i }, BenchVelocity::{ x: 1, y: -1 }),
    )
    if i % health_stride == 0 {
      try! world.insert_component(entity, BenchHealth::{ value: i })
    }
  }
  world
}

///|
fn checksum_bench_rows(
  rows : Array[(BenchPosition, BenchVelocity, BenchHealth)],
) -> Int {
  let mut total = 0
  for row in rows {
    let (position, velocity, health) = row
    total += position.x + position.y + velocity.x + velocity.y + health.value
  }
  total
}

///|
fn checksum_bench_quad_rows(
  rows : Array[(BenchPosition, BenchVelocity, BenchHealth, BenchArmor)],
) -> Int {
  let mut total = 0
  for row in rows {
    let (position, velocity, health, armor) = row
    total += position.x +
      position.y +
      velocity.x +
      velocity.y +
      health.value +
      armor.value
  }
  total
}

///|
fn checksum_bench_quint_rows(
  rows : Array[
    (BenchPosition, BenchVelocity, BenchHealth, BenchArmor, BenchMana),
  ],
) -> Int {
  let mut total = 0
  for row in rows {
    let (position, velocity, health, armor, mana) = row
    total += position.x +
      position.y +
      velocity.x +
      velocity.y +
      health.value +
      armor.value +
      mana.value
  }
  total
}

///|
fn checksum_bench_pair_rows(
  rows : Array[(BenchPosition, BenchVelocity)],
) -> Int {
  let mut total = 0
  for row in rows {
    let (position, velocity) = row
    total += position.x + position.y + velocity.x + velocity.y
  }
  total
}

///|
fn checksum_bench_pair(
  position : BenchPosition,
  velocity : BenchVelocity,
) -> Int {
  position.x + position.y + velocity.x + velocity.y
}

///|
fn checksum_bench_row(
  position : BenchPosition,
  velocity : BenchVelocity,
  health : BenchHealth,
) -> Int {
  position.x + position.y + velocity.x + velocity.y + health.value
}

///|
test "bench ecs: spawn" (b : @bench.T) {
  b.bench(name="spawn 1000 entities", count=20U, fn() {
    let world = @mecs.World()
    for _ in 0..<bench_size {
      ignore(world.spawn())
    }
    b.keep(world)
  })
}

///|
test "bench ecs: despawn" (b : @bench.T) {
  b.bench(name="despawn 1000 entities", count=20U, fn() {
    let world = @mecs.World()
    let entities : Array[@mecs.EntityId] = []
    for _ in 0..<bench_size {
      entities.push(world.spawn())
    }
    for entity in entities {
      ignore(world.despawn(entity))
    }
    b.keep(world)
  })
}

///|
test "bench ecs: insert component" (b : @bench.T) {
  b.bench(name="insert 1000 components", count=20U, fn() {
    let world = @mecs.World()
    let entities : Array[@mecs.EntityId] = []
    for i in 0..<bench_size {
      let entity = world.spawn()
      entities.push(entity)
      try! world.insert_component(entity, BenchPosition::{ x: i, y: -i })
    }
    b.keep(world)
  })
}

///|
test "bench ecs: remove component" (b : @bench.T) {
  b.bench(name="remove 1000 components", count=20U, fn() {
    let world = build_bench_world(bench_size)
    let rows : Array[(@mecs.EntityId, BenchPosition)] = world
      .query1_entities()
      .to_array()
    for row in rows {
      let (entity, position) = row
      b.keep(position.x + position.y)
      world.remove_component(entity, _hint=(None : BenchPosition?))
    }
    b.keep(world)
  })
}

///|
test "bench ecs: query" (b : @bench.T) {
  let world = build_bench_world(bench_size)
  b.bench(name="query1 over 1000 entities", count=100U, fn() {
    let rows : Array[BenchPosition] = world.query1().to_array()
    let mut total = 0
    for position in rows {
      total += position.x + position.y
    }
    b.keep(total)
  })
  b.bench(name="query2 over 1000 entities", count=100U, fn() {
    let rows : Array[(BenchPosition, BenchVelocity)] = world.query2().to_array()
    b.keep(checksum_bench_pair_rows(rows))
  })
  b.bench(name="for_each2 over 1000 entities", count=100U, fn() {
    let total = Ref(0)
    world.for_each2(fn(
      position : BenchPosition,
      velocity : BenchVelocity,
    ) -> Unit {
      total.val += checksum_bench_pair(position, velocity)
    })
    b.keep(total.val)
  })
  b.bench(name="query3 over 1000 entities", count=100U, fn() {
    let rows : Array[(BenchPosition, BenchVelocity, BenchHealth)] = world
      .query3()
      .to_array()
    b.keep(checksum_bench_rows(rows))
  })
  b.bench(name="for_each3 over 1000 entities", count=100U, fn() {
    let total = Ref(0)
    world.for_each3(fn(
      position : BenchPosition,
      velocity : BenchVelocity,
      health : BenchHealth,
    ) -> Unit {
      total.val += checksum_bench_row(position, velocity, health)
    })
    b.keep(total.val)
  })
  let world4 = build_bench_world4(bench_size)
  b.bench(name="query4 over 1000 entities", count=100U, fn() {
    let rows : Array[(BenchPosition, BenchVelocity, BenchHealth, BenchArmor)] = world4
      .query4()
      .to_array()
    b.keep(checksum_bench_quad_rows(rows))
  })
  let world5 = build_bench_world5(bench_size)
  b.bench(name="query5 over 1000 entities", count=100U, fn() {
    let rows : Array[
      (BenchPosition, BenchVelocity, BenchHealth, BenchArmor, BenchMana),
    ] = world5.query5().to_array()
    b.keep(checksum_bench_quint_rows(rows))
  })
}

///|
test "bench ecs: sparse query" (b : @bench.T) {
  let world = build_sparse_bench_world(bench_size, 4)
  b.bench(name="sparse query3 over 1000 entities", count=100U, fn() {
    let rows : Array[(BenchPosition, BenchVelocity, BenchHealth)] = world
      .query3()
      .to_array()
    b.keep(checksum_bench_rows(rows))
  })
  b.bench(name="sparse for_each3 over 1000 entities", count=100U, fn() {
    let total = Ref(0)
    world.for_each3(fn(
      position : BenchPosition,
      velocity : BenchVelocity,
      health : BenchHealth,
    ) -> Unit {
      total.val += checksum_bench_row(position, velocity, health)
    })
    b.keep(total.val)
  })
}

///|
test "bench ecs: resources" (b : @bench.T) {
  b.bench(name="set/get/remove resource 1000 times", count=50U, fn() {
    let world = @mecs.World()
    for i in 0..<bench_size {
      world.set_resource(BenchFrame::{ value: i })
      let frame : BenchFrame = world.get_resource()
      b.keep(frame.value)
      world.remove_resource(_hint=(None : BenchFrame?))
    }
  })
}
