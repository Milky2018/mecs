///|
struct World {
  mut entity_id_gen : UInt
  entities : @set.Set[Bool]
  component_storages : Map[ComponentId, ComponentStorage]
}

///|
pub fn World::World() -> World {
  { entity_id_gen: 0, entities: @set.Set::new(), component_storages: {} }
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
  let comp_name = C::debug_name()
  let storage = self.component_storages[comp_name]
  storage.set(ent, comp)
}

///|
pub fn World::entity_ops(self : Self, ent : EntityId) -> EntityOps {
  EntityOps(() => self.component_storages, ent)
}

pub fn[A] World::query1(self : Self) -> Query1[A] {

}