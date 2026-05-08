///|
pub struct ComponentId {
  name : String
} derive(Eq, Hash, Debug)

///|
pub fn ComponentId::ComponentId(name : String) -> Self {
  guard !name.is_empty() else { abort("component id cannot be empty") }
  { name, }
}

///|
pub fn ComponentId::name(self : Self) -> String {
  self.name
}

///|
pub fn component_id(name : String) -> ComponentId {
  ComponentId(name)
}

///|
pub struct ResourceId {
  name : String
} derive(Eq, Hash, Debug)

///|
pub fn ResourceId::ResourceId(name : String) -> Self {
  guard !name.is_empty() else { abort("resource id cannot be empty") }
  { name, }
}

///|
pub fn ResourceId::name(self : Self) -> String {
  self.name
}

///|
pub fn resource_id(name : String) -> ResourceId {
  ResourceId(name)
}

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
