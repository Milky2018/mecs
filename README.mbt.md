# Milky2018/mecs 

Define your normal components which will be stored in Archetypes:

```mbt check
///|
#valtype
priv struct Pos {
  x : Double
  y : Double
}

///|
#valtype
priv struct Vel {
  x : Double
  y : Double
}

///|
test {
  let position = Pos::{ x: 1.0, y: 2.0, }
  let velocity = Vel::{ x: 3.0, y: 4.0, }
  assert_eq(position.x + velocity.x, 4.0)
  assert_eq(position.y + velocity.y, 6.0)
}
```
