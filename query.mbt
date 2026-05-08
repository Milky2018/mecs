///|
pub(open) trait Query {
  iter(World) -> Iter[Self]
}

///|
pub impl[A : ComponentValue, B : ComponentValue] Query for (A, B) with iter(
  world : World,
) {
  world.query2()
}

///|
pub impl[A : ComponentValue, B : ComponentValue, C : ComponentValue] Query for (
  A,
  B,
  C,
) with iter(world : World) {
  world.query3()
}

///|
pub fn[Q : Query] World::query(self : World) -> Iter[Q] {
  Q::iter(self)
}

///|
pub fn[C : ComponentValue] World::query1(self : World) -> Iter[C] {
  self
  .query1_entities()
  .iter()
  .map(fn(row) {
    let (_entity, component) = row
    component
  })
}

///|
pub fn[C : ComponentValue] World::query1_entities(
  self : World,
) -> Iter2[EntityId, C] {
  let it = self.components.iter()
  Iter2::new(fn() -> (EntityId, C)? {
    for ;; {
      let row = match it.next() {
        Some(row) => row
        None => break None
      }
      let (entity, map) = row
      match map.get(C::component_id()) {
        Some(component) =>
          match C::from_component(component) {
            Some(value) => break Some((entity, value))
            None => continue
          }
        None => continue
      }
    }
  })
}

///|
pub fn[A : ComponentValue, B : ComponentValue] World::query2(
  self : World,
) -> Iter[(A, B)] {
  self
  .query2_entities()
  .iter()
  .map(fn(row) {
    let (_entity, components) = row
    components
  })
}

///|
pub fn[A : ComponentValue, B : ComponentValue] World::query2_entities(
  self : World,
) -> Iter2[EntityId, (A, B)] {
  let it = self.query1_entities()
  Iter2::new(fn() -> (EntityId, (A, B))? {
    for ;; {
      match it.next() {
        None => break None
        Some((entity, a)) =>
          match self.get_component(entity) {
            Some(b) => break Some((entity, (a, b)))
            None => continue
          }
      }
    }
  })
}

///|
pub fn[A : ComponentValue, B : ComponentValue, C : ComponentValue] World::query3(
  self : World,
) -> Iter[(A, B, C)] {
  self
  .query3_entities()
  .iter()
  .map(fn(row) {
    let (_entity, components) = row
    components
  })
}

///|
pub fn[A : ComponentValue, B : ComponentValue, C : ComponentValue] World::query3_entities(
  self : World,
) -> Iter2[EntityId, (A, B, C)] {
  let it = self.query1_entities()
  Iter2::new(fn() -> (EntityId, (A, B, C))? {
    for ;; {
      match it.next() {
        None => break None
        Some((entity, a)) =>
          match (self.get_component(entity), self.get_component(entity)) {
            (Some(b), Some(c)) => break Some((entity, (a, b, c)))
            _ => continue
          }
      }
    }
  })
}

///|
pub fn[A : ComponentValue, B : ComponentValue] World::each2(
  self : World,
  f : (A, B) -> Unit,
) -> Unit {
  let rows : Array[(EntityId, (A, B))] = self.query2_entities().to_array()
  for row in rows {
    let (entity, (a, b)) = row
    f(a, b)
    try! self.insert_component(entity, a)
    try! self.insert_component(entity, b)
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue, C : ComponentValue] World::each3(
  self : World,
  f : (A, B, C) -> Unit,
) -> Unit {
  let rows : Array[(EntityId, (A, B, C))] = self.query3_entities().to_array()
  for row in rows {
    let (entity, (a, b, c)) = row
    f(a, b, c)
    try! self.insert_component(entity, a)
    try! self.insert_component(entity, b)
    try! self.insert_component(entity, c)
  }
}
