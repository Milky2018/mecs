///|
struct World {
  mut entity_id_gen : EntityId
  entities : @set.Set[EntityId]
  components : Map[EntityId, Map[ComponentId, Component]]
  resources : Map[ResourceId, Resource]
  systems : Array[System]
}

///|
pub fn World::World() -> Self {
  {
    entity_id_gen: 0,
    entities: Set([]),
    components: {},
    resources: {},
    systems: [],
  }
}

///|
pub fn World::spawn(self : Self) -> EntityId {
  let entity = self.entity_id_gen
  self.entity_id_gen += 1
  self.entities.add(entity)
  self.components[entity] = {}
  entity
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
  self.entities.remove(entity)
  self.components.remove(entity)
  true
}

///|
fn World::component_map(
  self : Self,
  entity : EntityId,
) -> Map[ComponentId, Component]? {
  self.components.get(entity)
}

///|
pub fn[C : ComponentValue] World::insert_component(
  self : Self,
  entity : EntityId,
  component : C,
) -> Unit raise NotSpawned {
  guard self.is_alive(entity) else { raise NotSpawned(entity) }
  let map = self.components.get_or_init(entity, fn() { {} })
  map[C::component_id()] = C::to_component(component)
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
  match self.component_map(entity) {
    Some(map) =>
      match map.get(C::component_id()) {
        Some(component) => C::from_component(component)
        None => None
      }
    None => None
  }
}

///|
pub fn[C : ComponentValue] World::require_component(
  self : Self,
  entity : EntityId,
) -> C {
  match self.get_component(entity) {
    Some(component) => component
    None => abort("component is missing on entity \{entity}")
  }
}

///|
pub fn[C : ComponentValue] World::remove_component(
  self : Self,
  entity : EntityId,
  _hint? : C? = None,
) -> Unit {
  match self.component_map(entity) {
    Some(map) => map.remove(C::component_id())
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
pub fn World::entity_ops(self : Self, entity : EntityId) -> EntityOps {
  { world: self, entity }
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
