///|
priv enum Command {
  Spawn(EntityId)
  Despawn(EntityId)
  InsertComponent(EntityId, ComponentId, Component)
  RemoveComponent(EntityId, ComponentId)
  SetResource(ResourceId, Resource)
  RemoveResource(ResourceId)
}

///|
struct Commands {
  world : World
  mut ops : Array[Command]
}

///|
pub fn World::commands(self : Self) -> Commands {
  { world: self, ops: [], }
}

///|
pub fn Commands::spawn(self : Self) -> EntityId {
  let entity = self.world.reserve_entity_id()
  self.ops.push(Spawn(entity))
  entity
}

///|
pub fn Commands::despawn(self : Self, entity : EntityId) -> Unit {
  self.ops.push(Despawn(entity))
}

///|
pub fn[C : ComponentValue] Commands::insert_component(
  self : Self,
  entity : EntityId,
  component : C,
) -> Unit {
  self.ops.push(
    InsertComponent(entity, C::component_id(), C::to_component(component)),
  )
}

///|
pub fn[C : ComponentValue] Commands::remove_component(
  self : Self,
  entity : EntityId,
  _hint? : C? = None,
) -> Unit {
  self.ops.push(RemoveComponent(entity, C::component_id()))
}

///|
pub fn[R : ResourceValue] Commands::set_resource(
  self : Self,
  resource : R,
) -> Unit {
  self.ops.push(SetResource(R::resource_id(), R::to_resource(resource)))
}

///|
pub fn[R : ResourceValue] Commands::remove_resource(
  self : Self,
  _hint? : R? = None,
) -> Unit {
  self.ops.push(RemoveResource(R::resource_id()))
}

///|
pub fn World::apply_commands(
  self : Self,
  commands : Commands,
) -> Unit raise NotSpawned {
  let ops = commands.ops
  commands.ops = []
  for op in ops {
    match op {
      Spawn(entity) => self.spawn_reserved(entity)
      Despawn(entity) => ignore(self.despawn(entity))
      InsertComponent(entity, id, component) =>
        self.insert_component_value(entity, id, component)
      RemoveComponent(entity, id) => self.remove_component_value(entity, id)
      SetResource(id, resource) => self.resources[id] = resource
      RemoveResource(id) => self.resources.remove(id)
    }
  }
}
