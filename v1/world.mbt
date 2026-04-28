///|
struct World {
  mut entity_id_gen : EntityId
  entities : @set.Set[EntityId]
  component_storages : Map[ComponentId, ComponentStorage]
  systems : Array[System]
  resources : ResourceStorage
}

///|
pub fn World::World() -> World {
  {
    entity_id_gen: 0,
    entities: @set.Set::new(),
    component_storages: {},
    systems: [],
    resources: ResourceStorage(),
  }
}

///|
pub fn World::spawn_entity(self : World) -> EntityId {
  let id = self.entity_id_gen
  self.entity_id_gen += 1
  self.entities.add(id)
  id
}

///|
pub fn[C : Component] World::assign_component(
  self : World,
  ent : EntityId,
  comp : C,
) -> Unit {
  let comp_name = C::type_id()
  let storage = self.component_storages[comp_name]
  storage.set(ent, comp)
}

///|
pub fn World::entity_ops(self : Self, ent : EntityId) -> EntityOps {
  EntityOps(() => self.component_storages, ent)
}

///|
pub fn[A : Querable] World::query(self : Self) -> Iter[A] {
  A::iter(self)
}

///|
pub fn[C : Component] World::query1(self : Self) -> Iter[C] {
  let storage = self.component_storages[C::type_id()]
  storage.values()
}

///|
pub fn World::add_system(self : Self, system : System) -> Unit {
  self.systems.push(system)
}

///|
pub fn World::step(self : Self) -> Unit {
  for system in self.systems {
    (system.func)(self)
  }
}

///|
pub fn[R : Resource] World::set_resource(self : Self, r : R) -> Unit {
  self.resources.set(r)
}

pub fn[R : Resource] World::get_resource(self : Self) -> R {
  self.resources.get()
}