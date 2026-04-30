///|
pub type ComponentId = String

///|
pub type ResourceId = String

///|
pub(open) trait HasTypeId {
  type_id() -> String
}

///|
pub(open) trait Component: HasTypeId {}

///|
pub(open) trait Resource: HasTypeId {}
