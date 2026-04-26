///|
pub type ComponentId = String

///| 
/// Component can be normal `struct`, `enum`, `extenum`.
/// WARNING: Component cannot be basic types like `Int`, 
/// `Bool`, `Double`, `String`, cannot be `suberror`, 
/// cannot be function types, cannot be `valtype`.
pub(open) trait Component {
  component_id() -> ComponentId
}

///|
type ComponentRaw = Any
