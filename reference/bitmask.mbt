///|
/// The complete component identity of an archetype.
struct Bitmask(UInt64)

///|
fn Bitmask::single(component : Int) -> Bitmask {
  Bitmask(1UL << component)
}

///|
fn Bitmask::value(self : Bitmask) -> UInt64 {
  self.0
}

///|
fn Bitmask::overlaps(self : Bitmask, other : Bitmask) -> Bool {
  (self.0 & other.0) != 0UL
}

///|
fn Bitmask::union(self : Bitmask, other : Bitmask) -> Bitmask {
  Bitmask(self.0 | other.0)
}

///|
fn Bitmask::contains(self : Bitmask, component : Int) -> Bool {
  (self.0 & (1UL << component)) != 0UL
}
