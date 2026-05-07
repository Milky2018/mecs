///|
struct EntityOps {
  world : World
  entity : EntityId
}

///|
pub fn[C : ComponentValue] EntityOps::insert_component(
  self : Self,
  component : C,
) -> Unit {
  ignore(self.world.insert_component(self.entity, component))
}

///|
pub fn[C : ComponentValue] EntityOps::remove_component(self : Self) -> Unit {
  let hint : C? = None
  self.world.remove_component(self.entity, _hint=hint)
}

///|
pub fn EntityOps::despawn(self : Self) -> Bool {
  self.world.despawn(self.entity)
}
