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
`@mecs.ResourceId::ResourceId("VariantName")`; the checked example below uses
MoonBit's shorter constructor syntax where the return type is already known.

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
  ComponentId("ReadmePosition")
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
  ComponentId("ReadmeVelocity")
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
  ResourceId("ReadmeFrame")
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
  world.each2(fn(velocity : ReadmeVelocity, position : ReadmePosition) -> Unit {
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
  world.step()
  let position : ReadmePosition = world.require_component(entity)
  inspect((position.x, position.y), content="(2, 3)")
  inspect((world.get_resource() : ReadmeFrame).value, content="1")
}
```

## Id Invariant

The id chooses the storage slot. `to_component` and `to_resource` write the
extensible enum value into that slot. `from_component` and `from_resource`
verify that the stored enum variant really belongs to the requested type. If two
types intentionally or accidentally use the same id, the newer value overwrites
the same slot, and typed reads for the other variant return `None`.

## Insert Failures

`World::insert_component` and `EntityOps::insert_component` return `Unit`. If
the target entity has not been spawned or has already been despawned, they raise
`NotSpawned(entity)`.
