///|
struct EntityOps {
  world : World
  entity : EntityId
}

///|
pub fn[C : Component] EntityOps::insert_component(
  self : Self,
  component : C,
) -> Unit {
  ignore(self.world.insert_component(self.entity, component))
}

///|
pub fn[C : Component] EntityOps::remove_component(self : Self) -> Unit {
  let _hint : C? = None
  ignore(_hint)
  raw_world_remove_component(self.world.raw, C::type_id(), self.entity)
}

///|
pub fn EntityOps::despawn(self : Self) -> Bool {
  self.world.despawn(self.entity)
}
