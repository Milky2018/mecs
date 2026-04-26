///|
pub type ComponentId = String

///| 
/// Component can be normal `struct`s, `enum`s, `extenum`s.
/// WARNING: Component cannot be basic types like `Int`, 
/// `Bool`, `Double`
pub(open) trait Component {
  component_id() -> ComponentId
}

///|
type ComponentRaw = Any
