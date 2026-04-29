///|
struct World {
  mut entity_id_gen : EntityId
  entities : @set.Set[EntityId]
  systems : Array[System]
  cleanup : Array[(EntityId) -> Unit]
}

///|
pub fn World::World() -> Self {
  { entity_id_gen: 0, entities: @set.Set::new(), systems: [], cleanup: [] }
}

///|
pub fn World::spawn(self : Self) -> EntityId {
  let entity = self.entity_id_gen
  self.entity_id_gen += 1
  self.entities.add(entity)
  entity
}

///|
pub fn World::is_alive(self : Self, entity : EntityId) -> Bool {
  self.entities.contains(entity)
}

///|
pub fn World::despawn(self : Self, entity : EntityId) -> Bool {
  guard self.is_alive(entity) else { return false }
  self.entities.remove(entity)
  for cleanup in self.cleanup {
    cleanup(entity)
  }
  true
}

///|
pub fn[C] World::register_component_store(
  self : Self,
  store : ComponentStore[C],
) -> Unit {
  self.cleanup.push(fn(entity) { store.remove(entity) })
}

///|
pub fn[C] World::insert_component(
  self : Self,
  entity : EntityId,
  store : ComponentStore[C],
  component : C,
) -> Bool {
  guard self.is_alive(entity) else { return false }
  store.insert(entity, component)
  true
}

///|
pub fn[C] World::remove_component(
  _self : Self,
  entity : EntityId,
  store : ComponentStore[C],
) -> Unit {
  store.remove(entity)
}

///|
pub fn[C] World::get_component(
  self : Self,
  entity : EntityId,
  store : ComponentStore[C],
) -> C? {
  guard self.is_alive(entity) else { return None }
  store.get(entity)
}

///|
pub fn World::add_system(self : Self, system : System) -> Unit {
  self.systems.push(system)
}

///|
pub fn World::add_system_fn(
  self : Self,
  func : (World) -> Unit,
  name? : String = "system",
) -> Unit {
  self.add_system(System(func, name~))
}

///|
pub fn World::step(self : Self) -> Unit {
  for system in self.systems {
    (system.func)(self)
  }
}
