///|
type Any

///|
fn[A, B] coe(a : A) -> B = "%identity"

///|
pub fn[A] unsafe_to_any(a : A) -> Any {
  coe(a)
}

///|
pub fn[A] unsafe_from_any(a : Any) -> A {
  coe(a)
}

