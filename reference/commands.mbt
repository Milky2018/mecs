///|
priv struct CommandState {
  world : World
  mut actions : Array[(World) -> Unit]
  mut applying : Bool
}

///|
/// Owns deferred structural changes and is the only handle that can apply them.
struct CommandBuffer {
  state : CommandState
}

///|
/// A restricted handle that can enqueue, but cannot apply, structural changes.
struct CommandEmitter {
  state : CommandState
}

///|
pub fn World::command_buffer(self : World) -> CommandBuffer {
  { state: { world: self, actions: [], applying: false, }, }
}

///|
pub fn CommandBuffer::emitter(self : CommandBuffer) -> CommandEmitter {
  { state: self.state, }
}

///|
pub fn[B : Bundle] CommandEmitter::spawn(
  self : CommandEmitter,
  bundle : B,
) -> Unit {
  // Validate now so malformed commands fail at their call site.
  ignore(bundle.bitmask(self.state.world.id))
  self.state.actions.push(fn(world) { ignore(world.spawn(bundle)) })
}

///|
pub fn CommandEmitter::despawn(self : CommandEmitter, entity : Entity) -> Unit {
  guard entity.world_id == self.state.world.id else {
    abort("entity belongs to another world")
  }
  self.state.actions.push(fn(world) { ignore(world.despawn(entity)) })
}

///|
/// Applies the commands that were queued before this call in insertion order.
/// Commands emitted while applying remain queued for the next call.
pub fn CommandBuffer::apply(self : CommandBuffer) -> Unit {
  guard self.state.world.active_queries == 0 else {
    abort("cannot apply commands during a query")
  }
  guard !self.state.applying else {
    abort("command buffer is already applying")
  }
  let batch = self.state.actions
  self.state.actions = []
  self.state.applying = true
  for action in batch {
    action(self.state.world)
  }
  self.state.applying = false
}
