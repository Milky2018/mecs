///|
priv struct ComponentFilter {
  id : ComponentId
  matches : (Component) -> Bool
}

///|
struct QueryFilter {
  required : Array[ComponentFilter]
  forbidden : Array[ComponentFilter]
}

///|
pub fn QueryFilter::QueryFilter() -> Self {
  { required: [], forbidden: [] }
}

///|
pub fn[C : ComponentValue] QueryFilter::with_component(
  self : Self,
  _hint? : C? = None,
) -> Self {
  let required = self.required.copy()
  required.push({
    id: C::component_id(),
    matches: fn(component) { C::from_component(component) is Some(_) },
  })
  { required, forbidden: self.forbidden.copy() }
}

///|
pub fn[C : ComponentValue] QueryFilter::without_component(
  self : Self,
  _hint? : C? = None,
) -> Self {
  let forbidden = self.forbidden.copy()
  forbidden.push({
    id: C::component_id(),
    matches: fn(component) { C::from_component(component) is Some(_) },
  })
  { required: self.required.copy(), forbidden }
}

///|
pub fn QueryFilter::is_empty(self : Self) -> Bool {
  self.required.length() == 0 && self.forbidden.length() == 0
}

///|
fn World::entity_matches_filter(
  self : World,
  entity : EntityId,
  filter : QueryFilter,
) -> Bool {
  guard !filter.is_empty() else { return true }
  for required in filter.required {
    match self.component_store(required.id) {
      Some(store) =>
        match store.get(entity) {
          Some(component) => if !(required.matches)(component) { return false }
          None => return false
        }
      None => return false
    }
  }
  for forbidden in filter.forbidden {
    match self.component_store(forbidden.id) {
      Some(store) =>
        match store.get(entity) {
          Some(component) => if (forbidden.matches)(component) { return false }
          None => ()
        }
      None => ()
    }
  }
  true
}

///|
fn World::entity_matches_filter_with_driver(
  self : World,
  entity : EntityId,
  filter : QueryFilter,
  driver_id : ComponentId,
  driver_component : Component,
) -> Bool {
  guard !filter.is_empty() else { return true }
  for required in filter.required {
    if required.id == driver_id {
      if !(required.matches)(driver_component) {
        return false
      }
    } else {
      match self.component_store(required.id) {
        Some(store) =>
          match store.get(entity) {
            Some(component) =>
              if !(required.matches)(component) {
                return false
              }
            None => return false
          }
        None => return false
      }
    }
  }
  for forbidden in filter.forbidden {
    if forbidden.id == driver_id {
      if (forbidden.matches)(driver_component) {
        return false
      }
    } else {
      match self.component_store(forbidden.id) {
        Some(store) =>
          match store.get(entity) {
            Some(component) =>
              if (forbidden.matches)(component) {
                return false
              }
            None => ()
          }
        None => ()
      }
    }
  }
  true
}

///|
fn QueryFilter::shortest_required_id(
  self : Self,
  world : World,
  current_id : ComponentId,
  current_len : Int,
) -> ComponentId {
  let mut selected_id = current_id
  let mut selected_len = current_len
  for required in self.required {
    let required_len = world.component_store_len(required.id)
    if required_len < selected_len {
      selected_id = required.id
      selected_len = required_len
    }
  }
  selected_id
}

///|
fn[V] World::filter_entity_rows(
  self : World,
  rows : Iter2[EntityId, V],
  filter : QueryFilter,
) -> Iter2[EntityId, V] {
  if filter.is_empty() {
    rows
  } else {
    Iter2::new(fn() -> (EntityId, V)? {
      for ;; {
        match rows.next() {
          None => break None
          Some((entity, value)) =>
            if self.entity_matches_filter(entity, filter) {
              break Some((entity, value))
            } else {
              continue
            }
        }
      }
    })
  }
}

///|
fn[V] values_from_entity_rows(rows : Iter2[EntityId, V]) -> Iter[V] {
  rows
  .iter()
  .map(fn(row) {
    let (_entity, value) = row
    value
  })
}
