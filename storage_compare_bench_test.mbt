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
priv struct ComponentIdHashColumns {
  stores : Map[@mecs.ComponentId, @hashmap.HashMap[Int, Int]]
  component_ids : Array[Array[@mecs.ComponentId]]
}

///|
priv struct DenseComponentIndex {
  value : Int
}

///|
priv struct DenseComponentRegistry {
  indexes : Map[@mecs.ComponentId, DenseComponentIndex]
}

///|
priv struct DenseIndexedHashColumns {
  registry : DenseComponentRegistry
  stores : Array[@hashmap.HashMap[Int, Int]]
  masks : Array[Int]
}

///|
fn compare_value(entity : Int, component : Int) -> Int {
  entity * 31 + component
}

///|
fn compare_position_id() -> @mecs.ComponentId {
  @mecs.component_id("Position")
}

///|
fn compare_velocity_id() -> @mecs.ComponentId {
  @mecs.component_id("Velocity")
}

///|
fn compare_health_id() -> @mecs.ComponentId {
  @mecs.component_id("Health")
}

///|
fn DenseComponentIndex::DenseComponentIndex(value : Int) -> Self {
  { value, }
}

///|
fn DenseComponentIndex::value(self : Self) -> Int {
  self.value
}

///|
fn DenseComponentRegistry::index(
  self : Self,
  id : @mecs.ComponentId,
) -> DenseComponentIndex {
  match self.indexes.get(id) {
    Some(index) => index
    None => abort("component id is not registered: \{id.name()}")
  }
}

///|
fn build_dense_component_registry() -> DenseComponentRegistry {
  let indexes : Map[@mecs.ComponentId, DenseComponentIndex] = Map(
    [],
    capacity=3,
  )
  indexes[compare_position_id()] = DenseComponentIndex(0)
  indexes[compare_velocity_id()] = DenseComponentIndex(1)
  indexes[compare_health_id()] = DenseComponentIndex(2)
  { indexes, }
}

///|
fn compare_component_bit(index : DenseComponentIndex) -> Int {
  match index.value() {
    0 => 1
    1 => 2
    2 => 4
    _ => abort("component index is outside the benchmark mask range")
  }
}

///|
fn compare_mask_has(mask : Int, index : DenseComponentIndex) -> Bool {
  let bit = compare_component_bit(index)
  mask / bit % 2 == 1
}

///|
fn compare_mask_add(mask : Int, index : DenseComponentIndex) -> Int {
  if compare_mask_has(mask, index) {
    mask
  } else {
    mask + compare_component_bit(index)
  }
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
fn insert_component_id_hash_column(
  store : ComponentIdHashColumns,
  entity : Int,
  id : @mecs.ComponentId,
  value : Int,
) -> Unit {
  let column = store.stores.get_or_init(id, fn() {
    HashMap([], capacity=compare_size)
  })
  column[entity] = value
  let ids = store.component_ids[entity]
  if !ids.contains(id) {
    ids.push(id)
  }
}

///|
fn build_component_id_hash_columns(
  size : Int,
  sparse_health : Bool,
) -> ComponentIdHashColumns {
  let stores : Map[@mecs.ComponentId, @hashmap.HashMap[Int, Int]] = Map(
    [],
    capacity=3,
  )
  let component_ids : Array[Array[@mecs.ComponentId]] = Array::new(
    capacity=size,
  )
  for _ in 0..<size {
    component_ids.push([])
  }
  let columns = { stores, component_ids }
  for entity in 0..<size {
    insert_component_id_hash_column(
      columns,
      entity,
      compare_position_id(),
      compare_value(entity, 0),
    )
    insert_component_id_hash_column(
      columns,
      entity,
      compare_velocity_id(),
      compare_value(entity, 1),
    )
    if !sparse_health || entity % compare_sparse_stride == 0 {
      insert_component_id_hash_column(
        columns,
        entity,
        compare_health_id(),
        compare_value(entity, 2),
      )
    }
  }
  columns
}

///|
fn build_dense_indexed_hash_columns(
  size : Int,
  sparse_health : Bool,
) -> DenseIndexedHashColumns {
  let registry = build_dense_component_registry()
  let stores : Array[@hashmap.HashMap[Int, Int]] = []
  stores.push(HashMap([], capacity=size))
  stores.push(HashMap([], capacity=size))
  stores.push(HashMap([], capacity=size))
  let masks : Array[Int] = Array::new(capacity=size)
  let position = registry.index(compare_position_id())
  let velocity = registry.index(compare_velocity_id())
  let health = registry.index(compare_health_id())
  for entity in 0..<size {
    let position_store = stores[position.value()]
    let velocity_store = stores[velocity.value()]
    position_store[entity] = compare_value(entity, 0)
    velocity_store[entity] = compare_value(entity, 1)
    let mut mask = 0
    mask = compare_mask_add(mask, position)
    mask = compare_mask_add(mask, velocity)
    if !sparse_health || entity % compare_sparse_stride == 0 {
      let health_store = stores[health.value()]
      health_store[entity] = compare_value(entity, 2)
      mask = compare_mask_add(mask, health)
    }
    masks.push(mask)
  }
  { registry, stores, masks }
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
fn sum_component_id_hash_query3_dense_drive(
  store : ComponentIdHashColumns,
) -> Int {
  match
    (
      store.stores.get(compare_position_id()),
      store.stores.get(compare_velocity_id()),
      store.stores.get(compare_health_id()),
    ) {
    (Some(position_store), Some(velocity_store), Some(health_store)) => {
      let mut total = 0
      position_store.each(fn(entity, position) {
        match (velocity_store.get(entity), health_store.get(entity)) {
          (Some(velocity), Some(health)) =>
            total += position + velocity + health
          _ => ()
        }
      })
      total
    }
    _ => 0
  }
}

///|
fn sum_component_id_hash_query3_sparse_drive(
  store : ComponentIdHashColumns,
) -> Int {
  match
    (
      store.stores.get(compare_position_id()),
      store.stores.get(compare_velocity_id()),
      store.stores.get(compare_health_id()),
    ) {
    (Some(position_store), Some(velocity_store), Some(health_store)) => {
      let mut total = 0
      health_store.each(fn(entity, health) {
        match (position_store.get(entity), velocity_store.get(entity)) {
          (Some(position), Some(velocity)) =>
            total += position + velocity + health
          _ => ()
        }
      })
      total
    }
    _ => 0
  }
}

///|
fn sum_dense_indexed_query3_dense_drive(store : DenseIndexedHashColumns) -> Int {
  let position_index = store.registry.index(compare_position_id())
  let velocity_index = store.registry.index(compare_velocity_id())
  let health_index = store.registry.index(compare_health_id())
  let position_store = store.stores[position_index.value()]
  let velocity_store = store.stores[velocity_index.value()]
  let health_store = store.stores[health_index.value()]
  let mut total = 0
  position_store.each(fn(entity, position) {
    match (velocity_store.get(entity), health_store.get(entity)) {
      (Some(velocity), Some(health)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_dense_indexed_query3_sparse_drive(
  store : DenseIndexedHashColumns,
) -> Int {
  let position_index = store.registry.index(compare_position_id())
  let velocity_index = store.registry.index(compare_velocity_id())
  let health_index = store.registry.index(compare_health_id())
  let position_store = store.stores[position_index.value()]
  let velocity_store = store.stores[velocity_index.value()]
  let health_store = store.stores[health_index.value()]
  let mut total = 0
  health_store.each(fn(entity, health) {
    match (position_store.get(entity), velocity_store.get(entity)) {
      (Some(position), Some(velocity)) => total += position + velocity + health
      _ => ()
    }
  })
  total
}

///|
fn sum_component_id_list_has_query(store : ComponentIdHashColumns) -> Int {
  let position = compare_position_id()
  let velocity = compare_velocity_id()
  let health = compare_health_id()
  let mut total = 0
  for entity in 0..<store.component_ids.length() {
    let ids = store.component_ids[entity]
    if ids.contains(position) && ids.contains(velocity) && ids.contains(health) {
      total += entity
    }
  }
  total
}

///|
fn sum_dense_indexed_mask_has_query(store : DenseIndexedHashColumns) -> Int {
  let position = store.registry.index(compare_position_id())
  let velocity = store.registry.index(compare_velocity_id())
  let health = store.registry.index(compare_health_id())
  let mut total = 0
  for entity in 0..<store.masks.length() {
    let mask = store.masks[entity]
    if compare_mask_has(mask, position) &&
      compare_mask_has(mask, velocity) &&
      compare_mask_has(mask, health) {
      total += entity
    }
  }
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
fn despawn_component_id_hash_columns(store : ComponentIdHashColumns) -> Int {
  let mut total = 0
  for entity in 0..<store.component_ids.length() {
    let ids = store.component_ids[entity]
    for id in ids {
      match store.stores.get(id) {
        Some(column) => ignore(column.remove(entity))
        None => ()
      }
      total += 1
    }
  }
  total
}

///|
fn despawn_dense_indexed_hash_columns(store : DenseIndexedHashColumns) -> Int {
  let position = store.registry.index(compare_position_id())
  let velocity = store.registry.index(compare_velocity_id())
  let health = store.registry.index(compare_health_id())
  let mut total = 0
  for entity in 0..<store.masks.length() {
    let mask = store.masks[entity]
    if compare_mask_has(mask, position) {
      ignore(store.stores[position.value()].remove(entity))
      total += 1
    }
    if compare_mask_has(mask, velocity) {
      ignore(store.stores[velocity.value()].remove(entity))
      total += 1
    }
    if compare_mask_has(mask, health) {
      ignore(store.stores[health.value()].remove(entity))
      total += 1
    }
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
  b.bench(name="component-id hash build 1000 x3", count=5U, fn() {
    b.keep(build_component_id_hash_columns(compare_size, false))
  })
  b.bench(name="dense-index hash build 1000 x3", count=5U, fn() {
    b.keep(build_dense_indexed_hash_columns(compare_size, false))
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
  let component_id_hashes = build_component_id_hash_columns(compare_size, false)
  let dense_indexes = build_dense_indexed_hash_columns(compare_size, false)
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
  b.bench(name="component-id hash dense query3 1000", count=20U, fn() {
    b.keep(sum_component_id_hash_query3_dense_drive(component_id_hashes))
  })
  b.bench(name="dense-index hash dense query3 1000", count=20U, fn() {
    b.keep(sum_dense_indexed_query3_dense_drive(dense_indexes))
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
  let component_id_hashes = build_component_id_hash_columns(compare_size, true)
  let dense_indexes = build_dense_indexed_hash_columns(compare_size, true)
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
  b.bench(name="component-id hash sparse query3 dense-drive", count=20U, fn() {
    b.keep(sum_component_id_hash_query3_dense_drive(component_id_hashes))
  })
  b.bench(name="component-id hash sparse query3 sparse-drive", count=20U, fn() {
    b.keep(sum_component_id_hash_query3_sparse_drive(component_id_hashes))
  })
  b.bench(name="dense-index hash sparse query3 dense-drive", count=20U, fn() {
    b.keep(sum_dense_indexed_query3_dense_drive(dense_indexes))
  })
  b.bench(name="dense-index hash sparse query3 sparse-drive", count=20U, fn() {
    b.keep(sum_dense_indexed_query3_sparse_drive(dense_indexes))
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
test "bench storage compare: component index registry" (b : @bench.T) {
  let component_id_hashes = build_component_id_hash_columns(compare_size, false)
  let dense_indexes = build_dense_indexed_hash_columns(compare_size, false)
  b.bench(name="component-id list has query3 1000", count=20U, fn() {
    b.keep(sum_component_id_list_has_query(component_id_hashes))
  })
  b.bench(name="dense-index mask has query3 1000", count=20U, fn() {
    b.keep(sum_dense_indexed_mask_has_query(dense_indexes))
  })
  b.bench(name="component-id hash despawn 1000", count=5U, fn() {
    b.keep(
      despawn_component_id_hash_columns(
        build_component_id_hash_columns(compare_size, false),
      ),
    )
  })
  b.bench(name="dense-index hash despawn 1000", count=5U, fn() {
    b.keep(
      despawn_dense_indexed_hash_columns(
        build_dense_indexed_hash_columns(compare_size, false),
      ),
    )
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
