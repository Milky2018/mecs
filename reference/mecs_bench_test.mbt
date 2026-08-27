///|
#valtype
priv struct ValPosition {
  x : Int
  y : Int
}

///|
#valtype
priv struct ValVelocity {
  x : Int
  y : Int
}

///|
priv struct BoxPosition {
  mut x : Int
  mut y : Int
}

///|
priv struct BoxVelocity {
  x : Int
  y : Int
}

///|
let archetype_bench_size : Int = 1000

///|
fn build_val_world() -> (
  @reference.World,
  @reference.ComponentKey[ValPosition],
  @reference.ComponentKey[ValVelocity],
  @reference.ComponentKey[Int],
) {
  let world = @reference.World::new()
  let position : @reference.ComponentKey[ValPosition] = world.component()
  let velocity : @reference.ComponentKey[ValVelocity] = world.component()
  let health : @reference.ComponentKey[Int] = world.component()
  for i in 0..<archetype_bench_size {
    ignore(
      world.spawn(
        (
          (position.entry({ x: i, y: i, }), velocity.entry({ x: 1, y: -1, })),
          health.entry(i),
        ),
      ),
    )
  }
  (world, position, velocity, health)
}

///|
fn build_box_world() -> (
  @reference.World,
  @reference.ComponentKey[BoxPosition],
  @reference.ComponentKey[BoxVelocity],
  @reference.ComponentKey[Int],
) {
  let world = @reference.World::new()
  let position : @reference.ComponentKey[BoxPosition] = world.component()
  let velocity : @reference.ComponentKey[BoxVelocity] = world.component()
  let health : @reference.ComponentKey[Int] = world.component()
  for i in 0..<archetype_bench_size {
    ignore(
      world.spawn(
        (
          (position.entry({ x: i, y: i, }), velocity.entry({ x: 1, y: -1, })),
          health.entry(i),
        ),
      ),
    )
  }
  (world, position, velocity, health)
}

///|
#inline(never)
fn checksum_val(query : @reference.Query2[ValPosition, ValVelocity]) -> Int {
  let total = Ref(0)
  query.for_each(fn(_, p, v) { total.val += p.x + p.y + v.x + v.y })
  total.val
}

///|
#inline(never)
fn checksum_box(query : @reference.Query2[BoxPosition, BoxVelocity]) -> Int {
  let total = Ref(0)
  query.for_each(fn(_, p, v) { total.val += p.x + p.y + v.x + v.y })
  total.val
}

///|
#inline(never)
fn write_val(query : @reference.Query2[ValPosition, ValVelocity]) -> Unit {
  query.for_each_mut_a(fn(_, p, v) { { x: p.x + v.x, y: p.y + v.y, } })
}

///|
#inline(never)
fn write_box(query : @reference.Query2[BoxPosition, BoxVelocity]) -> Unit {
  query.for_each_mut_a(fn(_, p, v) { { x: p.x + v.x, y: p.y + v.y, } })
}

///|
#inline(never)
fn write_box_in_place(
  query : @reference.Query2[BoxPosition, BoxVelocity],
) -> Unit {
  query.for_each(fn(_, p, v) {
    p.x += v.x
    p.y += v.y
  })
}

///|
#inline(never)
fn write_val_batch(query : @reference.Query2[ValPosition, ValVelocity]) -> Unit {
  query.for_each_batch_mut_a(fn(_, positions, velocities) {
    for i in 0..<positions.length() {
      let p = positions[i]
      let v = velocities[i]
      positions[i] = { x: p.x + v.x, y: p.y + v.y, }
    }
  })
}

///|
#inline(never)
fn write_box_batch(query : @reference.Query2[BoxPosition, BoxVelocity]) -> Unit {
  query.for_each_batch_mut_a(fn(_, positions, velocities) {
    for i in 0..<positions.length() {
      let p = positions[i]
      let v = velocities[i]
      positions[i] = { x: p.x + v.x, y: p.y + v.y, }
    }
  })
}

///|
#inline(never)
fn write_box_batch_in_place(
  query : @reference.Query2[BoxPosition, BoxVelocity],
) -> Unit {
  query.for_each_batch(fn(_, positions, velocities) {
    for i in 0..<positions.length() {
      let p = positions[i]
      let v = velocities[i]
      p.x += v.x
      p.y += v.y
    }
  })
}

///|
test "bench fixed archetype: spawn" (b : @bench.T) {
  b.bench(name="spawn 1000 valtype entities", count=20U, fn() {
    let fixture = build_val_world()
    b.keep(fixture)
  })
  b.bench(name="spawn 1000 ordinary entities", count=20U, fn() {
    let fixture = build_box_world()
    b.keep(fixture)
  })
}

///|
test "bench fixed archetype: query2 read" (b : @bench.T) {
  let (val_world, val_position, val_velocity, _) = build_val_world()
  let val_query = val_world.query2(val_position, val_velocity)
  let (box_world, box_position, box_velocity, _) = build_box_world()
  let box_query = box_world.query2(box_position, box_velocity)
  b.bench(name="query2 per entity 1000 valtype", count=100U, fn() {
    b.keep(checksum_val(val_query))
  })
  b.bench(name="query2 per entity 1000 ordinary", count=100U, fn() {
    b.keep(checksum_box(box_query))
  })
  b.bench(name="query2 batch 1000 valtype", count=100U, fn() {
    let total = Ref(0)
    val_query.for_each_batch(fn(_, positions, velocities) {
      for i in 0..<positions.length() {
        let p = positions[i]
        let v = velocities[i]
        total.val += p.x + p.y + v.x + v.y
      }
    })
    b.keep(total.val)
  })
  b.bench(name="query2 batch 1000 ordinary", count=100U, fn() {
    let total = Ref(0)
    box_query.for_each_batch(fn(_, positions, velocities) {
      for i in 0..<positions.length() {
        let p = positions[i]
        let v = velocities[i]
        total.val += p.x + p.y + v.x + v.y
      }
    })
    b.keep(total.val)
  })
}

///|
test "bench fixed archetype: query2 write" (b : @bench.T) {
  let (val_world, val_position, val_velocity, _) = build_val_world()
  let val_query = val_world.query2(val_position, val_velocity)
  let (box_world, box_position, box_velocity, _) = build_box_world()
  let box_query = box_world.query2(box_position, box_velocity)
  let (mut_box_world, mut_box_position, mut_box_velocity, _) = build_box_world()
  let mut_box_query = mut_box_world.query2(mut_box_position, mut_box_velocity)
  b.bench(name="query2 write+check per entity 1000 valtype", count=100U, fn() {
    write_val(val_query)
    b.keep(checksum_val(val_query))
  })
  b.bench(
    name="query2 write+check per entity 1000 ordinary replace",
    count=100U,
    fn() {
      write_box(box_query)
      b.keep(checksum_box(box_query))
    },
  )
  b.bench(
    name="query2 write+check per entity 1000 ordinary in-place",
    count=100U,
    fn() {
      write_box_in_place(mut_box_query)
      b.keep(checksum_box(mut_box_query))
    },
  )
  b.bench(name="query2 write+check batch 1000 valtype", count=100U, fn() {
    write_val_batch(val_query)
    b.keep(checksum_val(val_query))
  })
  b.bench(name="query2 write+check batch 1000 ordinary replace", count=100U, fn() {
    write_box_batch(box_query)
    b.keep(checksum_box(box_query))
  })
  b.bench(name="query2 write+check batch 1000 ordinary in-place", count=100U, fn() {
    write_box_batch_in_place(mut_box_query)
    b.keep(checksum_box(mut_box_query))
  })
}
