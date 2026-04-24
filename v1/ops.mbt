///|
struct EntityOps {
  get_storages : () -> Map[ComponentId, ComponentStorage]
  entity : EntityId
}

///|
pub fn EntityOps::EntityOps(
  get_storages : () -> Map[ComponentId, ComponentStorage],
  entity : EntityId,
) -> Self {
  EntityOps::{ get_storages, entity }
}

///|
pub fn[C : Component] EntityOps::insert_component(
  self : EntityOps,
  comp : C,
) -> Unit {
  let storages = (self.get_storages)()
  let storage = storages[C::debug_name()]
  storage.set(self.entity, comp) 
}
