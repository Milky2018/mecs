///|
pub struct System {
  name : String
  func : (World) -> Unit
}

///|
let system_name_gen : Ref[UInt] = Ref(0)

///|
fn anonymous_system() -> String {
  let id = system_name_gen.val
  system_name_gen.val += 1
  "system#\{id}"
}

///|
pub fn System::System(
  func : (World) -> Unit,
  name? : String = anonymous_system(),
) -> Self {
  { name, func }
}
