///|
pub(open) trait Resource: HasTypeId {}

///|
type ResourceId = String

///|
type ResourceRaw = Any

///|
struct ResourceStorage {
  map : Map[ResourceId, ResourceRaw]
}

///|
pub fn ResourceStorage::ResourceStorage() -> Self {
  { map: {} }
}

///|
pub fn[R : Resource] ResourceStorage::set(self : Self, r : R) -> Unit {
  self.map[R::type_id()] = unsafe_to_any(r)
}

///|
pub fn[R : Resource] ResourceStorage::get(self : Self) -> R {
  self.map[R::type_id()] |> unsafe_from_any
}
