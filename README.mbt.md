# Milky2018/mecs

`mecs` is a portable ECS library for MoonBit. It uses extensible enums for
type-safe component and resource storage, without compiler primitives,
type-erased `Any`, or C FFI.

## Quick Start

Users extend `@mecs.Component` and `@mecs.Resource`, then implement
`ComponentValue` and `ResourceValue` for their own types. The `component_id` or
`resource_id` must be exactly the same text as the extensible enum variant
constructor name. The full constructor forms are
`@mecs.ComponentId::ComponentId("VariantName")` and
`@mecs.ResourceId::ResourceId("VariantName")`. The helper functions
`component_id("VariantName")` and `resource_id("VariantName")` make the common
case shorter while preserving the same invariant.

```mbt check
///|
struct ReadmePosition {
  mut x : Int
  mut y : Int
}

///|
struct ReadmeVelocity {
  x : Int
  y : Int
}

///|
struct ReadmeFrame {
  value : Int
}

///|
extenum @mecs.Component += {
  ReadmePosition(ReadmePosition)
  ReadmeVelocity(ReadmeVelocity)
}

///|
extenum @mecs.Resource += {
  ReadmeFrame(ReadmeFrame)
}

///|
impl @mecs.ComponentValue for ReadmePosition with component_id() {
  component_id("ReadmePosition")
}

///|
impl @mecs.ComponentValue for ReadmePosition with to_component(self) {
  ReadmePosition(self)
}

///|
impl @mecs.ComponentValue for ReadmePosition with from_component(component) {
  match component {
    ReadmePosition(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ComponentValue for ReadmeVelocity with component_id() {
  component_id("ReadmeVelocity")
}

///|
impl @mecs.ComponentValue for ReadmeVelocity with to_component(self) {
  ReadmeVelocity(self)
}

///|
impl @mecs.ComponentValue for ReadmeVelocity with from_component(component) {
  match component {
    ReadmeVelocity(value) => Some(value)
    _ => None
  }
}

///|
impl @mecs.ResourceValue for ReadmeFrame with resource_id() {
  resource_id("ReadmeFrame")
}

///|
impl @mecs.ResourceValue for ReadmeFrame with to_resource(self) {
  ReadmeFrame(self)
}

///|
impl @mecs.ResourceValue for ReadmeFrame with from_resource(resource) {
  match resource {
    ReadmeFrame(value) => Some(value)
    _ => None
  }
}

///|
fn readme_move_system(world : @mecs.World) -> Unit {
  try! world.each2(fn(
    velocity : ReadmeVelocity,
    position : ReadmePosition,
  ) -> Unit {
    position.x += velocity.x
    position.y += velocity.y
  })
}

///|
fn readme_frame_system(world : @mecs.World) -> Unit {
  let frame : ReadmeFrame = world.get_resource()
  world.set_resource(ReadmeFrame::{ value: frame.value + 1 })
}

///|
test "readme quick start" {
  let world = @mecs.World()
  world.set_resource(ReadmeFrame::{ value: 0 })
  let entity = world.spawn_with(
    (ReadmePosition::{ x: 0, y: 0 }, ReadmeVelocity::{ x: 2, y: 3 }),
  )
  world
  ..add_system(System(readme_move_system))
  ..add_system(System(readme_frame_system))
  |> ignore
  try! world.step()
  let position : ReadmePosition = world.require_component(entity)
  let rows : Array[(@mecs.EntityId, (ReadmeVelocity, ReadmePosition))] = world
    .query2_entities()
    .to_array()
  inspect((position.x, position.y), content="(2, 3)")
  inspect((world.get_resource() : ReadmeFrame).value, content="1")
  inspect(rows.length(), content="1")
}
```

See [examples/basic](/examples/basic) for the same pattern as a complete tested
package.

## Id Invariant

The id chooses the storage slot. `to_component` and `to_resource` write the
extensible enum value into that slot. `from_component` and `from_resource`
verify that the stored enum variant really belongs to the requested type. If two
types intentionally or accidentally use the same id, the newer value overwrites
the same slot, and typed reads for the other variant return `None`.

See [docs/ergonomics.md](/docs/ergonomics.md) for copyable component and
resource templates, and [docs/migration.md](/docs/migration.md) for migration
notes from the earlier experimental designs. Performance benchmarks and storage
tradeoffs are tracked in [docs/performance.md](/docs/performance.md).

## Entity Handles

`EntityId` is an opaque entity handle, not an integer alias. Users receive
entity handles from `World::spawn`, `World::spawn_with`, `Commands::spawn`, or
entity-returning query APIs. The handle can be copied, compared, hashed, and
used with world APIs, but arbitrary ids should not be constructed by user code.

Use `EntityId::value` only when a stable numeric value is needed for logging,
diagnostics, serialization keys, or tests.

## Insert Failures

`World::insert_component` and `EntityOps::insert_component` return `Unit`. If
the target entity has not been spawned or has already been despawned, they raise
`NotSpawned(entity)`.

## Failure Model

The library keeps convenience APIs for small examples while exposing checked
APIs for production paths.

`get_component`, `try_get_resource`, `has_component`, and `has_resource` are
non-raising absence checks. They return `None` or `false` when state is missing,
and component/resource reads also return absence when an id exists but stores a
different extensible-enum variant.

`despawn` returns `false` when the entity is not alive. `remove_component` and
`remove_resource` are idempotent and return `Unit`; missing targets are no-ops.

`require_component` and `get_resource` are convenience APIs. They abort when the
requested value is absent and should not be used for expected-missing production
state.

Checked APIs report expected failures with `EcsError`: `despawn_checked`,
`insert_component_checked`, `get_component_checked`,
`remove_component_checked`, `get_resource_checked`, and
`remove_resource_checked`. `EntityOps` exposes checked variants for insert,
remove, and despawn as well. These APIs distinguish `EntityMissing`,
`ComponentMissing`, `ComponentVariantMismatch`, `ResourceMissing`, and
`ResourceVariantMismatch`.

`insert_component`, `EntityOps::insert_component`, `apply_commands`, `each2`,
`each3`, `step`, `fixed_step`, and `run_stage` raise `NotSpawned` when a write
targets an entity that is not alive.

## Mutation Semantics

`query1` through `query5`, and their `queryN_entities` variants, are lazy read
queries. They yield component values from the world and do not write changes
back by themselves. Entity-returning query variants consistently return
`Iter2[EntityId, (...)]`, with `query1_entities` returning `Iter2[EntityId, C]`.

`for_each1` through `for_each5` are streaming query helpers. They avoid allocating
an intermediate result array and do not snapshot rows or perform explicit
writeback. If a component value contains mutable state, mutating it inside the
callback can still affect the stored component immediately. Use these helpers
for non-structural traversals and reductions.

`each2` and `each3` are the supported mutating query helpers. They first
materialize the matching rows, then call the user callback for each row, then
write the queried components back to the same entity. This means components
mutated inside the callback persist after `eachN` returns.

Rows are snapshotted before callbacks run. Entities spawned during an `eachN`
callback are not visited by that same `eachN` call. Non-queried components can be
inserted or removed during the callback and those structural changes persist.
If the yielded entity itself is despawned before `eachN` writes components back,
`eachN` raises `NotSpawned(entity)`.

Duplicate component types in a query are allowed and are treated as repeated
typed reads from the same entity component slot. For example,
`query2_entities[Position, Position]` yields two `Position` values read from the
same stored `Position` component.

`QueryFilter` adds typed `with` and `without` component constraints to
`query1_filtered` through `query5_filtered` and their
`queryN_entities_filtered` variants:

```moonbit nocheck
///|
let moving = @mecs.QueryFilter().with_component(_hint=(None : ReadmeVelocity?))

///|
let moving_positions : Array[ReadmePosition] = world
  .query1_filtered(moving)
  .to_array()

///|
let stationary = @mecs.QueryFilter().without_component(
  _hint=(None : ReadmeVelocity?),
)

///|
let stationary_positions : Array[ReadmePosition] = world
  .query1_filtered(stationary)
  .to_array()
```

The `_hint` argument tells MoonBit which component type the generic filter
method should use. The filter checks the typed component conversion, so an id
collision with the wrong extensible-enum variant does not count as present.

Prefer command buffers for structural changes requested from systems. If direct
world mutation changes the same queried component slots inside an `eachN`
callback, the callback-owned values are written back after the callback, so that
writeback wins deterministically.

## Command Buffers

`World::commands` creates a deferred command buffer. Commands are recorded in
call order and become visible only when `World::apply_commands` runs. Applying a
buffer consumes it, so applying the same buffer again is a no-op.

Supported commands are `spawn`, `despawn`, `insert_component`,
`remove_component`, `set_resource`, and `remove_resource`. `Commands::spawn`
reserves and returns an `EntityId` immediately, but the entity is not alive until
the buffer is applied. This lets users queue inserts for the newly reserved
entity in the same buffer.

`World::apply_commands` applies commands in FIFO order. Duplicate inserts or
resource sets target the same storage slot, so the later command wins. Duplicate
despawns, component removals, and resource removals are no-ops after the first
successful removal. Inserting a component into an entity that is dead at the time
that command is applied raises `NotSpawned(entity)`.

Systems that need deferred structural mutation can be registered with
`CommandSystem` through `World::add_command_system` or
`World::add_command_system_fn`. During `World::step`, commands from a command
system are applied immediately after that system finishes and before the next
system runs. Direct world mutation APIs remain available for simple use cases.

## Scheduler

Systems are stored in a single-threaded deterministic scheduler. The built-in
stages are `Startup`, `Update`, `FixedUpdate`, and `Cleanup`. Existing
`add_system` and `add_command_system` calls register systems in `Update`.

`World::step` runs `Startup` once, then runs `Update` and `Cleanup` every call.
`World::fixed_step` runs `FixedUpdate` explicitly. `World::run_stage` can run
any stage directly.

Each system has a label derived from its system name. Use
`add_system_to_stage`, `add_system_fn_to_stage`,
`add_command_system_to_stage`, and `add_command_system_fn_to_stage` to choose a
stage, add `before` or `after` label constraints, or provide a `run_if`
condition. Run conditions receive `World`, so resources can drive scheduling
state.

Ordering is resolved inside each stage. `after` requires the referenced label to
run first when that label exists in the same stage. `before` makes the
referenced label wait for the current system. Unconstrained systems keep
registration order. Cycles fall back to registration order for the unresolved
systems, so execution remains deterministic.

`World::system_order` returns the resolved labels for a stage and is intended
for tests and debugging.
