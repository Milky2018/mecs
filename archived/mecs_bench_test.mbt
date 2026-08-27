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
extenum @archived.Component += {
  BenchPosition(BenchPosition)
  BenchVelocity(BenchVelocity)
  BenchHealth(BenchHealth)
  BenchArmor(BenchArmor)
  BenchMana(BenchMana)
}

///|
extenum @archived.Resource += {
  BenchFrame(BenchFrame)
}

///|
impl @archived.ComponentValue for BenchPosition with fn component_id() {
  @archived.component_id("BenchPosition")
}

///|
impl @archived.ComponentValue for BenchPosition with fn to_component(self) {
  BenchPosition(self)
}

///|
impl @archived.ComponentValue for BenchPosition with fn from_component(
  component,
) {
  match component {
    BenchPosition(value) => Some(value)
    _ => None
  }
}

///|
impl @archived.ComponentValue for BenchVelocity with fn component_id() {
  @archived.component_id("BenchVelocity")
}

///|
impl @archived.ComponentValue for BenchVelocity with fn to_component(self) {
  BenchVelocity(self)
}

///|
impl @archived.ComponentValue for BenchVelocity with fn from_component(
  component,
) {
  match component {
    BenchVelocity(value) => Some(value)
    _ => None
  }
}

///|
impl @archived.ComponentValue for BenchHealth with fn component_id() {
  @archived.component_id("BenchHealth")
}

///|
impl @archived.ComponentValue for BenchHealth with fn to_component(self) {
  BenchHealth(self)
}

///|
impl @archived.ComponentValue for BenchHealth with fn from_component(component) {
  match component {
    BenchHealth(value) => Some(value)
    _ => None
  }
}

///|
impl @archived.ComponentValue for BenchArmor with fn component_id() {
  @archived.component_id("BenchArmor")
}

///|
impl @archived.ComponentValue for BenchArmor with fn to_component(self) {
  BenchArmor(self)
}

///|
impl @archived.ComponentValue for BenchArmor with fn from_component(component) {
  match component {
    BenchArmor(value) => Some(value)
    _ => None
  }
}

///|
impl @archived.ComponentValue for BenchMana with fn component_id() {
  @archived.component_id("BenchMana")
}

///|
impl @archived.ComponentValue for BenchMana with fn to_component(self) {
  BenchMana(self)
}

///|
impl @archived.ComponentValue for BenchMana with fn from_component(component) {
  match component {
    BenchMana(value) => Some(value)
    _ => None
  }
}

///|
impl @archived.ResourceValue for BenchFrame with fn resource_id() {
  @archived.resource_id("BenchFrame")
}

///|
impl @archived.ResourceValue for BenchFrame with fn to_resource(self) {
  BenchFrame(self)
}

///|
impl @archived.ResourceValue for BenchFrame with fn from_resource(resource) {
  match resource {
    BenchFrame(value) => Some(value)
    _ => None
  }
}

///|
let bench_size : Int = 1000

///|
fn build_bench_world(size : Int) -> @archived.World {
  let world = @archived.World()
  for i in 0..<size {
    ignore(
      world.spawn_with(
        (
          BenchPosition::{ x: i, y: i, },
          BenchVelocity::{ x: 1, y: -1, },
          BenchHealth::{ value: i, },
        ),
      ),
    )
  }
  world
}

///|
fn build_bench_world4(size : Int) -> @archived.World {
  let world = @archived.World()
  for i in 0..<size {
    ignore(
      world.spawn_with(
        (
          BenchPosition::{ x: i, y: i, },
          BenchVelocity::{ x: 1, y: -1, },
          BenchHealth::{ value: i, },
          BenchArmor::{ value: i % 7, },
        ),
      ),
    )
  }
  world
}

///|
fn build_bench_world5(size : Int) -> @archived.World {
  let world = build_bench_world4(size)
  let rows : Array[(@archived.EntityId, BenchPosition)] = world
    .query1_entities()
    .to_array()
  for row in rows {
    let (entity, position) = row
    try! world.insert_component(entity, BenchMana::{ value: position.x % 11, })
  }
  world
}

///|
fn build_sparse_bench_world(size : Int, health_stride : Int) -> @archived.World {
  let world = @archived.World()
  for i in 0..<size {
    let entity = world.spawn_with(
      (BenchPosition::{ x: i, y: i, }, BenchVelocity::{ x: 1, y: -1, }),
    )
    if i % health_stride == 0 {
      try! world.insert_component(entity, BenchHealth::{ value: i, })
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
fn checksum_bench_quad(
  position : BenchPosition,
  velocity : BenchVelocity,
  health : BenchHealth,
  armor : BenchArmor,
) -> Int {
  position.x + position.y + velocity.x + velocity.y + health.value + armor.value
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
fn checksum_bench_quint(
  position : BenchPosition,
  velocity : BenchVelocity,
  health : BenchHealth,
  armor : BenchArmor,
  mana : BenchMana,
) -> Int {
  position.x +
  position.y +
  velocity.x +
  velocity.y +
  health.value +
  armor.value +
  mana.value
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
    let world = @archived.World()
    for _ in 0..<bench_size {
      ignore(world.spawn())
    }
    b.keep(world)
  })
}

///|
test "bench ecs: despawn" (b : @bench.T) {
  b.bench(name="despawn 1000 entities", count=20U, fn() {
    let world = @archived.World()
    let entities : Array[@archived.EntityId] = []
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
    let world = @archived.World()
    let entities : Array[@archived.EntityId] = []
    for i in 0..<bench_size {
      let entity = world.spawn()
      entities.push(entity)
      try! world.insert_component(entity, BenchPosition::{ x: i, y: -i, })
    }
    b.keep(world)
  })
}

///|
test "bench ecs: remove component" (b : @bench.T) {
  b.bench(name="remove 1000 components", count=20U, fn() {
    let world = build_bench_world(bench_size)
    let rows : Array[(@archived.EntityId, BenchPosition)] = world
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
  b.bench(name="for_each1 over 1000 entities", count=100U, fn() {
    let total = Ref(0)
    world.for_each1(fn(position : BenchPosition) -> Unit {
      total.val += position.x + position.y
    })
    b.keep(total.val)
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
  b.bench(name="for_each4 over 1000 entities", count=100U, fn() {
    let total = Ref(0)
    world4.for_each4(fn(
      position : BenchPosition,
      velocity : BenchVelocity,
      health : BenchHealth,
      armor : BenchArmor,
    ) -> Unit {
      total.val += checksum_bench_quad(position, velocity, health, armor)
    })
    b.keep(total.val)
  })
  let world5 = build_bench_world5(bench_size)
  b.bench(name="query5 over 1000 entities", count=100U, fn() {
    let rows : Array[
      (BenchPosition, BenchVelocity, BenchHealth, BenchArmor, BenchMana),
    ] = world5.query5().to_array()
    b.keep(checksum_bench_quint_rows(rows))
  })
  b.bench(name="for_each5 over 1000 entities", count=100U, fn() {
    let total = Ref(0)
    world5.for_each5(fn(
      position : BenchPosition,
      velocity : BenchVelocity,
      health : BenchHealth,
      armor : BenchArmor,
      mana : BenchMana,
    ) -> Unit {
      total.val += checksum_bench_quint(position, velocity, health, armor, mana)
    })
    b.keep(total.val)
  })
}

///|
test "bench ecs: sparse query" (b : @bench.T) {
  let world = build_sparse_bench_world(bench_size, 4)
  let with_health = @archived.QueryFilter().with_component(
    _hint=(None : BenchHealth?),
  )
  let without_health = @archived.QueryFilter().without_component(
    _hint=(None : BenchHealth?),
  )
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
  b.bench(name="filtered query2 with health over 1000 entities", count=100U, fn() {
    let rows : Array[(BenchPosition, BenchVelocity)] = world
      .query2_filtered(with_health)
      .to_array()
    b.keep(checksum_bench_pair_rows(rows))
  })
  b.bench(
    name="filtered query2 without health over 1000 entities",
    count=100U,
    fn() {
      let rows : Array[(BenchPosition, BenchVelocity)] = world
        .query2_filtered(without_health)
        .to_array()
      b.keep(checksum_bench_pair_rows(rows))
    },
  )
}

///|
test "bench ecs: resources" (b : @bench.T) {
  b.bench(name="set/get/remove resource 1000 times", count=50U, fn() {
    let world = @archived.World()
    for i in 0..<bench_size {
      world.set_resource(BenchFrame::{ value: i, })
      let frame : BenchFrame = world.get_resource()
      b.keep(frame.value)
      world.remove_resource(_hint=(None : BenchFrame?))
    }
  })
}
