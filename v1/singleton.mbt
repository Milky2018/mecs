///|
pub(open) trait HasTypeId {
  type_id() -> String = _
}

///|
impl HasTypeId with type_id() {
  let f : () -> Self = coe(0)
  let s = any_to_string(f)
  guard s is [.. "<obj:() -> ", .. type_name, '>']
  type_name.to_string()
}
