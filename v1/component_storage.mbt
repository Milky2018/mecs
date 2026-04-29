///|
/// TODO: Sparse set 
struct ComponentStorage {
  map : Map[EntityId, ComponentRaw]
}

///|
pub fn ComponentStorage::ComponentStorage() -> Self {
  ComponentStorage::{ map: {} }
}

///|
pub fn[C] ComponentStorage::set(self : Self, ent : EntityId, comp : C) -> Unit {
  self.map[ent] = unsafe_to_any(comp)
}

///|
pub fn[C] ComponentStorage::get(self : Self, ent : EntityId) -> C {
  self.map[ent] |> unsafe_from_any
}

///|
pub fn[C] ComponentStorage::values(self : Self) -> Iter[C] {
  self.map.values().map(unsafe_from_any)
}

///|
pub fn[C] ComponentStorage::iter2(self : Self) -> Iter2[EntityId, C] {
  self.map.map(fn(_k, v) { coe(v) }).iter2()
}
