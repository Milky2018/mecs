///|
struct EntityOps {
  world : World
  entity : EntityId
}

///|
pub fn[C : ComponentValue] EntityOps::insert_component(
  self : Self,
  component : C,
) -> Unit raise NotSpawned {
  self.world.insert_component(self.entity, component)
}

///|
pub fn[C : ComponentValue] EntityOps::insert_component_checked(
  self : Self,
  component : C,
) -> Unit raise EcsError {
  self.world.insert_component_checked(self.entity, component)
}

///|
pub fn[C : ComponentValue] EntityOps::remove_component(
  self : Self,
  _hint? : C? = None,
) -> Unit {
  self.world.remove_component(self.entity, _hint~)
}

///|
pub fn[C : ComponentValue] EntityOps::remove_component_checked(
  self : Self,
  _hint? : C? = None,
) -> Unit raise EcsError {
  self.world.remove_component_checked(self.entity, _hint~)
}

///|
pub fn EntityOps::despawn(self : Self) -> Bool {
  self.world.despawn(self.entity)
}

///|
pub fn EntityOps::despawn_checked(self : Self) -> Unit raise EcsError {
  self.world.despawn_checked(self.entity)
}
