///|
/// An immutable, canonical dynamic bitset used as an archetype identity.
priv struct ComponentSet {
  words : FixedArray[UInt64]
}

///|
/// Reusable spawn-time state. Its bitset representation is intentionally opaque.
struct ComponentCollector {
  words : Array[UInt64]
  world_id : WorldId
  mut valid : Bool
}

///|
fn ComponentCollector::reset(self : ComponentCollector) -> Unit {
  self.words.fill(0UL)
  self.valid = true
}

///|
fn ComponentCollector::insert(
  self : ComponentCollector,
  component : Int,
  world_id : WorldId,
) -> Unit {
  if world_id != self.world_id {
    self.valid = false
    return
  }
  let word = component / 64
  let bit = 1UL << (component % 64)
  if (self.words[word] & bit) != 0UL {
    self.valid = false
    return
  }
  self.words[word] = self.words[word] | bit
}

///|
fn canonical_word_count(words : ArrayView[UInt64]) -> Int {
  for end = words.length(); end > 0; {
    if words[end - 1] != 0UL {
      break end
    }
    continue end - 1
  } nobreak {
    0
  }
}

///|
fn ComponentSet::from_scratch(scratch : ArrayView[UInt64]) -> ComponentSet {
  let length = canonical_word_count(scratch)
  { words: FixedArray::makei(length, i => scratch[i]), }
}

///|
fn ComponentSet::equals_scratch(
  self : ComponentSet,
  scratch : ArrayView[UInt64],
) -> Bool {
  let length = canonical_word_count(scratch)
  if self.words.length() != length {
    return false
  }
  for i in 0..<length {
    if self.words[i] != scratch[i] {
      return false
    }
  }
  true
}

///|
fn ComponentSet::contains(self : ComponentSet, component : Int) -> Bool {
  let word = component / 64
  word < self.words.length() &&
  (self.words[word] & (1UL << (component % 64))) != 0UL
}

///|
fn component_set_hash(scratch : ArrayView[UInt64]) -> UInt64 {
  let hash = Ref(1469598103934665603UL)
  for i in 0..<canonical_word_count(scratch) {
    hash.val = (hash.val ^ scratch[i]) * 1099511628211UL
  }
  hash.val
}
