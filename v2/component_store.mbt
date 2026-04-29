///|
struct ComponentStore[C] {
  map : Map[EntityId, C]
}

///|
pub fn[C] ComponentStore::ComponentStore() -> ComponentStore[C] {
  { map: {} }
}

///|
pub fn[C] component_store() -> ComponentStore[C] {
  ComponentStore::ComponentStore()
}

///|
pub fn[C] ComponentStore::insert(
  self : ComponentStore[C],
  entity : EntityId,
  component : C,
) -> Unit {
  self.map[entity] = component
}

///|
pub fn[C] ComponentStore::get(
  self : ComponentStore[C],
  entity : EntityId,
) -> C? {
  self.map.get(entity)
}

///|
pub fn[C] ComponentStore::require(
  self : ComponentStore[C],
  entity : EntityId,
) -> C {
  match self.get(entity) {
    Some(component) => component
    None => abort("component is not present on entity \{entity}")
  }
}

///|
pub fn[C] ComponentStore::remove(
  self : ComponentStore[C],
  entity : EntityId,
) -> Unit {
  self.map.remove(entity)
}

///|
pub fn[C] ComponentStore::contains(
  self : ComponentStore[C],
  entity : EntityId,
) -> Bool {
  self.map.contains(entity)
}

///|
pub fn[C] ComponentStore::clear(self : ComponentStore[C]) -> Unit {
  self.map.clear()
}

///|
pub fn[C] ComponentStore::length(self : ComponentStore[C]) -> Int {
  self.map.length()
}

///|
pub fn[C] ComponentStore::is_empty(self : ComponentStore[C]) -> Bool {
  self.map.is_empty()
}

///|
pub fn[C] ComponentStore::values(self : ComponentStore[C]) -> Iter[C] {
  self.map.values()
}

///|
pub fn[C] ComponentStore::iter_entities(
  self : ComponentStore[C],
) -> Iter[(EntityId, C)] {
  self.map.iter()
}
