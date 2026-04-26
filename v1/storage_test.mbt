///|
test "component storage get/set" {
  let store = @v1.ComponentStorage()
  store.set(1, "Hello")
  store.set(2, true)
  store.set(3, Point::{ x: 1, y: 2 })

  let s : String = store.get(1)
  inspect(
    s,
    content=(
      #|Hello
    ),
  )
  let b : Bool = store.get(2)
  inspect(
    b,
    content=(
      #|true
    ),
  )
  let p : Point = store.get(3)
  debug_inspect(
    p,
    content=(
      #|{ x: 1, y: 2 }
    ),
  )
}
