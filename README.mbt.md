# Milky2018/mecs

`mecs` uses extensible enums for type-safe component and resource storage. It
does not use compiler primitives or C FFI.

Users extend `@mecs.Component` and `@mecs.Resource`, then implement the small
conversion traits for each concrete type.

`component_id` and `resource_id` return opaque ids, not raw strings. The id
must be exactly the same text as the extensible enum variant constructor name.
The id chooses the storage slot; `to_component` writes the extensible enum value
into that slot; `from_component` verifies that the stored enum variant really
belongs to the requested type. If an id collision stores a different variant in
the same slot, typed reads return `None`.

```mbt nocheck
///|
struct Position {
  mut x : Int
  mut y : Int
}

///|
extenum @mecs.Component += {
  Position(Position)
}

///|
impl @mecs.ComponentValue for Position with component_id() {
  @mecs.ComponentId::ComponentId("Position")
}

///|
impl @mecs.ComponentValue for Position with to_component(self) {
  Position(self)
}

///|
impl @mecs.ComponentValue for Position with from_component(component) {
  match component {
    Position(value) => Some(value)
    _ => None
  }
}
```
