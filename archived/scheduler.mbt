///|
priv enum SystemEntry {
  DirectSystem(System)
  DeferredSystem(CommandSystem)
}

///|
priv struct ScheduledSystem {
  stage : Stage
  label : SystemLabel
  before : Array[SystemLabel]
  after : Array[SystemLabel]
  run_if : (World) -> Bool
  entry : SystemEntry
}

///|
fn always_run(_world : World) -> Bool {
  true
}

///|
fn labels_contain(labels : Array[SystemLabel], label : SystemLabel) -> Bool {
  for candidate in labels {
    if candidate == label {
      return true
    }
  }
  false
}

///|
fn indices_contain(indices : Array[Int], index : Int) -> Bool {
  for candidate in indices {
    if candidate == index {
      return true
    }
  }
  false
}

///|
fn World::stage_contains_label(
  self : Self,
  indices : Array[Int],
  label : SystemLabel,
) -> Bool {
  for index in indices {
    if self.systems[index].label == label {
      return true
    }
  }
  false
}

///|
fn World::ordered_contains_label(
  self : Self,
  indices : Array[Int],
  label : SystemLabel,
) -> Bool {
  for index in indices {
    if self.systems[index].label == label {
      return true
    }
  }
  false
}

///|
fn World::system_ready(
  self : Self,
  system_index : Int,
  candidates : Array[Int],
  ordered : Array[Int],
) -> Bool {
  let scheduled = self.systems[system_index]
  for label in scheduled.after {
    if self.stage_contains_label(candidates, label) &&
      !self.ordered_contains_label(ordered, label) {
      return false
    }
  }
  for other_index in candidates {
    if other_index != system_index && !indices_contain(ordered, other_index) {
      let other = self.systems[other_index]
      if labels_contain(other.before, scheduled.label) {
        return false
      }
    }
  }
  true
}

///|
fn World::ordered_system_indices(self : Self, stage : Stage) -> Array[Int] {
  let candidates : Array[Int] = []
  for index in 0..<self.systems.length() {
    if self.systems[index].stage == stage {
      candidates.push(index)
    }
  }
  let ordered : Array[Int] = []
  for _ in 0..<candidates.length() {
    let before_length = ordered.length()
    for index in candidates {
      if !indices_contain(ordered, index) &&
        self.system_ready(index, candidates, ordered) {
        ordered.push(index)
      }
    }
    if ordered.length() == before_length {
      for index in candidates {
        if !indices_contain(ordered, index) {
          ordered.push(index)
        }
      }
    }
  }
  ordered
}

///|
fn World::add_scheduled_system(
  self : Self,
  stage : Stage,
  label : SystemLabel,
  entry : SystemEntry,
  before : Array[SystemLabel],
  after : Array[SystemLabel],
  run_if : (World) -> Bool,
) -> Unit {
  self.systems.push({ stage, label, before, after, run_if, entry, })
}

///|
fn World::run_system_entry(
  self : Self,
  entry : SystemEntry,
) -> Unit raise NotSpawned {
  match entry {
    DirectSystem(system) => (system.func)(self)
    DeferredSystem(system) => {
      let commands = self.commands()
      (system.func)(self, commands)
      self.apply_commands(commands)
    }
  }
}

///|
pub fn World::add_system_to_stage(
  self : Self,
  stage : Stage,
  system : System,
  before? : Array[SystemLabel] = [],
  after? : Array[SystemLabel] = [],
  run_if? : (World) -> Bool = always_run,
) -> Unit {
  self.add_scheduled_system(
    stage,
    system.label(),
    DirectSystem(system),
    before,
    after,
    run_if,
  )
}

///|
pub fn World::add_system_fn_to_stage(
  self : Self,
  stage : Stage,
  func : (World) -> Unit,
  name? : String = "system",
  before? : Array[SystemLabel] = [],
  after? : Array[SystemLabel] = [],
  run_if? : (World) -> Bool = always_run,
) -> Unit {
  self.add_system_to_stage(stage, System(func, name~), before~, after~, run_if~)
}

///|
pub fn World::add_command_system_to_stage(
  self : Self,
  stage : Stage,
  system : CommandSystem,
  before? : Array[SystemLabel] = [],
  after? : Array[SystemLabel] = [],
  run_if? : (World) -> Bool = always_run,
) -> Unit {
  self.add_scheduled_system(
    stage,
    system.label(),
    DeferredSystem(system),
    before,
    after,
    run_if,
  )
}

///|
pub fn World::add_command_system_fn_to_stage(
  self : Self,
  stage : Stage,
  func : (World, Commands) -> Unit,
  name? : String = "system",
  before? : Array[SystemLabel] = [],
  after? : Array[SystemLabel] = [],
  run_if? : (World) -> Bool = always_run,
) -> Unit {
  self.add_command_system_to_stage(
    stage,
    CommandSystem(func, name~),
    before~,
    after~,
    run_if~,
  )
}

///|
pub fn World::run_stage(self : Self, stage : Stage) -> Unit raise NotSpawned {
  for index in self.ordered_system_indices(stage) {
    let system = self.systems[index]
    if (system.run_if)(self) {
      self.run_system_entry(system.entry)
    }
  }
}

///|
pub fn World::fixed_step(self : Self) -> Unit raise NotSpawned {
  self.run_stage(FixedUpdate)
}

///|
pub fn World::system_order(
  self : Self,
  stage? : Stage = Update,
) -> Array[SystemLabel] {
  let labels : Array[SystemLabel] = []
  for index in self.ordered_system_indices(stage) {
    labels.push(self.systems[index].label)
  }
  labels
}
