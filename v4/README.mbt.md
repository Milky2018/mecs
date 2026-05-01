ECS v4

`v4` uses extensible enums for type-safe component and resource storage. It does
not use compiler primitives such as `%identity`, and it does not use C FFI.

Users extend `@v4.Component` and `@v4.Resource`, then implement the small
conversion traits for each concrete type.

```mbt nocheck
///|
struct Position {
  mut x : Int
  mut y : Int
}

///|
extenum @v4.Component += {
  Position(Position)
}

///|
impl @v4.ComponentValue for Position with component_id() {
  "Position"
}

///|
impl @v4.ComponentValue for Position with to_component(self) {
  @v4.Component::Position(self)
}

///|
impl @v4.ComponentValue for Position with from_component(component) {
  match component {
    Position(value) => Some(value)
    _ => None
  }
}
```
