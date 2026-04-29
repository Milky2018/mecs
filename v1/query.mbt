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
  let it = storage_a.iter2()

  Iter::new(fn() -> (A, B)? {
    for ;; {
      match it.next() {
        None => break None
        Some((entity, a)) =>
          match storage_b.get(entity) {
            Some(b) => break Some((a, b))
            None => continue
          }
      }
    }
  })
}
