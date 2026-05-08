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
pub impl[
  A : ComponentValue,
  B : ComponentValue,
  C : ComponentValue,
  D : ComponentValue,
] Query for (A, B, C, D) with iter(world : World) {
  world.query4()
}

///|
pub impl[
  A : ComponentValue,
  B : ComponentValue,
  C : ComponentValue,
  D : ComponentValue,
  E : ComponentValue,
] Query for (A, B, C, D, E) with iter(world : World) {
  world.query5()
}

///|
pub fn[Q : Query] World::query(self : World) -> Iter[Q] {
  Q::iter(self)
}

///|
fn[C : ComponentValue] World::query1_entities_from_store(
  self : World,
  id : ComponentId,
) -> Iter2[EntityId, C] {
  match self.component_store(id) {
    Some(store) => {
      let it = store.iter()
      Iter2::new(fn() -> (EntityId, C)? {
        for ;; {
          let row = match it.next() {
            Some(row) => row
            None => break None
          }
          let (entity, component) = row
          match C::from_component(component) {
            Some(value) => break Some((entity, value))
            None => continue
          }
        }
      })
    }
    None => Iter2::new(fn() -> (EntityId, C)? { None })
  }
}

///|
fn[C : ComponentValue] component_from_store(
  store : @hashmap.HashMap[EntityId, Component]?,
  entity : EntityId,
) -> C? {
  match store {
    Some(store) =>
      match store.get(entity) {
        Some(component) => C::from_component(component)
        None => None
      }
    None => None
  }
}

///|
pub fn[C : ComponentValue] World::query1(self : World) -> Iter[C] {
  match self.component_store(C::component_id()) {
    Some(store) => {
      let it = store.iter()
      Iter::new(fn() -> C? {
        for ;; {
          let row = match it.next() {
            Some(row) => row
            None => break None
          }
          let (_entity, component) = row
          match C::from_component(component) {
            Some(value) => break Some(value)
            None => continue
          }
        }
      })
    }
    None => Iter::new(fn() -> C? { None })
  }
}

///|
pub fn[C : ComponentValue] World::query1_entities(
  self : World,
) -> Iter2[EntityId, C] {
  self.query1_entities_from_store(C::component_id())
}

///|
pub fn[A : ComponentValue, B : ComponentValue] World::query2(
  self : World,
) -> Iter[(A, B)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  if self.component_store_len(a_id) <= self.component_store_len(b_id) {
    match self.component_store(a_id) {
      Some(a_store) => {
        let it = a_store.iter()
        let b_store = self.component_store(b_id)
        Iter::new(fn() -> (A, B)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                A::from_component(component),
                component_from_store(b_store, entity),
              ) {
              (Some(a), Some(b)) => break Some((a, b))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B)? { None })
    }
  } else {
    match self.component_store(b_id) {
      Some(b_store) => {
        let it = b_store.iter()
        let a_store = self.component_store(a_id)
        Iter::new(fn() -> (A, B)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                B::from_component(component),
              ) {
              (Some(a), Some(b)) => break Some((a, b))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B)? { None })
    }
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue] World::query2_entities(
  self : World,
) -> Iter2[EntityId, (A, B)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  if self.component_store_len(a_id) <= self.component_store_len(b_id) {
    let it = self.query1_entities_from_store(a_id)
    let b_store = self.component_store(b_id)
    Iter2::new(fn() -> (EntityId, (A, B))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, a)) =>
            match component_from_store(b_store, entity) {
              Some(b) => break Some((entity, (a, b)))
              None => continue
            }
        }
      }
    })
  } else {
    let it = self.query1_entities_from_store(b_id)
    let a_store = self.component_store(a_id)
    Iter2::new(fn() -> (EntityId, (A, B))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, b)) =>
            match component_from_store(a_store, entity) {
              Some(a) => break Some((entity, (a, b)))
              None => continue
            }
        }
      }
    })
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue, C : ComponentValue] World::query3(
  self : World,
) -> Iter[(A, B, C)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  let c_id = C::component_id()
  let a_len = self.component_store_len(a_id)
  let b_len = self.component_store_len(b_id)
  let c_len = self.component_store_len(c_id)
  if a_len <= b_len && a_len <= c_len {
    match self.component_store(a_id) {
      Some(a_store) => {
        let it = a_store.iter()
        let b_store = self.component_store(b_id)
        let c_store = self.component_store(c_id)
        Iter::new(fn() -> (A, B, C)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                A::from_component(component),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
              ) {
              (Some(a), Some(b), Some(c)) => break Some((a, b, c))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C)? { None })
    }
  } else if b_len <= c_len {
    match self.component_store(b_id) {
      Some(b_store) => {
        let it = b_store.iter()
        let a_store = self.component_store(a_id)
        let c_store = self.component_store(c_id)
        Iter::new(fn() -> (A, B, C)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                B::from_component(component),
                component_from_store(c_store, entity),
              ) {
              (Some(a), Some(b), Some(c)) => break Some((a, b, c))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C)? { None })
    }
  } else {
    match self.component_store(c_id) {
      Some(c_store) => {
        let it = c_store.iter()
        let a_store = self.component_store(a_id)
        let b_store = self.component_store(b_id)
        Iter::new(fn() -> (A, B, C)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                C::from_component(component),
              ) {
              (Some(a), Some(b), Some(c)) => break Some((a, b, c))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C)? { None })
    }
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue, C : ComponentValue] World::query3_entities(
  self : World,
) -> Iter2[EntityId, (A, B, C)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  let c_id = C::component_id()
  let a_len = self.component_store_len(a_id)
  let b_len = self.component_store_len(b_id)
  let c_len = self.component_store_len(c_id)
  if a_len <= b_len && a_len <= c_len {
    let it = self.query1_entities_from_store(a_id)
    let b_store = self.component_store(b_id)
    let c_store = self.component_store(c_id)
    Iter2::new(fn() -> (EntityId, (A, B, C))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, a)) =>
            match
              (
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
              ) {
              (Some(b), Some(c)) => break Some((entity, (a, b, c)))
              _ => continue
            }
        }
      }
    })
  } else if b_len <= c_len {
    let it = self.query1_entities_from_store(b_id)
    let a_store = self.component_store(a_id)
    let c_store = self.component_store(c_id)
    Iter2::new(fn() -> (EntityId, (A, B, C))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, b)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(c_store, entity),
              ) {
              (Some(a), Some(c)) => break Some((entity, (a, b, c)))
              _ => continue
            }
        }
      }
    })
  } else {
    let it = self.query1_entities_from_store(c_id)
    let a_store = self.component_store(a_id)
    let b_store = self.component_store(b_id)
    Iter2::new(fn() -> (EntityId, (A, B, C))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, c)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
              ) {
              (Some(a), Some(b)) => break Some((entity, (a, b, c)))
              _ => continue
            }
        }
      }
    })
  }
}

///|
pub fn[
  A : ComponentValue,
  B : ComponentValue,
  C : ComponentValue,
  D : ComponentValue,
] World::query4(
  self : World,
) -> Iter[(A, B, C, D)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  let c_id = C::component_id()
  let d_id = D::component_id()
  let a_len = self.component_store_len(a_id)
  let b_len = self.component_store_len(b_id)
  let c_len = self.component_store_len(c_id)
  let d_len = self.component_store_len(d_id)
  if a_len <= b_len && a_len <= c_len && a_len <= d_len {
    match self.component_store(a_id) {
      Some(a_store) => {
        let it = a_store.iter()
        let b_store = self.component_store(b_id)
        let c_store = self.component_store(c_id)
        let d_store = self.component_store(d_id)
        Iter::new(fn() -> (A, B, C, D)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                A::from_component(component),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d)) => break Some((a, b, c, d))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D)? { None })
    }
  } else if b_len <= c_len && b_len <= d_len {
    match self.component_store(b_id) {
      Some(b_store) => {
        let it = b_store.iter()
        let a_store = self.component_store(a_id)
        let c_store = self.component_store(c_id)
        let d_store = self.component_store(d_id)
        Iter::new(fn() -> (A, B, C, D)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                B::from_component(component),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d)) => break Some((a, b, c, d))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D)? { None })
    }
  } else if c_len <= d_len {
    match self.component_store(c_id) {
      Some(c_store) => {
        let it = c_store.iter()
        let a_store = self.component_store(a_id)
        let b_store = self.component_store(b_id)
        let d_store = self.component_store(d_id)
        Iter::new(fn() -> (A, B, C, D)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                C::from_component(component),
                component_from_store(d_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d)) => break Some((a, b, c, d))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D)? { None })
    }
  } else {
    match self.component_store(d_id) {
      Some(d_store) => {
        let it = d_store.iter()
        let a_store = self.component_store(a_id)
        let b_store = self.component_store(b_id)
        let c_store = self.component_store(c_id)
        Iter::new(fn() -> (A, B, C, D)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                D::from_component(component),
              ) {
              (Some(a), Some(b), Some(c), Some(d)) => break Some((a, b, c, d))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D)? { None })
    }
  }
}

///|
pub fn[
  A : ComponentValue,
  B : ComponentValue,
  C : ComponentValue,
  D : ComponentValue,
] World::query4_entities(
  self : World,
) -> Iter2[EntityId, (A, B, C, D)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  let c_id = C::component_id()
  let d_id = D::component_id()
  let a_len = self.component_store_len(a_id)
  let b_len = self.component_store_len(b_id)
  let c_len = self.component_store_len(c_id)
  let d_len = self.component_store_len(d_id)
  if a_len <= b_len && a_len <= c_len && a_len <= d_len {
    let it = self.query1_entities_from_store(a_id)
    let b_store = self.component_store(b_id)
    let c_store = self.component_store(c_id)
    let d_store = self.component_store(d_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, a)) =>
            match
              (
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
              ) {
              (Some(b), Some(c), Some(d)) => break Some((entity, (a, b, c, d)))
              _ => continue
            }
        }
      }
    })
  } else if b_len <= c_len && b_len <= d_len {
    let it = self.query1_entities_from_store(b_id)
    let a_store = self.component_store(a_id)
    let c_store = self.component_store(c_id)
    let d_store = self.component_store(d_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, b)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
              ) {
              (Some(a), Some(c), Some(d)) => break Some((entity, (a, b, c, d)))
              _ => continue
            }
        }
      }
    })
  } else if c_len <= d_len {
    let it = self.query1_entities_from_store(c_id)
    let a_store = self.component_store(a_id)
    let b_store = self.component_store(b_id)
    let d_store = self.component_store(d_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, c)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(d_store, entity),
              ) {
              (Some(a), Some(b), Some(d)) => break Some((entity, (a, b, c, d)))
              _ => continue
            }
        }
      }
    })
  } else {
    let it = self.query1_entities_from_store(d_id)
    let a_store = self.component_store(a_id)
    let b_store = self.component_store(b_id)
    let c_store = self.component_store(c_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, d)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
              ) {
              (Some(a), Some(b), Some(c)) => break Some((entity, (a, b, c, d)))
              _ => continue
            }
        }
      }
    })
  }
}

///|
pub fn[
  A : ComponentValue,
  B : ComponentValue,
  C : ComponentValue,
  D : ComponentValue,
  E : ComponentValue,
] World::query5(
  self : World,
) -> Iter[(A, B, C, D, E)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  let c_id = C::component_id()
  let d_id = D::component_id()
  let e_id = E::component_id()
  let a_len = self.component_store_len(a_id)
  let b_len = self.component_store_len(b_id)
  let c_len = self.component_store_len(c_id)
  let d_len = self.component_store_len(d_id)
  let e_len = self.component_store_len(e_id)
  if a_len <= b_len && a_len <= c_len && a_len <= d_len && a_len <= e_len {
    match self.component_store(a_id) {
      Some(a_store) => {
        let it = a_store.iter()
        let b_store = self.component_store(b_id)
        let c_store = self.component_store(c_id)
        let d_store = self.component_store(d_id)
        let e_store = self.component_store(e_id)
        Iter::new(fn() -> (A, B, C, D, E)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                A::from_component(component),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
                component_from_store(e_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d), Some(e)) =>
                break Some((a, b, c, d, e))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D, E)? { None })
    }
  } else if b_len <= c_len && b_len <= d_len && b_len <= e_len {
    match self.component_store(b_id) {
      Some(b_store) => {
        let it = b_store.iter()
        let a_store = self.component_store(a_id)
        let c_store = self.component_store(c_id)
        let d_store = self.component_store(d_id)
        let e_store = self.component_store(e_id)
        Iter::new(fn() -> (A, B, C, D, E)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                B::from_component(component),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
                component_from_store(e_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d), Some(e)) =>
                break Some((a, b, c, d, e))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D, E)? { None })
    }
  } else if c_len <= d_len && c_len <= e_len {
    match self.component_store(c_id) {
      Some(c_store) => {
        let it = c_store.iter()
        let a_store = self.component_store(a_id)
        let b_store = self.component_store(b_id)
        let d_store = self.component_store(d_id)
        let e_store = self.component_store(e_id)
        Iter::new(fn() -> (A, B, C, D, E)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                C::from_component(component),
                component_from_store(d_store, entity),
                component_from_store(e_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d), Some(e)) =>
                break Some((a, b, c, d, e))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D, E)? { None })
    }
  } else if d_len <= e_len {
    match self.component_store(d_id) {
      Some(d_store) => {
        let it = d_store.iter()
        let a_store = self.component_store(a_id)
        let b_store = self.component_store(b_id)
        let c_store = self.component_store(c_id)
        let e_store = self.component_store(e_id)
        Iter::new(fn() -> (A, B, C, D, E)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                D::from_component(component),
                component_from_store(e_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d), Some(e)) =>
                break Some((a, b, c, d, e))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D, E)? { None })
    }
  } else {
    match self.component_store(e_id) {
      Some(e_store) => {
        let it = e_store.iter()
        let a_store = self.component_store(a_id)
        let b_store = self.component_store(b_id)
        let c_store = self.component_store(c_id)
        let d_store = self.component_store(d_id)
        Iter::new(fn() -> (A, B, C, D, E)? {
          for ;; {
            let row = match it.next() {
              Some(row) => row
              None => break None
            }
            let (entity, component) = row
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
                E::from_component(component),
              ) {
              (Some(a), Some(b), Some(c), Some(d), Some(e)) =>
                break Some((a, b, c, d, e))
              _ => continue
            }
          }
        })
      }
      None => Iter::new(fn() -> (A, B, C, D, E)? { None })
    }
  }
}

///|
pub fn[
  A : ComponentValue,
  B : ComponentValue,
  C : ComponentValue,
  D : ComponentValue,
  E : ComponentValue,
] World::query5_entities(
  self : World,
) -> Iter2[EntityId, (A, B, C, D, E)] {
  let a_id = A::component_id()
  let b_id = B::component_id()
  let c_id = C::component_id()
  let d_id = D::component_id()
  let e_id = E::component_id()
  let a_len = self.component_store_len(a_id)
  let b_len = self.component_store_len(b_id)
  let c_len = self.component_store_len(c_id)
  let d_len = self.component_store_len(d_id)
  let e_len = self.component_store_len(e_id)
  if a_len <= b_len && a_len <= c_len && a_len <= d_len && a_len <= e_len {
    let it = self.query1_entities_from_store(a_id)
    let b_store = self.component_store(b_id)
    let c_store = self.component_store(c_id)
    let d_store = self.component_store(d_id)
    let e_store = self.component_store(e_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D, E))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, a)) =>
            match
              (
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
                component_from_store(e_store, entity),
              ) {
              (Some(b), Some(c), Some(d), Some(e)) =>
                break Some((entity, (a, b, c, d, e)))
              _ => continue
            }
        }
      }
    })
  } else if b_len <= c_len && b_len <= d_len && b_len <= e_len {
    let it = self.query1_entities_from_store(b_id)
    let a_store = self.component_store(a_id)
    let c_store = self.component_store(c_id)
    let d_store = self.component_store(d_id)
    let e_store = self.component_store(e_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D, E))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, b)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
                component_from_store(e_store, entity),
              ) {
              (Some(a), Some(c), Some(d), Some(e)) =>
                break Some((entity, (a, b, c, d, e)))
              _ => continue
            }
        }
      }
    })
  } else if c_len <= d_len && c_len <= e_len {
    let it = self.query1_entities_from_store(c_id)
    let a_store = self.component_store(a_id)
    let b_store = self.component_store(b_id)
    let d_store = self.component_store(d_id)
    let e_store = self.component_store(e_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D, E))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, c)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(d_store, entity),
                component_from_store(e_store, entity),
              ) {
              (Some(a), Some(b), Some(d), Some(e)) =>
                break Some((entity, (a, b, c, d, e)))
              _ => continue
            }
        }
      }
    })
  } else if d_len <= e_len {
    let it = self.query1_entities_from_store(d_id)
    let a_store = self.component_store(a_id)
    let b_store = self.component_store(b_id)
    let c_store = self.component_store(c_id)
    let e_store = self.component_store(e_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D, E))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, d)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                component_from_store(e_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(e)) =>
                break Some((entity, (a, b, c, d, e)))
              _ => continue
            }
        }
      }
    })
  } else {
    let it = self.query1_entities_from_store(e_id)
    let a_store = self.component_store(a_id)
    let b_store = self.component_store(b_id)
    let c_store = self.component_store(c_id)
    let d_store = self.component_store(d_id)
    Iter2::new(fn() -> (EntityId, (A, B, C, D, E))? {
      for ;; {
        match it.next() {
          None => break None
          Some((entity, e)) =>
            match
              (
                component_from_store(a_store, entity),
                component_from_store(b_store, entity),
                component_from_store(c_store, entity),
                component_from_store(d_store, entity),
              ) {
              (Some(a), Some(b), Some(c), Some(d)) =>
                break Some((entity, (a, b, c, d, e)))
              _ => continue
            }
        }
      }
    })
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue] World::for_each2(
  self : World,
  f : (A, B) -> Unit,
) -> Unit {
  let a_id = A::component_id()
  let b_id = B::component_id()
  if self.component_store_len(a_id) <= self.component_store_len(b_id) {
    match self.component_store(a_id) {
      Some(a_store) => {
        let b_store = self.component_store(b_id)
        a_store.each(fn(entity, component) {
          match
            (
              A::from_component(component),
              component_from_store(b_store, entity),
            ) {
            (Some(a), Some(b)) => f(a, b)
            _ => ()
          }
        })
      }
      None => ()
    }
  } else {
    match self.component_store(b_id) {
      Some(b_store) => {
        let a_store = self.component_store(a_id)
        b_store.each(fn(entity, component) {
          match
            (
              component_from_store(a_store, entity),
              B::from_component(component),
            ) {
            (Some(a), Some(b)) => f(a, b)
            _ => ()
          }
        })
      }
      None => ()
    }
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue, C : ComponentValue] World::for_each3(
  self : World,
  f : (A, B, C) -> Unit,
) -> Unit {
  let a_id = A::component_id()
  let b_id = B::component_id()
  let c_id = C::component_id()
  let a_len = self.component_store_len(a_id)
  let b_len = self.component_store_len(b_id)
  let c_len = self.component_store_len(c_id)
  if a_len <= b_len && a_len <= c_len {
    match self.component_store(a_id) {
      Some(a_store) => {
        let b_store = self.component_store(b_id)
        let c_store = self.component_store(c_id)
        a_store.each(fn(entity, component) {
          match
            (
              A::from_component(component),
              component_from_store(b_store, entity),
              component_from_store(c_store, entity),
            ) {
            (Some(a), Some(b), Some(c)) => f(a, b, c)
            _ => ()
          }
        })
      }
      None => ()
    }
  } else if b_len <= c_len {
    match self.component_store(b_id) {
      Some(b_store) => {
        let a_store = self.component_store(a_id)
        let c_store = self.component_store(c_id)
        b_store.each(fn(entity, component) {
          match
            (
              component_from_store(a_store, entity),
              B::from_component(component),
              component_from_store(c_store, entity),
            ) {
            (Some(a), Some(b), Some(c)) => f(a, b, c)
            _ => ()
          }
        })
      }
      None => ()
    }
  } else {
    match self.component_store(c_id) {
      Some(c_store) => {
        let a_store = self.component_store(a_id)
        let b_store = self.component_store(b_id)
        c_store.each(fn(entity, component) {
          match
            (
              component_from_store(a_store, entity),
              component_from_store(b_store, entity),
              C::from_component(component),
            ) {
            (Some(a), Some(b), Some(c)) => f(a, b, c)
            _ => ()
          }
        })
      }
      None => ()
    }
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue] World::each2(
  self : World,
  f : (A, B) -> Unit,
) -> Unit raise NotSpawned {
  let rows : Array[(EntityId, (A, B))] = self.query2_entities().to_array()
  for row in rows {
    let (entity, (a, b)) = row
    f(a, b)
    self.insert_component(entity, a)
    self.insert_component(entity, b)
  }
}

///|
pub fn[A : ComponentValue, B : ComponentValue, C : ComponentValue] World::each3(
  self : World,
  f : (A, B, C) -> Unit,
) -> Unit raise NotSpawned {
  let rows : Array[(EntityId, (A, B, C))] = self.query3_entities().to_array()
  for row in rows {
    let (entity, (a, b, c)) = row
    f(a, b, c)
    self.insert_component(entity, a)
    self.insert_component(entity, b)
    self.insert_component(entity, c)
  }
}
