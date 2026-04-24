
///|
struct ComponentStorage {
  map : Map[EntityId, ComponentRaw]
}

pub fn ComponentStorage::ComponentStorage() -> Self {
  ComponentStorage::{
    map: {}
  }
}

pub fn[C] ComponentStorage::set(self : Self, ent : EntityId, comp : C) -> Unit {
  save_any(self.map, ent, comp)
}

pub fn[C] ComponentStorage::get(self : Self, ent : EntityId) -> C {
  load_any(self.map, ent)
}


