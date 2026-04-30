///|
struct World {
  raw : RawWorld
  systems : Array[System]
}

///|
pub fn World::World() -> Self {
  { raw: raw_world_new(), systems: [] }
}

///|
pub fn World::spawn(self : Self) -> EntityId {
  raw_world_spawn(self.raw)
}

///|
pub fn[B : Bundle] World::spawn_with(self : Self, bundle : B) -> EntityId {
  let entity = self.spawn()
  bundle.insert_into(self, entity)
  entity
}

///|
pub fn World::is_alive(self : Self, entity : EntityId) -> Bool {
  raw_world_is_alive(self.raw, entity)
}

///|
pub fn World::despawn(self : Self, entity : EntityId) -> Bool {
  raw_world_despawn(self.raw, entity)
}

///|
pub fn[C : Component] World::insert_component(
  self : Self,
  entity : EntityId,
  component : C,
) -> Bool {
  guard self.is_alive(entity) else { return false }
  raw_world_set_component(
    self.raw,
    C::type_id(),
    entity,
    ref_to_any(Ref::new(component)),
  )
  true
}

///|
pub fn[C : Component] World::has_component(
  self : Self,
  entity : EntityId,
  _hint? : C? = None,
) -> Bool {
  raw_world_has_component(self.raw, C::type_id(), entity)
}

///|
pub fn[C : Component] World::get_component(
  self : Self,
  entity : EntityId,
) -> C? {
  guard raw_world_has_component(self.raw, C::type_id(), entity) else {
    return None
  }
  Some(any_to_ref(raw_world_get_component(self.raw, C::type_id(), entity)).val)
}

///|
pub fn[C : Component] World::require_component(
  self : Self,
  entity : EntityId,
) -> C {
  any_to_ref(raw_world_get_component(self.raw, C::type_id(), entity)).val
}

///|
pub fn[C : Component] World::remove_component(
  self : Self,
  entity : EntityId,
  _hint? : C? = None,
) -> Unit {
  raw_world_remove_component(self.raw, C::type_id(), entity)
}

///|
pub fn[R : Resource] World::set_resource(self : Self, resource : R) -> Unit {
  raw_world_set_resource(self.raw, R::type_id(), ref_to_any(Ref::new(resource)))
}

///|
pub fn[R : Resource] World::has_resource(
  self : Self,
  _hint? : R? = None,
) -> Bool {
  raw_world_has_resource(self.raw, R::type_id())
}

///|
pub fn[R : Resource] World::get_resource(self : Self) -> R {
  any_to_ref(raw_world_get_resource(self.raw, R::type_id())).val
}

///|
pub fn[R : Resource] World::try_get_resource(self : Self) -> R? {
  guard raw_world_has_resource(self.raw, R::type_id()) else { return None }
  Some(any_to_ref(raw_world_get_resource(self.raw, R::type_id())).val)
}

///|
pub fn[R : Resource] World::remove_resource(
  self : Self,
  _hint? : R? = None,
) -> Unit {
  raw_world_remove_resource(self.raw, R::type_id())
}

///|
pub fn World::entity_ops(self : Self, entity : EntityId) -> EntityOps {
  EntityOps::{ world: self, entity }
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
