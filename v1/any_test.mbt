///|
priv struct Point {
  x : Int
  y : Int
} derive(Debug)

///|
test "unsafe to/from any for structs" {
  let x = Point::{ x: 10, y: 20 }
  let y = unsafe_to_any(x)
  let z : Point = unsafe_from_any(y)
  debug_inspect(
    z,
    content=(
      #|{ x: 10, y: 20 }
    ),
  )
}

///|
priv enum Coin {
  Head
  Tail
} derive(Debug)

///|
test "unsafe to/from any for enums" {
  let coin = Head
  debug_inspect(
    (coin |> unsafe_to_any |> unsafe_from_any : Coin),
    content=(
      #|Head
    ),
  )
  let coin = Tail
  debug_inspect(
    (coin |> unsafe_to_any |> unsafe_from_any : Coin),
    content=(
      #|Tail
    ),
  )
}

///|
test "unsafe to/from any for strings" {
  let s = "Hello"
  debug_inspect(
    (s |> unsafe_to_any |> unsafe_from_any : String),
    content=(
      #|"Hello"
    ),
  )
}
