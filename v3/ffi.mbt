///|
priv type RawWorld

///|
extern "c" fn raw_world_new() -> RawWorld = "mecs_v3_world_new"

///|
#borrow(world)
extern "c" fn raw_world_spawn(world : RawWorld) -> UInt = "mecs_v3_world_spawn"

///|
#borrow(world)
extern "c" fn raw_world_is_alive(world : RawWorld, entity : UInt) -> Bool = "mecs_v3_world_is_alive"

///|
#borrow(world)
extern "c" fn raw_world_despawn(world : RawWorld, entity : UInt) -> Bool = "mecs_v3_world_despawn"

///|
#borrow(world, type_id)
#owned(value)
extern "c" fn raw_world_set_component(
  world : RawWorld,
  type_id : String,
  entity : UInt,
  value : AnyRef,
) -> Unit = "mecs_v3_world_set_component"

///|
#borrow(world, type_id)
extern "c" fn raw_world_has_component(
  world : RawWorld,
  type_id : String,
  entity : UInt,
) -> Bool = "mecs_v3_world_has_component"

///|
#borrow(world, type_id)
extern "c" fn raw_world_get_component(
  world : RawWorld,
  type_id : String,
  entity : UInt,
) -> AnyRef = "mecs_v3_world_get_component"

///|
#borrow(world, type_id)
extern "c" fn raw_world_remove_component(
  world : RawWorld,
  type_id : String,
  entity : UInt,
) -> Unit = "mecs_v3_world_remove_component"

///|
#borrow(world, type_id)
extern "c" fn raw_world_component_count(
  world : RawWorld,
  type_id : String,
) -> Int = "mecs_v3_world_component_count"

///|
#borrow(world, type_id)
extern "c" fn raw_world_component_entity_at(
  world : RawWorld,
  type_id : String,
  index : Int,
) -> UInt = "mecs_v3_world_component_entity_at"

///|
#borrow(world, type_id)
#owned(value)
extern "c" fn raw_world_set_resource(
  world : RawWorld,
  type_id : String,
  value : AnyRef,
) -> Unit = "mecs_v3_world_set_resource"

///|
#borrow(world, type_id)
extern "c" fn raw_world_has_resource(
  world : RawWorld,
  type_id : String,
) -> Bool = "mecs_v3_world_has_resource"

///|
#borrow(world, type_id)
extern "c" fn raw_world_get_resource(
  world : RawWorld,
  type_id : String,
) -> AnyRef = "mecs_v3_world_get_resource"

///|
#borrow(world, type_id)
extern "c" fn raw_world_remove_resource(
  world : RawWorld,
  type_id : String,
) -> Unit = "mecs_v3_world_remove_resource"
