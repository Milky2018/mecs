///|
struct Query1[A] {
  iter : () -> A?
}

///|
pub fn[A] Query1::Query1(iter : () -> A?) -> Query1[A] {
  Query1::{ iter, }
}

///|
pub fn[A] Query1::iter() -> Iter[A] {
  Iter::new(self.iter)
}

///|
struct Query2[A, B] {}
