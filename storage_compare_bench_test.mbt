///|
let compare_size : Int = 1000

///|
let compare_sparse_stride : Int = 4

///|
priv struct NestedStore {
  components : Map[Int, Map[Int, Int]]
}

///|
priv struct MapColumns {
  position : Map[Int, Int]
  velocity : Map[Int, Int]
  health : Map[Int, Int]
}

///|
priv struct HashColumns {
  position : @hashmap.HashMap[Int, Int]
  velocity : @hashmap.HashMap[Int, Int]
  health : @hashmap.HashMap[Int, Int]
}

///|
priv struct SecondaryColumns {
  entities : @slotmap.SlotMap[@slotmap.DefaultKey, Int]
  keys : Array[@slotmap.DefaultKey]
  position : @slotmap.SecondaryMap[@slotmap.DefaultKey, Int]
  velocity : @slotmap.SecondaryMap[@slotmap.DefaultKey, Int]
  health : @slotmap.SecondaryMap[@slotmap.DefaultKey, Int]
}

///|
priv struct SparseSecondaryColumns {
  entities : @slotmap.SlotMap[@slotmap.DefaultKey, Int]
  keys : Array[@slotmap.DefaultKey]
  position : @slotmap.SparseSecondaryMap[@slotmap.DefaultKey, Int]
  velocity : @slotmap.SparseSecondaryMap[@slotmap.DefaultKey, Int]
  health : @slotmap.SparseSecondaryMap[@slotmap.DefaultKey, Int]
}

///|
fn compare_value(entity : Int, component : Int) -> Int {
  entity * 31 + component
}

///|
fn build_nested_store(size : Int, sparse_health : Bool) -> NestedStore {
  let components : Map[Int, Map[Int, Int]] = Map([], capacity=size)
  for entity in 0..<size {
    let row : Map[Int, Int] = Map([], capacity=3)
    row[0] = compare_value(entity, 0)
    row[1] = compare_value(entity, 1)
    if !sparse_health || entity % compare_sparse_stride == 0 {
      row[2] = compare_value(entity, 2)
    }
    components[entity] = row
  }
  { components, }
}

///|
fn build_map_columns(size : Int, sparse_health : Bool) -> MapColumns {
  let position : Map[Int, Int] = Map([], capacity=size)
  let velocity : Map[Int, Int] = Map([], capacity=size)
  let health : Map[Int, Int] = Map([], capacity=size)
  for entity in 0..<size {
    position[entity] = compare_value(entity, 0)
    velocity[entity] = compare_value(entity, 1)
    if !sparse_health || entity % compare_sparse_stride == 0 {
      health[entity] = compare_value(entity, 2)
    }
  }
  { position, velocity, health }
}

///|
fn build_hash_columns(size : Int, sparse_health : Bool) -> HashColumns {
  let position : @hashmap.HashMap[Int, Int] = HashMap([], capacity=size)
  let velocity : @hashmap.HashMap[Int, Int] = HashMap([], capacity=size)
  let health : @hashmap.HashMap[Int, Int] = HashMap([], capacity=size)
  for entity in 0..<size {
    position[entity] = compare_value(entity, 0)
    velocity[entity] = compare_value(entity, 1)
    if !sparse_health || entity % compare_sparse_stride == 0 {
      health[entity] = compare_value(entity, 2)
    }
  }
  { position, velocity, health }
}

///|
fn build_secondary_columns(
  size : Int,
  sparse_health : Bool,
) -> SecondaryColumns {
  let entities : @slotmap.SlotMap[@slotmap.DefaultKey, Int] = @slotmap.SlotMap::with_capacity(
    size,
  )
  let keys : Array[@slotmap.DefaultKey] = Array::new(capacity=size)
  let position : @slotmap.SecondaryMap[@slotmap.DefaultKey, Int] = @slotmap.SecondaryMap::with_capacity(
    size,
  )
  let velocity : @slotmap.SecondaryMap[@slotmap.DefaultKey, Int] = @slotmap.SecondaryMap::with_capacity(
    size,
  )
  let health : @slotmap.SecondaryMap[@slotmap.DefaultKey, Int] = @slotmap.SecondaryMap::with_capacity(
    size,
  )
  for entity in 0..<size {
    let key = entities.insert(entity)
    keys.push(key)
    ignore(position.insert(key, compare_value(entity, 0)))
    ignore(velocity.insert(key, compare_value(entity, 1)))
    if !sparse_health || entity % compare_sparse_stride == 0 {
      ignore(health.insert(key, compare_value(entity, 2)))
    }
  }
  { entities, keys, position, velocity, health }
}

///|
fn build_sparse_secondary_columns(
  size : Int,
  sparse_health : Bool,
) -> SparseSecondaryColumns {
  let entities : @slotmap.SlotMap[@slotmap.DefaultKey, Int] = @slotmap.SlotMap::with_capacity(
    size,
  )
  let keys : Array[@slotmap.DefaultKey] = Array::new(capacity=size)
  let position : @slotmap.SparseSecondaryMap[@slotmap.DefaultKey, Int] = @slotmap.SparseSecondaryMap::with_capacity(
    size,
  )
  let velocity : @slotmap.SparseSecondaryMap[@slotmap.DefaultKey, Int] = @slotmap.SparseSecondaryMap::with_capacity(
    size,
  )
  let health : @slotmap.SparseSecondaryMap[@slotmap.DefaultKey, Int] = @slotmap.SparseSecondaryMap::with_capacity(
    size,
  )
  for entity in 0..<size {
    let key = entities.insert(entity)
    keys.push(key)
    ignore(position.insert(key, compare_value(entity, 0)))
    ignore(velocity.insert(key, compare_value(entity, 1)))
    if !sparse_health || entity % compare_sparse_stride == 0 {
      ignore(health.insert(key, compare_value(entity, 2)))
    }
  }
  { entities, keys, position, velocity, health }
}

///|
fn sum_nested_query3(store : NestedStore) -> Int {
  let mut total = 0
  store.components.each(fn(_, row) {
    match (row.get(0), row.get(1), row.get(2)) {
      (Some(position), Some(velocity), Some(health)) =>
        total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_map_query3_dense_drive(store : MapColumns) -> Int {
  let mut total = 0
  store.position.each(fn(entity, position) {
    match (store.velocity.get(entity), store.health.get(entity)) {
      (Some(velocity), Some(health)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_map_query3_sparse_drive(store : MapColumns) -> Int {
  let mut total = 0
  store.health.each(fn(entity, health) {
    match (store.position.get(entity), store.velocity.get(entity)) {
      (Some(position), Some(velocity)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_hash_query3_dense_drive(store : HashColumns) -> Int {
  let mut total = 0
  store.position.each(fn(entity, position) {
    match (store.velocity.get(entity), store.health.get(entity)) {
      (Some(velocity), Some(health)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_hash_query3_sparse_drive(store : HashColumns) -> Int {
  let mut total = 0
  store.health.each(fn(entity, health) {
    match (store.position.get(entity), store.velocity.get(entity)) {
      (Some(position), Some(velocity)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_secondary_query3_dense_drive(store : SecondaryColumns) -> Int {
  let mut total = 0
  store.position.each(fn(entity, position) {
    match (store.velocity.get(entity), store.health.get(entity)) {
      (Some(velocity), Some(health)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_secondary_query3_sparse_drive(store : SecondaryColumns) -> Int {
  let mut total = 0
  store.health.each(fn(entity, health) {
    match (store.position.get(entity), store.velocity.get(entity)) {
      (Some(position), Some(velocity)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_sparse_secondary_query3_dense_drive(
  store : SparseSecondaryColumns,
) -> Int {
  let mut total = 0
  store.position.each(fn(entity, position) {
    match (store.velocity.get(entity), store.health.get(entity)) {
      (Some(velocity), Some(health)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_sparse_secondary_query3_sparse_drive(
  store : SparseSecondaryColumns,
) -> Int {
  let mut total = 0
  store.health.each(fn(entity, health) {
    match (store.position.get(entity), store.velocity.get(entity)) {
      (Some(position), Some(velocity)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn remove_nested_positions(store : NestedStore) -> Int {
  let mut total = 0
  store.components.each(fn(_, row) {
    match row.get(0) {
      Some(position) => total += position
      None => ()
    }
    row.remove(0)
  })
  total
}

///|
fn remove_map_positions(store : MapColumns) -> Int {
  let mut total = 0
  let ids = store.position.keys()
  for entity in ids {
    match store.position.get(entity) {
      Some(position) => total += position
      None => ()
    }
    store.position.remove(entity)
  }
  total
}

///|
fn remove_hash_positions(store : HashColumns) -> Int {
  let mut total = 0
  let ids = store.position.keys()
  for entity in ids {
    match store.position.get(entity) {
      Some(position) => total += position
      None => ()
    }
    store.position.remove(entity)
  }
  total
}

///|
fn remove_secondary_positions(store : SecondaryColumns) -> Int {
  let mut total = 0
  for key in store.keys {
    match store.position.remove(key) {
      Some(position) => total += position
      None => ()
    }
  }
  total
}

///|
fn remove_sparse_secondary_positions(store : SparseSecondaryColumns) -> Int {
  let mut total = 0
  for key in store.keys {
    match store.position.remove(key) {
      Some(position) => total += position
      None => ()
    }
  }
  total
}

///|
fn despawn_nested(store : NestedStore) -> Int {
  let mut total = 0
  let ids = store.components.keys()
  for entity in ids {
    match store.components.get(entity) {
      Some(row) => total += row.length()
      None => ()
    }
    store.components.remove(entity)
  }
  total
}

///|
fn despawn_map_columns(store : MapColumns) -> Int {
  let mut total = 0
  let ids = store.position.keys()
  for entity in ids {
    match store.position.get(entity) {
      Some(value) => total += value
      None => ()
    }
    store.position.remove(entity)
    ignore(store.velocity.remove(entity))
    ignore(store.health.remove(entity))
  }
  total
}

///|
fn despawn_hash_columns(store : HashColumns) -> Int {
  let mut total = 0
  let ids = store.position.keys()
  for entity in ids {
    match store.position.get(entity) {
      Some(value) => total += value
      None => ()
    }
    store.position.remove(entity)
    ignore(store.velocity.remove(entity))
    ignore(store.health.remove(entity))
  }
  total
}

///|
fn despawn_secondary_columns(store : SecondaryColumns) -> Int {
  let mut total = 0
  for key in store.keys {
    match store.entities.remove(key) {
      Some(value) => total += value
      None => ()
    }
    ignore(store.position.remove(key))
    ignore(store.velocity.remove(key))
    ignore(store.health.remove(key))
  }
  total
}

///|
fn despawn_sparse_secondary_columns(store : SparseSecondaryColumns) -> Int {
  let mut total = 0
  for key in store.keys {
    match store.entities.remove(key) {
      Some(value) => total += value
      None => ()
    }
    ignore(store.position.remove(key))
    ignore(store.velocity.remove(key))
    ignore(store.health.remove(key))
  }
  total
}

///|
fn set_churn(size : Int, rounds : Int) -> Int {
  let live : @set.Set[Int] = Set([])
  let active : Array[Int] = Array::new(capacity=size)
  let mut next_id = 0
  for _ in 0..<size {
    live.add(next_id)
    active.push(next_id)
    next_id += 1
  }
  for i in 0..<rounds {
    let position = (i * 17 + 23) % size
    live.remove(active[position])
    live.add(next_id)
    active[position] = next_id
    next_id += 1
  }
  let mut total = 0
  for entity in active {
    if live.contains(entity) {
      total += entity
    }
  }
  total
}

///|
fn map_churn(size : Int, rounds : Int) -> Int {
  let live : Map[Int, Int] = Map([], capacity=size)
  let active : Array[Int] = Array::new(capacity=size)
  let mut next_id = 0
  for _ in 0..<size {
    live[next_id] = next_id
    active.push(next_id)
    next_id += 1
  }
  for i in 0..<rounds {
    let position = (i * 17 + 23) % size
    live.remove(active[position])
    live[next_id] = next_id
    active[position] = next_id
    next_id += 1
  }
  let mut total = 0
  for entity in active {
    match live.get(entity) {
      Some(value) => total += value
      None => ()
    }
  }
  total
}

///|
fn slotmap_churn(size : Int, rounds : Int) -> Int {
  let live : @slotmap.SlotMap[@slotmap.DefaultKey, Int] = @slotmap.SlotMap::with_capacity(
    size,
  )
  let active : Array[@slotmap.DefaultKey] = Array::new(capacity=size)
  for i in 0..<size {
    active.push(live.insert(i))
  }
  for i in 0..<rounds {
    let position = (i * 17 + 23) % size
    ignore(live.remove(active[position]))
    active[position] = live.insert(size + i)
  }
  let mut total = 0
  for entity in active {
    match live.get(entity) {
      Some(value) => total += value
      None => ()
    }
  }
  total
}

///|
fn dense_slotmap_churn(size : Int, rounds : Int) -> Int {
  let live : @slotmap.DenseSlotMap[@slotmap.DefaultKey, Int] = @slotmap.DenseSlotMap::with_capacity(
    size,
  )
  let active : Array[@slotmap.DefaultKey] = Array::new(capacity=size)
  for i in 0..<size {
    active.push(live.insert(i))
  }
  for i in 0..<rounds {
    let position = (i * 17 + 23) % size
    ignore(live.remove(active[position]))
    active[position] = live.insert(size + i)
  }
  let mut total = 0
  for entity in active {
    match live.get(entity) {
      Some(value) => total += value
      None => ()
    }
  }
  total
}

///|
test "bench storage compare: build dense stores" (b : @bench.T) {
  b.bench(name="nested map build 1000 x3", count=5U, fn() {
    b.keep(build_nested_store(compare_size, false))
  })
  b.bench(name="component maps build 1000 x3", count=5U, fn() {
    b.keep(build_map_columns(compare_size, false))
  })
  b.bench(name="component hashmaps build 1000 x3", count=5U, fn() {
    b.keep(build_hash_columns(compare_size, false))
  })
  b.bench(name="slot secondary build 1000 x3", count=5U, fn() {
    b.keep(build_secondary_columns(compare_size, false))
  })
  b.bench(name="slot sparse-secondary build 1000 x3", count=5U, fn() {
    b.keep(build_sparse_secondary_columns(compare_size, false))
  })
}

///|
test "bench storage compare: dense query3 stores" (b : @bench.T) {
  let nested = build_nested_store(compare_size, false)
  let maps = build_map_columns(compare_size, false)
  let hashes = build_hash_columns(compare_size, false)
  let secondary = build_secondary_columns(compare_size, false)
  let sparse_secondary = build_sparse_secondary_columns(compare_size, false)
  b.bench(name="nested map dense query3 1000", count=20U, fn() {
    b.keep(sum_nested_query3(nested))
  })
  b.bench(name="component maps dense query3 1000", count=20U, fn() {
    b.keep(sum_map_query3_dense_drive(maps))
  })
  b.bench(name="component hashmaps dense query3 1000", count=20U, fn() {
    b.keep(sum_hash_query3_dense_drive(hashes))
  })
  b.bench(name="slot secondary dense query3 1000", count=20U, fn() {
    b.keep(sum_secondary_query3_dense_drive(secondary))
  })
  b.bench(name="slot sparse-secondary dense query3 1000", count=20U, fn() {
    b.keep(sum_sparse_secondary_query3_dense_drive(sparse_secondary))
  })
}

///|
test "bench storage compare: sparse query3 stores" (b : @bench.T) {
  let nested = build_nested_store(compare_size, true)
  let maps = build_map_columns(compare_size, true)
  let hashes = build_hash_columns(compare_size, true)
  let secondary = build_secondary_columns(compare_size, true)
  let sparse_secondary = build_sparse_secondary_columns(compare_size, true)
  b.bench(name="nested map sparse query3 1000", count=20U, fn() {
    b.keep(sum_nested_query3(nested))
  })
  b.bench(name="component maps sparse query3 dense-drive", count=20U, fn() {
    b.keep(sum_map_query3_dense_drive(maps))
  })
  b.bench(name="component maps sparse query3 sparse-drive", count=20U, fn() {
    b.keep(sum_map_query3_sparse_drive(maps))
  })
  b.bench(name="component hashmaps sparse query3 dense-drive", count=20U, fn() {
    b.keep(sum_hash_query3_dense_drive(hashes))
  })
  b.bench(name="component hashmaps sparse query3 sparse-drive", count=20U, fn() {
    b.keep(sum_hash_query3_sparse_drive(hashes))
  })
  b.bench(name="slot secondary sparse query3 dense-drive", count=20U, fn() {
    b.keep(sum_secondary_query3_dense_drive(secondary))
  })
  b.bench(name="slot secondary sparse query3 sparse-drive", count=20U, fn() {
    b.keep(sum_secondary_query3_sparse_drive(secondary))
  })
  b.bench(name="slot sparse-secondary sparse query3 dense-drive", count=20U, fn() {
    b.keep(sum_sparse_secondary_query3_dense_drive(sparse_secondary))
  })
  b.bench(name="slot sparse-secondary sparse query3 sparse-drive", count=20U, fn() {
    b.keep(sum_sparse_secondary_query3_sparse_drive(sparse_secondary))
  })
}

///|
test "bench storage compare: remove component stores" (b : @bench.T) {
  b.bench(name="nested map remove position 1000", count=5U, fn() {
    b.keep(remove_nested_positions(build_nested_store(compare_size, false)))
  })
  b.bench(name="component maps remove position 1000", count=5U, fn() {
    b.keep(remove_map_positions(build_map_columns(compare_size, false)))
  })
  b.bench(name="component hashmaps remove position 1000", count=5U, fn() {
    b.keep(remove_hash_positions(build_hash_columns(compare_size, false)))
  })
  b.bench(name="slot secondary remove position 1000", count=5U, fn() {
    b.keep(
      remove_secondary_positions(build_secondary_columns(compare_size, false)),
    )
  })
  b.bench(name="slot sparse-secondary remove position 1000", count=5U, fn() {
    b.keep(
      remove_sparse_secondary_positions(
        build_sparse_secondary_columns(compare_size, false),
      ),
    )
  })
}

///|
test "bench storage compare: despawn dense stores" (b : @bench.T) {
  b.bench(name="nested map despawn 1000", count=5U, fn() {
    b.keep(despawn_nested(build_nested_store(compare_size, false)))
  })
  b.bench(name="component maps eager despawn 1000", count=5U, fn() {
    b.keep(despawn_map_columns(build_map_columns(compare_size, false)))
  })
  b.bench(name="component hashmaps eager despawn 1000", count=5U, fn() {
    b.keep(despawn_hash_columns(build_hash_columns(compare_size, false)))
  })
  b.bench(name="slot secondary eager despawn 1000", count=5U, fn() {
    b.keep(
      despawn_secondary_columns(build_secondary_columns(compare_size, false)),
    )
  })
  b.bench(name="slot sparse-secondary eager despawn 1000", count=5U, fn() {
    b.keep(
      despawn_sparse_secondary_columns(
        build_sparse_secondary_columns(compare_size, false),
      ),
    )
  })
}

///|
test "bench storage compare: entity churn" (b : @bench.T) {
  let rounds = compare_size
  b.bench(name="set entity churn 1000", count=10U, fn() {
    b.keep(set_churn(compare_size, rounds))
  })
  b.bench(name="map entity churn 1000", count=10U, fn() {
    b.keep(map_churn(compare_size, rounds))
  })
  b.bench(name="slotmap entity churn 1000", count=10U, fn() {
    b.keep(slotmap_churn(compare_size, rounds))
  })
  b.bench(name="dense-slotmap entity churn 1000", count=10U, fn() {
    b.keep(dense_slotmap_churn(compare_size, rounds))
  })
}
