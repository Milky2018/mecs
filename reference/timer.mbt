///|
struct TimerId(UInt64) derive(Eq, Debug)

///|
pub extend TimerId with Eq::{equal, not_equal}

///|
pub extend TimerId with @debug.Debug::{to_repr}

///|
priv struct ScheduledAction {
  id : TimerId
  mut remaining : Double
  action : (CommandEmitter) -> Unit
}

///|
/// A deterministic timer queue advanced explicitly by delta time.
struct Timers {
  mut next_id : UInt64
  mut scheduled : Array[ScheduledAction]
}

///|
pub fn Timers::new() -> Timers {
  { next_id: 0UL, scheduled: [], }
}

///|
pub fn Timers::after(
  self : Timers,
  delay : Double,
  action : (CommandEmitter) -> Unit,
) -> TimerId {
  guard delay >= 0.0 else { abort("timer delay must be non-negative") }
  let id = TimerId(self.next_id)
  self.next_id += 1UL
  self.scheduled.push({ id, remaining: delay, action, })
  id
}

///|
pub fn Timers::cancel(self : Timers, timer : TimerId) -> Bool {
  for index, scheduled in self.scheduled {
    if scheduled.id == timer {
      swap_remove_row(self.scheduled, index)
      return true
    }
  }
  false
}

///|
/// Advances one batch. Timers scheduled by callbacks start on the next update.
pub fn Timers::update(
  self : Timers,
  delta_time : Double,
  commands : CommandEmitter,
) -> Unit {
  guard delta_time >= 0.0 else {
    abort("timer delta time must be non-negative")
  }
  let batch = self.scheduled
  self.scheduled = []
  for scheduled in batch {
    scheduled.remaining -= delta_time
    if scheduled.remaining <= 0.0 {
      (scheduled.action)(commands)
    } else {
      self.scheduled.push(scheduled)
    }
  }
}
