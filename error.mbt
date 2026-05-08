///|
pub suberror NotSpawned {
  NotSpawned(EntityId)
}

///|
pub(all) suberror EcsError {
  EntityMissing(EntityId)
  ComponentMissing(EntityId, ComponentId)
  ComponentVariantMismatch(EntityId, ComponentId)
  ResourceMissing(ResourceId)
  ResourceVariantMismatch(ResourceId)
} derive(Eq, Debug)
