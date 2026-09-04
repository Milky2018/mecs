///|
/// A world-local handle. Reusing a slot never revives an old handle.
struct Entity {
  world_id : WorldId
  index : Int
  generation : UInt64
} derive(Eq, Debug)

///|
pub extend Entity with Eq::{equal, not_equal}

///|
pub extend Entity with @debug.Debug::{to_repr}

///|
priv struct EntitySlot {
  mut generation : UInt64
  mut location : (Int, Int)?
}

///|
fn World::allocate_entity(self : World, archetype : Int, row : Int) -> Entity {
  let index = match self.free_slots.pop() {
    Some(index) => index
    None => {
      let index = self.slots.length()
      self.slots.push({ generation: 0UL, location: None, })
      index
    }
  }
  let slot = self.slots[index]
  slot.location = Some((archetype, row))
  { world_id: self.id, index, generation: slot.generation, }
}

///|
fn World::location(self : World, entity : Entity) -> (Int, Int)? {
  guard entity.world_id == self.id else { None }
  guard self.slots.get(entity.index) is Some(slot) else { None }
  guard slot.generation == entity.generation else { None }
  slot.location
}

///|
/// Returns false for foreign-world, despawned, or stale handles.
pub fn World::is_alive(self : World, entity : Entity) -> Bool {
  self.location(entity) is Some(_)
}

///|
fn[T] swap_remove_row(column : Array[T], row : Int) -> Unit {
  let last = column.length() - 1
  if row != last {
    column[row] = column[last]
  }
  ignore(column.pop())
}

///|
/// Permanently invalidates this handle and removes its component row.
/// Returns false for foreign-world, despawned, or stale handles.
/// Panics if a live entity is removed inside a query callback on this world.
pub fn World::despawn(self : World, entity : Entity) -> Bool {
  guard self.location(entity) is Some((archetype_id, row)) else { false }
  guard self.active_queries == 0 else { abort("cannot despawn during a query") }
  let archetype = self.archetypes[archetype_id]
  let last = archetype.entities.length() - 1
  let moved = archetype.entities[last]
  (archetype.remove_components)(row)
  swap_remove_row(archetype.entities, row)
  if row != last {
    self.slots[moved.index].location = Some((archetype_id, row))
  }
  let slot = self.slots[entity.index]
  slot.location = None
  // Retire exhausted slots instead of wrapping and reviving stale handles.
  if slot.generation != 0xffffffffffffffffUL {
    slot.generation += 1UL
    self.free_slots.push(entity.index)
  }
  true
}
