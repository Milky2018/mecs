///|
pub fn[C] query1(store : ComponentStore[C]) -> Iter[C] {
  store.values()
}

///|
pub fn[C] query1_entities(store : ComponentStore[C]) -> Iter[(EntityId, C)] {
  store.iter_entities()
}

///|
pub fn[A, B] query2(
  a : ComponentStore[A],
  b : ComponentStore[B],
) -> Iter[(A, B)] {
  query2_entities(a, b).map(fn(row) {
    let (_, av, bv) = row
    (av, bv)
  })
}

///|
pub fn[A, B] query2_entities(
  a : ComponentStore[A],
  b : ComponentStore[B],
) -> Iter[(EntityId, A, B)] {
  let it = a.iter_entities()
  Iter::new(fn() -> (EntityId, A, B)? {
    for ;; {
      match it.next() {
        None => break None
        Some((entity, av)) =>
          match b.get(entity) {
            Some(bv) => break Some((entity, av, bv))
            None => continue
          }
      }
    }
  })
}

///|
pub fn[A, B, C] query3(
  a : ComponentStore[A],
  b : ComponentStore[B],
  c : ComponentStore[C],
) -> Iter[(A, B, C)] {
  query3_entities(a, b, c).map(fn(row) {
    let (_, av, bv, cv) = row
    (av, bv, cv)
  })
}

///|
pub fn[A, B, C] query3_entities(
  a : ComponentStore[A],
  b : ComponentStore[B],
  c : ComponentStore[C],
) -> Iter[(EntityId, A, B, C)] {
  let it = a.iter_entities()
  Iter::new(fn() -> (EntityId, A, B, C)? {
    for ;; {
      match it.next() {
        None => break None
        Some((entity, av)) =>
          match (b.get(entity), c.get(entity)) {
            (Some(bv), Some(cv)) => break Some((entity, av, bv, cv))
            _ => continue
          }
      }
    }
  })
}
