///|
/// A process-local identity allocated monotonically for each world.
priv struct WorldId(UInt64) derive(Eq, Debug)

///|
let next_world_id : Ref[UInt64] = Ref(0UL)

///|
fn allocate_world_id() -> WorldId {
  let id = next_world_id.val
  next_world_id.val += 1UL
  WorldId(id)
}

///|
priv struct Archetype {
  components : ComponentSet
  entities : Array[Entity]
  remove_components : (Int) -> Unit
}

///|
/// A typed lookup from an archetype id to its contiguous component column.
struct ComponentKey[T] {
  id : Int
  world_id : WorldId
  columns : Array[Array[T]?]
}

///|
/// A component value paired with its typed storage key for spawning.
struct ComponentEntry[T] {
  key : ComponentKey[T]
  value : T
}

///|
pub trait Bundle {
  fn collect(Self, ComponentCollector) -> Unit
  fn prepare(Self, Int) -> (Int) -> Unit
  fn append(Self, Int) -> Unit
}

///|
pub impl[T] Bundle for ComponentEntry[T] with fn collect(self, collector) {
  collector.insert(self.key.id, self.key.world_id)
}

///|
pub impl[T] Bundle for ComponentEntry[T] with fn prepare(self, archetype) {
  self.key.ensure(archetype)
  let column = self.key.column(archetype)
  fn(row) { swap_remove_row(column, row) }
}

///|
pub impl[T] Bundle for ComponentEntry[T] with fn append(self, archetype) {
  self.key.column(archetype).push(self.value)
}

///|
pub extend ComponentEntry with Bundle::{append, collect, prepare}

///|
pub impl[L : Bundle, R : Bundle] Bundle for (L, R) with fn collect(
  self,
  collector,
) {
  self.0.collect(collector)
  self.1.collect(collector)
}

///|
pub impl[L : Bundle, R : Bundle] Bundle for (L, R) with fn prepare(
  self,
  archetype,
) {
  let remove_left = self.0.prepare(archetype)
  let remove_right = self.1.prepare(archetype)
  fn(row) {
    remove_left(row)
    remove_right(row)
  }
}

///|
pub impl[L : Bundle, R : Bundle] Bundle for (L, R) with fn append(
  self,
  archetype,
) {
  self.0.append(archetype)
  self.1.append(archetype)
}

///|
struct World {
  id : WorldId
  mut next_component : Int
  slots : Array[EntitySlot]
  free_slots : Array[Int]
  mut active_queries : Int
  archetypes : Array[Archetype]
  archetype_index : @hashmap.HashMap[UInt64, Array[Int]]
  component_collector : ComponentCollector
}

///|
pub fn World::new() -> World {
  let world_id = allocate_world_id()
  {
    id: world_id,
    next_component: 0,
    slots: [],
    free_slots: [],
    active_queries: 0,
    archetypes: [],
    archetype_index: HashMap([]),
    component_collector: { words: [], world_id, valid: true, },
  }
}

///|
/// Registers a world-local component key.
pub fn[T] World::component(self : World) -> ComponentKey[T] {
  let id = self.next_component
  self.next_component += 1
  if id / 64 == self.component_collector.words.length() {
    self.component_collector.words.push(0UL)
  }
  { id, world_id: self.id, columns: [], }
}

///|
pub fn[T] ComponentKey::entry(
  self : ComponentKey[T],
  value : T,
) -> ComponentEntry[T] {
  { key: self, value, }
}

///|
fn[T] ComponentKey::ensure(self : ComponentKey[T], archetype : Int) -> Unit {
  while self.columns.length() <= archetype {
    self.columns.push(None)
  }
  if self.columns[archetype] is None {
    self.columns[archetype] = Some([])
  }
}

///|
fn[T] ComponentKey::column(self : ComponentKey[T], archetype : Int) -> Array[T] {
  match self.columns.get(archetype) {
    Some(Some(column)) => column
    _ => abort("component is absent from archetype")
  }
}

///|
fn[B : Bundle] World::archetype(self : World, hash : UInt64, bundle : B) -> Int {
  match self.archetype_index.get(hash) {
    Some(candidates) =>
      for candidate in candidates {
        if self.archetypes[candidate].components.equals_scratch(
            self.component_collector.words,
          ) {
          return candidate
        }
      }
    None => ()
  }
  let id = self.archetypes.length()
  let remove_components = bundle.prepare(id)
  self.archetypes.push({
    components: ComponentSet::from_scratch(self.component_collector.words),
    entities: [],
    remove_components,
  })
  match self.archetype_index.get(hash) {
    Some(candidates) => candidates.push(id)
    None => self.archetype_index[hash] = [id]
  }
  id
}

///|
/// Spawns into the final archetype. Component composition cannot change later.
/// Panics if called inside a query callback on this world.
pub fn[B : Bundle] World::spawn(self : World, bundle : B) -> Entity {
  guard self.active_queries == 0 else { abort("cannot spawn during a query") }
  self.component_collector.reset()
  bundle.collect(self.component_collector)
  guard self.component_collector.valid else {
    abort("invalid component bundle")
  }
  let archetype = self.archetype(
    component_set_hash(self.component_collector.words),
    bundle,
  )
  let row = self.archetypes[archetype].entities.length()
  let entity = self.allocate_entity(archetype, row)
  self.archetypes[archetype].entities.push(entity)
  bundle.append(archetype)
  entity
}

///|
pub fn[T] World::get(
  self : World,
  entity : Entity,
  key : ComponentKey[T],
) -> T? {
  guard key.world_id == self.id else { None }
  guard self.location(entity) is Some((archetype, row)) else { None }
  match key.columns.get(archetype) {
    Some(Some(column)) => column.get(row)
    _ => None
  }
}

///|
/// A cached two-component query. It scans only newly created archetypes.
struct Query2[A, B] {
  world : World
  a : ComponentKey[A]
  b : ComponentKey[B]
  matches : Array[Int]
  mut scanned : Int
}

///|
pub fn[A, B] World::query2(
  self : World,
  a : ComponentKey[A],
  b : ComponentKey[B],
) -> Query2[A, B] {
  guard a.world_id == self.id && b.world_id == self.id else {
    abort("component key belongs to another world")
  }
  { world: self, a, b, matches: [], scanned: 0, }
}

///|
fn[A, B] Query2::refresh(self : Query2[A, B]) -> Unit {
  for archetype in self.scanned..<self.world.archetypes.length() {
    let components = self.world.archetypes[archetype].components
    if components.contains(self.a.id) && components.contains(self.b.id) {
      self.matches.push(archetype)
    }
  }
  self.scanned = self.world.archetypes.length()
}

///|
pub fn[A, B] Query2::for_each(
  self : Query2[A, B],
  f : (Entity, A, B) -> Unit,
) -> Unit {
  self.refresh()
  self.world.active_queries += 1
  for archetype in self.matches {
    let entities = self.world.archetypes[archetype].entities
    let a = self.a.column(archetype)
    let b = self.b.column(archetype)
    for row in 0..<entities.length() {
      f(entities[row], a[row], b[row])
    }
  }
  self.world.active_queries -= 1
}

///|
pub fn[A, B] Query2::for_each_mut_a(
  self : Query2[A, B],
  f : (Entity, A, B) -> A,
) -> Unit {
  self.refresh()
  self.world.active_queries += 1
  for archetype in self.matches {
    let entities = self.world.archetypes[archetype].entities
    let a = self.a.column(archetype)
    let b = self.b.column(archetype)
    for row in 0..<entities.length() {
      a[row] = f(entities[row], a[row], b[row])
    }
  }
  self.world.active_queries -= 1
}

///|
pub fn[A, B] Query2::for_each_batch(
  self : Query2[A, B],
  f : (ArrayView[Entity], ArrayView[A], ArrayView[B]) -> Unit,
) -> Unit {
  self.refresh()
  self.world.active_queries += 1
  for archetype in self.matches {
    f(
      self.world.archetypes[archetype].entities[:],
      self.a.column(archetype)[:],
      self.b.column(archetype)[:],
    )
  }
  self.world.active_queries -= 1
}

///|
pub fn[A, B] Query2::for_each_batch_mut_a(
  self : Query2[A, B],
  f : (ArrayView[Entity], MutArrayView[A], ArrayView[B]) -> Unit,
) -> Unit {
  self.refresh()
  self.world.active_queries += 1
  for archetype in self.matches {
    f(
      self.world.archetypes[archetype].entities[:],
      self.a.column(archetype).mut_view(),
      self.b.column(archetype)[:],
    )
  }
  self.world.active_queries -= 1
}
