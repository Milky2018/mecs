///|
pub(open) trait Bundle {
  insert_into(Self, World, EntityId) -> Unit
}

///|
pub impl[A : ComponentValue, B : ComponentValue] Bundle for (A, B) with insert_into(
  bundle : (A, B),
  world : World,
  entity : EntityId,
) {
  let (a, b) = bundle
  try! world.insert_component(entity, a)
  try! world.insert_component(entity, b)
}

///|
pub impl[A : ComponentValue, B : ComponentValue, C : ComponentValue] Bundle for (
  A,
  B,
  C,
) with insert_into(bundle : (A, B, C), world : World, entity : EntityId) {
  let (a, b, c) = bundle
  try! world.insert_component(entity, a)
  try! world.insert_component(entity, b)
  try! world.insert_component(entity, c)
}

///|
pub impl[
  A : ComponentValue,
  B : ComponentValue,
  C : ComponentValue,
  D : ComponentValue,
] Bundle for (A, B, C, D) with insert_into(
  bundle : (A, B, C, D),
  world : World,
  entity : EntityId,
) {
  let (a, b, c, d) = bundle
  try! world.insert_component(entity, a)
  try! world.insert_component(entity, b)
  try! world.insert_component(entity, c)
  try! world.insert_component(entity, d)
}
