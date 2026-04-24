///|
pub type ComponentId = String

///|
trait Component {
  debug_name() -> ComponentId
}

///|
type ComponentRaw = Any
