///|
priv type AnyRef

///|
fn[A, B] coerce(value : A) -> B = "%identity"

///|
fn[T] ref_to_any(value : Ref[T]) -> AnyRef {
  coerce(value)
}

///|
fn[T] any_to_ref(value : AnyRef, _hint? : T? = None) -> Ref[T] {
  coerce(value)
}
