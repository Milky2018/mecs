///|
/// Fixed-composition archetype storage.
struct Entity(Int) derive(Eq, Debug)

///|
pub extend Entity with Eq::{equal, not_equal}

///|
pub extend Entity with @debug.Debug::{to_repr}

///|
priv struct Archetype {
  signature : UInt64
  entities : Array[Entity]
}

///|
/// A typed lookup from an archetype id to its contiguous component column.
struct ComponentKey[T] {
  bit : UInt64
  owner : Array[Unit]
  columns : Array[Array[T]?]
}

///|
/// A component value paired with its typed storage key for spawning.
struct ComponentEntry[T] {
  key : ComponentKey[T]
  value : T
}

///|
pub(open) trait Bundle {
  fn signature(Self) -> UInt64
  fn valid(Self, Array[Unit]) -> Bool
  fn prepare(Self, Int) -> Unit
  fn append(Self, Int) -> Unit
}

///|
pub impl[T] Bundle for ComponentEntry[T] with fn signature(self) {
  self.key.bit
}

///|
pub impl[T] Bundle for ComponentEntry[T] with fn valid(self, owner) {
  physical_equal(self.key.owner, owner)
}

///|
pub impl[T] Bundle for ComponentEntry[T] with fn prepare(self, archetype) {
  self.key.ensure(archetype)
}

///|
pub impl[T] Bundle for ComponentEntry[T] with fn append(self, archetype) {
  self.key.column(archetype).push(self.value)
}

///|
pub extend ComponentEntry with Bundle::{append, prepare, signature, valid}

///|
pub impl[L : Bundle, R : Bundle] Bundle for (L, R) with fn signature(self) {
  self.0.signature() | self.1.signature()
}

///|
pub impl[L : Bundle, R : Bundle] Bundle for (L, R) with fn valid(self, owner) {
  self.0.valid(owner) &&
  self.1.valid(owner) &&
  (self.0.signature() & self.1.signature()) == 0UL
}

///|
pub impl[L : Bundle, R : Bundle] Bundle for (L, R) with fn prepare(
  self,
  archetype,
) {
  self.0.prepare(archetype)
  self.1.prepare(archetype)
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
  owner : Array[Unit]
  mut next_entity : Int
  mut next_component : Int
  locations : Array[(Int, Int)]
  archetypes : Array[Archetype]
  archetype_index : @hashmap.HashMap[UInt64, Int]
}

///|
pub fn World::new() -> World {
  {
    owner: [],
    next_entity: 0,
    next_component: 0,
    locations: [],
    archetypes: [],
    archetype_index: HashMap([]),
  }
}

///|
/// Registers a world-local component key. This prototype supports at most 63.
pub fn[T] World::component(self : World) -> ComponentKey[T] {
  guard self.next_component < 63 else { abort("too many component types") }
  let id = self.next_component
  self.next_component += 1
  { bit: 1UL << id, owner: self.owner, columns: [], }
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
fn[B : Bundle] World::archetype(
  self : World,
  signature : UInt64,
  bundle : B,
) -> Int {
  match self.archetype_index.get(signature) {
    Some(id) => id
    None => {
      let id = self.archetypes.length()
      self.archetypes.push({ signature, entities: [], })
      self.archetype_index[signature] = id
      bundle.prepare(id)
      id
    }
  }
}

///|
/// Spawns directly into the final archetype. Components cannot change later.
pub fn[B : Bundle] World::spawn(self : World, bundle : B) -> Entity {
  guard bundle.valid(self.owner) else { abort("invalid component bundle") }
  let archetype = self.archetype(bundle.signature(), bundle)
  let row = self.archetypes[archetype].entities.length()
  let entity = Entity(self.next_entity)
  self.next_entity += 1
  self.archetypes[archetype].entities.push(entity)
  bundle.append(archetype)
  self.locations.push((archetype, row))
  entity
}

///|
pub fn[T] World::get(
  self : World,
  entity : Entity,
  key : ComponentKey[T],
) -> T? {
  let (archetype, row) = self.locations[entity.0]
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
  guard physical_equal(a.owner, self.owner) &&
    physical_equal(b.owner, self.owner) else {
    abort("component key belongs to another world")
  }
  { world: self, a, b, matches: [], scanned: 0, }
}

///|
fn[A, B] Query2::refresh(self : Query2[A, B]) -> Unit {
  let required = self.a.bit | self.b.bit
  for archetype in self.scanned..<self.world.archetypes.length() {
    if (self.world.archetypes[archetype].signature & required) == required {
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
  for archetype in self.matches {
    let entities = self.world.archetypes[archetype].entities
    let a = self.a.column(archetype)
    let b = self.b.column(archetype)
    for row in 0..<entities.length() {
      f(entities[row], a[row], b[row])
    }
  }
}

///|
pub fn[A, B] Query2::for_each_mut_a(
  self : Query2[A, B],
  f : (Entity, A, B) -> A,
) -> Unit {
  self.refresh()
  for archetype in self.matches {
    let entities = self.world.archetypes[archetype].entities
    let a = self.a.column(archetype)
    let b = self.b.column(archetype)
    for row in 0..<entities.length() {
      a[row] = f(entities[row], a[row], b[row])
    }
  }
}

///|
pub fn[A, B] Query2::for_each_batch(
  self : Query2[A, B],
  f : (ArrayView[Entity], ArrayView[A], ArrayView[B]) -> Unit,
) -> Unit {
  self.refresh()
  for archetype in self.matches {
    f(
      self.world.archetypes[archetype].entities[:],
      self.a.column(archetype)[:],
      self.b.column(archetype)[:],
    )
  }
}

///|
pub fn[A, B] Query2::for_each_batch_mut_a(
  self : Query2[A, B],
  f : (ArrayView[Entity], MutArrayView[A], ArrayView[B]) -> Unit,
) -> Unit {
  self.refresh()
  for archetype in self.matches {
    f(
      self.world.archetypes[archetype].entities[:],
      self.a.column(archetype).mut_view(),
      self.b.column(archetype)[:],
    )
  }
}
