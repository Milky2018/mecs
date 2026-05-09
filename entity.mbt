///|
struct EntityId {
  value : UInt
} derive(Eq, Hash, Debug)

///|
fn EntityId::EntityId(value : UInt) -> Self {
  { value, }
}

///|
pub fn EntityId::value(self : Self) -> UInt {
  self.value
}
