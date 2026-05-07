///|
pub type ComponentId = String

///|
pub type ResourceId = String

///|
pub extenum Component {}

///|
pub extenum Resource {}

///|
pub(open) trait ComponentValue {
  component_id() -> ComponentId
  to_component(Self) -> Component
  from_component(Component) -> Self?
}

///|
pub(open) trait ResourceValue {
  resource_id() -> ResourceId
  to_resource(Self) -> Resource
  from_resource(Resource) -> Self?
}
