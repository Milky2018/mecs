///|
struct Resource[T] {
  mut value : T?
}

///|
pub fn[T] Resource::Resource() -> Resource[T] {
  { value: None }
}

///|
pub fn[T] resource() -> Resource[T] {
  Resource::Resource()
}

///|
pub fn[T] Resource::set(self : Resource[T], value : T) -> Unit {
  self.value = Some(value)
}

///|
pub fn[T] Resource::try_get(self : Resource[T]) -> T? {
  self.value
}

///|
pub fn[T] Resource::get(self : Resource[T]) -> T {
  match self.value {
    Some(value) => value
    None => abort("resource is not set")
  }
}

///|
pub fn[T] Resource::clear(self : Resource[T]) -> Unit {
  self.value = None
}

///|
pub fn[T] Resource::is_set(self : Resource[T]) -> Bool {
  self.value is Some(_)
}
