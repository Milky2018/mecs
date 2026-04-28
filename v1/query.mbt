///|
pub(open) trait Querable {
  iter(world : World) -> Iter[Self]
}

///|
pub impl[A : Component, B : Component] Querable for (A, B) with iter(
  world : World,
) {
  let storage_a = world.component_storages[A::type_id()]
  let storage_b = world.component_storages[B::type_id()]
  storage_a.values().zip(storage_b.values())
}
