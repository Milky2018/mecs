# mecs Production Roadmap

This roadmap tracks the work needed to turn `mecs` from a compact experimental
ECS into a production-quality MoonBit library. The current foundation is the
extensible-enum design: users extend `Component` and `Resource`, then implement
typed conversion traits for their own component and resource values.

## Principles

- [ ] Preserve type safety without compiler primitives, type-erased `Any`, or C
      FFI.
- [ ] Keep the core API portable across MoonBit stable targets.
- [ ] Prefer explicit semantics over hidden mutation or scheduler behavior.
- [ ] Add abstractions only when they remove real user burden or clarify safety.
- [ ] Keep every public API change reflected in `pkg.generated.mbti` and tests.

## Phase 1: API Hardening

Goal: make the current API difficult to misuse before expanding features.

- [x] Replace `ComponentId = String` and `ResourceId = String` with stronger
      opaque identifier types.
- [x] Define and test identifier collision behavior.
- [x] Add constructors and document the convention that ids match extensible
      enum variant names exactly.
- [x] Document the exact relationship between `component_id`, `to_component`,
      and `from_component`.
- [x] Decide whether mismatched component ids and enum variants should return
      `None`, abort, or become a diagnostic-only invariant.
- [x] Add focused tests for missing entities, missing components, removed
      components, and removed resources.

Acceptance criteria:

- [x] Users cannot accidentally treat component and resource ids as arbitrary
      strings in normal API use.
- [x] Public documentation explains how custom types become ECS values.
- [x] Tests cover id collisions and conversion mismatch behavior.

## Phase 2: Mutation Semantics

Goal: make system and query behavior deterministic.

- [x] Write down the contract for `queryN`, `queryN_entities`, and `eachN`.
- [x] Decide whether `queryN` returns snapshots, mutable values, or values that
      must be explicitly written back.
- [x] Keep `eachN` writeback behavior explicit and tested.
- [x] Add tests for mutation persistence through `each2` and `each3`.
- [x] Add tests for despawn, component insertion, and component removal during
      iteration.
- [x] Decide whether direct world mutation during iteration is supported,
      discouraged, or blocked by command buffers.

Acceptance criteria:

- [x] A system author can predict exactly when component changes become visible.
- [x] Iteration behavior remains deterministic when entities are changed
      mid-frame.
- [x] The README shows the recommended mutation pattern.

## Phase 3: Command Buffer

Goal: support safe deferred world mutation from systems.

- [x] Add a `Commands` type.
- [x] Support deferred `spawn`, `despawn`, `insert_component`,
      `remove_component`, `set_resource`, and `remove_resource`.
- [x] Add `World::apply_commands`.
- [x] Add a system execution mode that gives systems access to commands.
- [x] Define when commands are applied: after each system or after the full
      stage.
- [x] Test ordering, duplicate commands, and commands targeting dead entities.

Acceptance criteria:

- [x] Systems can request structural changes without invalidating active
      queries.
- [x] Command application order is deterministic and documented.
- [x] Existing direct mutation APIs remain available for simple use cases.

## Phase 4: Scheduler

Goal: move from a linear system list to a predictable execution model.

- [x] Add named stages such as startup, update, fixed update, and cleanup.
- [x] Add system labels and ordering constraints.
- [x] Add optional run conditions.
- [x] Decide whether resources can drive scheduling state.
- [x] Keep the first scheduler single-threaded and deterministic.
- [x] Expose enough metadata for debugging system order.

Acceptance criteria:

- [x] Users can express common game-loop and simulation schedules.
- [x] System order can be inspected in tests or diagnostics.
- [x] Scheduler behavior is independent of backend.

## Phase 5: Query Coverage

Goal: broaden query expressiveness without making the core brittle.

- [x] Refactor query internals so adding more arities is mechanical.
- [x] Add `query4` and `query5` first.
- [x] Add entity-returning versions as `Iter2[EntityId, (...)]`.
- [x] Consider optional filters such as `with`, `without`, and entity-only
      queries.
- [x] Add tests for duplicate component types in a query and document whether
      they are rejected or treated as repeated reads.

Acceptance criteria:

- [x] Common multi-component systems do not need custom query code.
- [x] Query return shapes stay consistent across arities.
- [x] Query implementation remains small enough to audit.

## Phase 6: Error Model

Goal: avoid abort-first APIs in production paths.

- [x] Keep `require_component` and `get_resource` as convenience APIs.
- [x] Add safe alternatives for all APIs that can fail.
- [x] Consider typed errors for entity-not-found, component-not-found,
      resource-not-found, and id/variant mismatch.
- [x] Document when an API returns `None`, returns `false`, returns an error, or
      aborts.
- [x] Add tests for every failure mode.

Acceptance criteria:

- [x] Production code can avoid aborting on expected missing ECS state.
- [x] Failure behavior is consistent across components, resources, and
      entities.
- [x] The generated interface makes safe APIs obvious.

## Phase 7: Ergonomics

Goal: reduce boilerplate without weakening the model.

- [x] Improve README examples for components, resources, systems, and queries.
- [x] Add a complete small example package or executable.
- [x] Investigate whether MoonBit tooling can generate repetitive
      `ComponentValue` and `ResourceValue` impls.
- [x] Add helper functions or naming conventions for common id patterns.
- [x] Provide migration notes from the previous experimental versions.

Acceptance criteria:

- [x] A new user can define a component and run a system from the README alone.
- [x] The common component/resource boilerplate is either minimal or
      mechanically generated.
- [x] Examples are covered by tests where possible.

## Phase 8: Performance And Storage

Goal: understand and improve runtime cost without sacrificing portability.

- [x] Add microbenchmarks for spawn, despawn, insert, remove, query, and
      resources.
- [x] Measure the cost of map-based component storage.
- [x] Evaluate per-component sparse storage while retaining extensible-enum
      values.
- [x] Avoid optimizing before query and mutation semantics are stable.
- [x] Track performance across wasm, wasm-gc, js, and native targets.

Acceptance criteria:

- [x] Baseline performance is measured and repeatable.
- [x] Any storage refactor preserves the public type-safe API.
- [x] Performance-sensitive tradeoffs are documented.

Optimization backlog:

- [x] Add ECS-shaped storage comparison benchmarks for nested maps,
      per-component maps, per-component hashmaps, `SlotMap + SecondaryMap`, and
      `SlotMap + SparseSecondaryMap`.
- [x] Implement per-component storage behind the existing public API:
      `Map[ComponentId, @hashmap.HashMap[EntityId, Component]]`.
- [ ] Prototype `SlotMap`-allocated entity keys plus per-component
      `SecondaryMap` columns after deciding whether `EntityId = UInt` can
      change.
- [x] Keep `@hashmap.HashMap` component columns as the control implementation
      and adopt them for the current backend.
- [x] Make queries iterate the smallest matching component table instead of
      scanning every entity map.
- [x] Use component store lengths so wide queries can choose the cheapest
      driving component deterministically.
- [x] Improve component removal by going directly to component-id storage when
      sparse storage exists.
- [x] Evaluate despawn bookkeeping strategies for sparse storage: use eager
      removal from the entity's recorded component-id list for now.
- [ ] Treat `SparseSecondaryMap` as a memory-oriented experiment, not the
      default path, unless memory benchmarks justify its runtime cost.
- [x] Preserve current `ComponentValue` / `ResourceValue` conversion and
      `EcsError` mismatch behavior during any storage refactor.
- [ ] Keep benchmarks as the acceptance gate: require before/after numbers for
      spawn, despawn, insert, remove, query, and resources on all stable targets.

## Phase 9: Release Readiness

Goal: prepare the library for real users and versioned releases.

- [ ] Decide semantic versioning policy.
- [ ] Add a changelog.
- [ ] Expand package docs and examples.
- [ ] Add CI commands matching local validation: `moon info`, `moon fmt`,
      `moon check --warn-list +73`, and `moon test --target all`.
- [ ] Document supported targets.
- [ ] Audit public names before the first stable release.

Acceptance criteria:

- [ ] The repository has a documented release process.
- [ ] CI verifies formatting, generated interfaces, warnings, and all-target
      tests.
- [ ] The public API is intentionally stable for the chosen release version.

## Current Priority

- [x] Start with Phase 1.
- [x] Treat strong component and resource identifiers as the first production
      API decision, because changing them later will be more expensive once
      scheduler, commands, and broader queries build on top of them.
