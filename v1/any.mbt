///|
type Any

///|
fn[A, B] coe(a : A) -> B = "%identity"

///|
pub fn[A] unsafe_to_any(a : A) -> Any {
  coe(Ref::new(a))
}

///|
pub fn[A] unsafe_from_any(a : Any) -> A {
  let r : Ref[A] = coe(a)
  r.val
}

pub fn[A] any_to_string(x : A) -> String = "%any.to_string"
