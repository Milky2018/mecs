# Ergonomics Guide

This library keeps component and resource conversion explicit because the
extensible enum variant is the type-safe boundary. Boilerplate should follow a
small, mechanical shape.

## Component Template

For a component type named `Health`, the id must be the same text as the
`@mecs.Component` variant name:

```moonbit
///|
struct Health {
  value : Int
}

///|
extenum @mecs.Component += {
  Health(Health)
}

///|
impl @mecs.ComponentValue for Health with component_id() {
  @mecs.component_id("Health")
}

///|
impl @mecs.ComponentValue for Health with to_component(self) {
  Health(self)
}

///|
impl @mecs.ComponentValue for Health with from_component(component) {
  match component {
    Health(value) => Some(value)
    _ => None
  }
}
```

## Resource Template

For a resource type named `Frame`, the id must be the same text as the
`@mecs.Resource` variant name:

```moonbit
///|
struct Frame {
  value : Int
}

///|
extenum @mecs.Resource += {
  Frame(Frame)
}

///|
impl @mecs.ResourceValue for Frame with resource_id() {
  @mecs.resource_id("Frame")
}

///|
impl @mecs.ResourceValue for Frame with to_resource(self) {
  Frame(self)
}

///|
impl @mecs.ResourceValue for Frame with from_resource(resource) {
  match resource {
    Frame(value) => Some(value)
    _ => None
  }
}
```

## Code Generation Position

The runtime library does not generate `ComponentValue` or `ResourceValue`
implementations. The implementation is deliberately explicit because
`from_component` and `from_resource` validate that the stored extensible enum
variant matches the requested user type.

The repetitive part is mechanical: the type name, extensible enum variant, id
string, and match arm should all use the same name. A future external generator
or editor snippet can safely emit this template, but the checked source should
still contain the explicit conversion code.

## Common Patterns

Use `World::spawn_with` for initial component bundles:

```moonbit
let entity = world.spawn_with((Position::{ x: 0, y: 0 }, Velocity::{ x: 1, y: 0 }))
```

Use `World::queryN_entities` when the system needs entity ids:

```moonbit
let rows : Array[(@mecs.EntityId, (Velocity, Position))] = world
  .query2_entities()
  .to_array()
```

Use checked APIs when absence is expected:

```moonbit
let result = try? (world.get_component_checked(entity) : Position)
```
