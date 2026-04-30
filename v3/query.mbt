///|
pub(open) trait Query {
  iter(World) -> Iter[Self]
}

///|
pub impl[A : Component, B : Component] Query for (A, B) with iter(world : World) {
  world.query2()
}

///|
pub impl[A : Component, B : Component, C : Component] Query for (A, B, C) with iter(
  world : World,
) {
  world.query3()
}

///|
pub fn[Q : Query] World::query(self : World) -> Iter[Q] {
  Q::iter(self)
}

///|
pub fn[C : Component] World::query1(self : World) -> Iter[C] {
  self
  .query1_entities()
  .map(fn(row) {
    let (_entity, component) = row
    component
  })
}

///|
pub fn[C : Component] World::query1_entities(
  self : World,
) -> Iter[(EntityId, C)] {
  let type_id = C::type_id()
  let mut index = 0
  Iter::new(fn() -> (EntityId, C)? {
    for ;; {
      let count = raw_world_component_count(self.raw, type_id)
      guard index < count else { break None }
      let entity = raw_world_component_entity_at(self.raw, type_id, index)
      index += 1
      if self.is_alive(entity) &&
        raw_world_has_component(self.raw, type_id, entity) {
        let component = any_to_ref(
            raw_world_get_component(self.raw, type_id, entity),
          ).val
        break Some((entity, component))
      }
    }
  })
}

///|
pub fn[A : Component, B : Component] World::query2(
  self : World,
) -> Iter[(A, B)] {
  self
  .query2_entities()
  .map(fn(row) {
    let (_entity, a, b) = row
    (a, b)
  })
}

///|
pub fn[A : Component, B : Component] World::query2_entities(
  self : World,
) -> Iter[(EntityId, A, B)] {
  let it = self.query1_entities()
  Iter::new(fn() -> (EntityId, A, B)? {
    for ;; {
      match it.next() {
        None => break None
        Some((entity, a)) =>
          match self.get_component(entity) {
            Some(b) => break Some((entity, a, b))
            None => continue
          }
      }
    }
  })
}

///|
pub fn[A : Component, B : Component, C : Component] World::query3(
  self : World,
) -> Iter[(A, B, C)] {
  self
  .query3_entities()
  .map(fn(row) {
    let (_entity, a, b, c) = row
    (a, b, c)
  })
}

///|
pub fn[A : Component, B : Component, C : Component] World::query3_entities(
  self : World,
) -> Iter[(EntityId, A, B, C)] {
  let it = self.query1_entities()
  Iter::new(fn() -> (EntityId, A, B, C)? {
    for ;; {
      match it.next() {
        None => break None
        Some((entity, a)) =>
          match (self.get_component(entity), self.get_component(entity)) {
            (Some(b), Some(c)) => break Some((entity, a, b, c))
            _ => continue
          }
      }
    }
  })
}

///|
pub fn[A : Component, B : Component] World::each2(
  self : World,
  f : (A, B) -> Unit,
) -> Unit {
  let rows : Array[(EntityId, A, B)] = self.query2_entities().to_array()
  for row in rows {
    let (entity, a, b) = row
    f(a, b)
    ignore(self.insert_component(entity, a))
    ignore(self.insert_component(entity, b))
  }
}

///|
pub fn[A : Component, B : Component, C : Component] World::each3(
  self : World,
  f : (A, B, C) -> Unit,
) -> Unit {
  let rows : Array[(EntityId, A, B, C)] = self.query3_entities().to_array()
  for row in rows {
    let (entity, a, b, c) = row
    f(a, b, c)
    ignore(self.insert_component(entity, a))
    ignore(self.insert_component(entity, b))
    ignore(self.insert_component(entity, c))
  }
}
