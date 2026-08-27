///|
struct World {
  mut entity_id_gen : UInt
  entities : @set.Set[EntityId]
  component_ids : Map[EntityId, Array[ComponentId]]
  component_stores : Map[ComponentId, @hashmap.HashMap[EntityId, Component]]
  resources : Map[ResourceId, Resource]
  systems : Array[ScheduledSystem]
  mut startup_complete : Bool
}

///|
pub fn World::World() -> Self {
  {
    entity_id_gen: 0,
    entities: Set([]),
    component_ids: {},
    component_stores: {},
    resources: {},
    systems: [],
    startup_complete: false,
  }
}

///|
pub fn World::spawn(self : Self) -> EntityId {
  let entity = self.reserve_entity_id()
  self.spawn_reserved(entity)
  entity
}

///|
fn World::reserve_entity_id(self : Self) -> EntityId {
  let entity = EntityId::EntityId(self.entity_id_gen)
  self.entity_id_gen += 1
  entity
}

///|
fn World::spawn_reserved(self : Self, entity : EntityId) -> Unit {
  if entity.value() >= self.entity_id_gen {
    self.entity_id_gen = entity.value() + 1
  }
  guard !self.is_alive(entity) else { return }
  self.entities.add(entity)
  self.component_ids[entity] = []
}

///|
pub fn[B : Bundle] World::spawn_with(self : Self, bundle : B) -> EntityId {
  let entity = self.spawn()
  bundle.insert_into(self, entity)
  entity
}

///|
pub fn World::is_alive(self : Self, entity : EntityId) -> Bool {
  self.entities.contains(entity)
}

///|
pub fn World::despawn(self : Self, entity : EntityId) -> Bool {
  guard self.is_alive(entity) else { return false }
  match self.component_ids.get(entity) {
    Some(ids) =>
      ids.each(fn(id) { self.remove_component_from_store(entity, id) })
    None => ()
  }
  self.entities.remove(entity)
  self.component_ids.remove(entity)
  true
}

///|
pub fn World::despawn_checked(
  self : Self,
  entity : EntityId,
) -> Unit raise EcsError {
  guard self.despawn(entity) else { raise EntityMissing(entity) }
}

///|
fn World::entity_component_ids(
  self : Self,
  entity : EntityId,
) -> Array[ComponentId]? {
  self.component_ids.get(entity)
}

///|
fn World::component_store(
  self : Self,
  id : ComponentId,
) -> @hashmap.HashMap[EntityId, Component]? {
  self.component_stores.get(id)
}

///|
fn World::component_store_len(self : Self, id : ComponentId) -> Int {
  match self.component_store(id) {
    Some(store) => store.length()
    None => 0
  }
}

///|
fn World::insert_component_into_store(
  self : Self,
  entity : EntityId,
  id : ComponentId,
  component : Component,
) -> Unit {
  let store = self.component_stores.get_or_init(id, fn() { HashMap([]) })
  store[entity] = component
}

///|
fn World::remove_component_from_store(
  self : Self,
  entity : EntityId,
  id : ComponentId,
) -> Unit {
  match self.component_stores.get(id) {
    Some(store) => {
      store.remove(entity)
      if store.is_empty() {
        self.component_stores.remove(id)
      }
    }
    None => ()
  }
}

///|
pub fn[C : ComponentValue] World::insert_component(
  self : Self,
  entity : EntityId,
  component : C,
) -> Unit raise NotSpawned {
  self.insert_component_value(
    entity,
    C::component_id(),
    C::to_component(component),
  )
}

///|
fn World::insert_component_value(
  self : Self,
  entity : EntityId,
  id : ComponentId,
  component : Component,
) -> Unit raise NotSpawned {
  guard self.is_alive(entity) else { raise NotSpawned(entity) }
  let ids = self.component_ids.get_or_init(entity, fn() {
    Array::new(capacity=4)
  })
  if !ids.contains(id) {
    ids.push(id)
  }
  self.insert_component_into_store(entity, id, component)
}

///|
pub fn[C : ComponentValue] World::insert_component_checked(
  self : Self,
  entity : EntityId,
  component : C,
) -> Unit raise EcsError {
  guard self.is_alive(entity) else { raise EntityMissing(entity) }
  let id = C::component_id()
  let value = C::to_component(component)
  let ids = self.component_ids.get_or_init(entity, fn() {
    Array::new(capacity=4)
  })
  if !ids.contains(id) {
    ids.push(id)
  }
  self.insert_component_into_store(entity, id, value)
}

///|
pub fn[C : ComponentValue] World::has_component(
  self : Self,
  entity : EntityId,
  _hint? : C? = None,
) -> Bool {
  let component : C? = self.get_component(entity)
  component is Some(_)
}

///|
pub fn[C : ComponentValue] World::get_component(
  self : Self,
  entity : EntityId,
) -> C? {
  match self.component_store(C::component_id()) {
    Some(store) =>
      match store.get(entity) {
        Some(component) => C::from_component(component)
        None => None
      }
    None => None
  }
}

///|
pub fn[C : ComponentValue] World::get_component_checked(
  self : Self,
  entity : EntityId,
) -> C raise EcsError {
  let id = C::component_id()
  guard self.is_alive(entity) else { raise EntityMissing(entity) }
  match self.component_store(id) {
    Some(store) =>
      match store.get(entity) {
        Some(component) =>
          match C::from_component(component) {
            Some(value) => value
            None => raise ComponentVariantMismatch(entity, id)
          }
        None => raise ComponentMissing(entity, id)
      }
    None => raise ComponentMissing(entity, id)
  }
}

///|
pub fn[C : ComponentValue] World::require_component(
  self : Self,
  entity : EntityId,
) -> C {
  match self.get_component(entity) {
    Some(component) => component
    None => abort("component is missing on entity \{entity.value()}")
  }
}

///|
pub fn[C : ComponentValue] World::remove_component(
  self : Self,
  entity : EntityId,
  _hint? : C? = None,
) -> Unit {
  self.remove_component_value(entity, C::component_id())
}

///|
pub fn[C : ComponentValue] World::remove_component_checked(
  self : Self,
  entity : EntityId,
  _hint? : C? = None,
) -> Unit raise EcsError {
  let id = C::component_id()
  guard self.is_alive(entity) else { raise EntityMissing(entity) }
  match self.component_store(id) {
    Some(store) =>
      match store.get(entity) {
        Some(component) =>
          match C::from_component(component) {
            Some(_) => self.remove_component_value(entity, id)
            None => raise ComponentVariantMismatch(entity, id)
          }
        None => raise ComponentMissing(entity, id)
      }
    None => raise ComponentMissing(entity, id)
  }
}

///|
fn World::remove_component_value(
  self : Self,
  entity : EntityId,
  id : ComponentId,
) -> Unit {
  match self.entity_component_ids(entity) {
    Some(ids) => {
      match ids.search(id) {
        Some(index) => ignore(ids.remove(index))
        None => ()
      }
      self.remove_component_from_store(entity, id)
    }
    None => ()
  }
}

///|
pub fn[R : ResourceValue] World::set_resource(
  self : Self,
  resource : R,
) -> Unit {
  self.resources[R::resource_id()] = R::to_resource(resource)
}

///|
pub fn[R : ResourceValue] World::has_resource(
  self : Self,
  _hint? : R? = None,
) -> Bool {
  let resource : R? = self.try_get_resource()
  resource is Some(_)
}

///|
pub fn[R : ResourceValue] World::get_resource(self : Self) -> R {
  match self.try_get_resource() {
    Some(resource) => resource
    None => abort("resource is missing")
  }
}

///|
pub fn[R : ResourceValue] World::get_resource_checked(
  self : Self,
) -> R raise EcsError {
  let id = R::resource_id()
  match self.resources.get(id) {
    Some(resource) =>
      match R::from_resource(resource) {
        Some(value) => value
        None => raise ResourceVariantMismatch(id)
      }
    None => raise ResourceMissing(id)
  }
}

///|
pub fn[R : ResourceValue] World::try_get_resource(self : Self) -> R? {
  match self.resources.get(R::resource_id()) {
    Some(resource) => R::from_resource(resource)
    None => None
  }
}

///|
pub fn[R : ResourceValue] World::remove_resource(
  self : Self,
  _hint? : R? = None,
) -> Unit {
  self.resources.remove(R::resource_id())
}

///|
pub fn[R : ResourceValue] World::remove_resource_checked(
  self : Self,
  _hint? : R? = None,
) -> Unit raise EcsError {
  let id = R::resource_id()
  match self.resources.get(id) {
    Some(resource) =>
      match R::from_resource(resource) {
        Some(_) => self.resources.remove(id)
        None => raise ResourceVariantMismatch(id)
      }
    None => raise ResourceMissing(id)
  }
}

///|
pub fn World::entity_ops(self : Self, entity : EntityId) -> EntityOps {
  { world: self, entity, }
}

///|
pub fn World::add_system(self : Self, system : System) -> Unit {
  self.add_system_to_stage(Update, system)
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
pub fn World::add_command_system(self : Self, system : CommandSystem) -> Unit {
  self.add_command_system_to_stage(Update, system)
}

///|
pub fn World::add_command_system_fn(
  self : Self,
  func : (World, Commands) -> Unit,
  name? : String = "system",
) -> Unit {
  self.add_command_system(CommandSystem(func, name~))
}

///|
pub fn World::step(self : Self) -> Unit raise NotSpawned {
  if !self.startup_complete {
    self.run_stage(Startup)
    self.startup_complete = true
  }
  self.run_stage(Update)
  self.run_stage(Cleanup)
}
