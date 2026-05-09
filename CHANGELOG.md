# Changelog

All notable changes to `mecs` are recorded here.

This project follows semantic versioning after the first stable release. Before
`1.0.0`, minor versions may include breaking API changes, and patch versions are
reserved for compatible fixes.

## Unreleased

- Wrapped `EntityId` in an opaque handle type instead of exposing it as `UInt`.
- Added streaming query helpers `for_each1` through `for_each5`.
- Added direct value iterators for `query1` through `query5`.
- Added command buffers, scheduler stages, system labels, run conditions, and
  checked error-returning APIs.
- Added native and all-target benchmarks for spawn, despawn, mutation, queries,
  resources, and storage layout comparisons.

## 0.1.0

- Initial extensible-enum ECS design.
