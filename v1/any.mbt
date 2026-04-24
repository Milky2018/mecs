///|
priv type Any

///|
fn[A, B] coe(a : A) -> B = "%identity"

///|
fn[K : Eq + Hash, V] save_any(store : Map[K, Any], k : K, v : V) -> Unit {
  store[k] = coe(v)
}

///|
fn[K : Eq + Hash, V] load_any(store : Map[K, Any], k : K) -> V {
  store[k] |> coe
}
