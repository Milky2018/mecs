# Milky2018/mecs

`mecs` uses extensible enums for type-safe component and resource storage. It
does not use compiler primitives or C FFI.

Users extend `@mecs.Component` and `@mecs.Resource`, then implement the small
conversion traits for each concrete type.

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
  "Position"
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
