///|
pub struct System {
  name : String
  func : (World) -> Unit
}

///|
pub struct CommandSystem {
  name : String
  func : (World, Commands) -> Unit
}

///|
pub(all) enum Stage {
  Startup
  Update
  FixedUpdate
  Cleanup
} derive(Eq, Debug)

///|
pub struct SystemLabel {
  name : String
} derive(Eq, Hash, Debug)

///|
pub fn SystemLabel::SystemLabel(name : String) -> Self {
  guard !name.is_empty() else { abort("system label cannot be empty") }
  { name, }
}

///|
pub fn SystemLabel::name(self : Self) -> String {
  self.name
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
  { name, func, }
}

///|
pub fn System::label(self : Self) -> SystemLabel {
  SystemLabel(self.name)
}

///|
pub fn CommandSystem::CommandSystem(
  func : (World, Commands) -> Unit,
  name? : String = anonymous_system(),
) -> Self {
  { name, func, }
}

///|
pub fn CommandSystem::label(self : Self) -> SystemLabel {
  SystemLabel(self.name)
}
