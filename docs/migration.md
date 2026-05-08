# Migration Notes

`mecs` now uses the extensible-enum design as the final public model. Earlier
experimental versions explored several implementation strategies; new code
should target the root package API documented in `README.mbt.md`.

## From Primitive Or Type-Erased Storage

Earlier experiments used implementation primitives or type-erased storage to
recover user component values. The current API does not rely on compiler
primitives, `Any`, or C FFI. Define user values by extending `@mecs.Component`
and `@mecs.Resource`, then implement `ComponentValue` or `ResourceValue`.

## From C FFI Storage

Native-only C FFI storage is no longer the library direction. The current
storage is portable across stable MoonBit targets and uses explicit conversion
through extensible enum variants.

## From Old Id Strings

Component and resource ids are now opaque `ComponentId` and `ResourceId`
values. Use `@mecs.component_id("VariantName")` and
`@mecs.resource_id("VariantName")` in trait implementations. The string must
match the extensible enum variant name exactly.

## From Direct Structural Mutation In Systems

Direct `World` mutation is still available for simple code, but systems that
need structural changes should prefer `Commands`. Register those systems with
`CommandSystem` or `World::add_command_system_fn`; commands are applied after
that system finishes.

## From Linear System Lists

Plain `add_system` still works and registers into `Update`. For explicit
scheduling, use `add_system_to_stage`, labels, ordering constraints, and
optional `run_if` conditions.

## From Abort-First Reads

`require_component` and `get_resource` remain convenience APIs. Production code
that expects missing state should use checked APIs such as
`get_component_checked`, `get_resource_checked`, and
`remove_component_checked`, or optional APIs such as `get_component` and
`try_get_resource`.
