# Performance And Storage

This document records the current performance baseline and storage tradeoffs for
`mecs`. Benchmark numbers are machine-dependent, so treat them as local
comparisons rather than portable guarantees.

## Running Benchmarks

Run the full benchmark suite across stable targets:

```sh
moon bench --target all --release
```

Run one target when comparing local changes:

```sh
moon bench --target native --release
```

The benchmark suite lives in `mecs_bench_test.mbt` and covers:

- spawning 1000 entities
- despawning 1000 entities
- inserting 1000 components
- removing 1000 components
- `query3` over 1000 entities
- setting, getting, and removing one resource 1000 times

## Baseline

Recorded on 2026-05-08 with:

```sh
moon bench --target all --release
```

| Target | Spawn 1000 | Despawn 1000 | Insert 1000 | Remove 1000 | Query3 1000 | Resource 1000 |
|---|---:|---:|---:|---:|---:|---:|
| wasm | 335.81 us | 456.39 us | 585.81 us | 1.41 ms | 619.50 us | 381.20 us |
| wasm-gc | 73.22 us | 99.33 us | 126.40 us | 352.47 us | 175.37 us | 77.67 us |
| js | 149.77 us | 184.29 us | 194.08 us | 421.10 us | 143.40 us | 79.76 us |
| native | 118.21 us | 163.29 us | 196.04 us | 480.26 us | 181.69 us | 107.25 us |

## Current Storage

The current storage shape is:

- `Set[EntityId]` for live entities.
- `Map[EntityId, Map[ComponentId, Component]]` for components.
- `Map[ResourceId, Resource]` for resources.

This keeps the implementation compact, portable, and compatible with
extensible-enum component values. It also makes dynamic component sets easy:
every entity owns a component map keyed by opaque component ids.

The main cost is query locality. A query scans entity component maps and performs
one map lookup per requested component. This is simple and deterministic, but it
does not get the cache locality of a per-component sparse storage layout.

## Sparse Storage Evaluation

A future sparse storage design can keep the same public API by storing each
component id in its own `Map[EntityId, Component]` or sparse-set-like table:

- Public typed API remains `ComponentValue` plus extensible enum conversion.
- `World::insert_component` writes to storage for `C::component_id()`.
- `World::get_component` reads the component id storage, then validates the
  extensible enum variant with `C::from_component`.
- Queries can iterate the smallest component table, then probe the other
  component tables.

Expected benefits:

- Fewer component-id lookups inside wide queries.
- Better query locality for common component types.
- Faster component removal when the component id table is already known.

Costs and risks:

- More storage bookkeeping when despawning an entity, because every component
  table must remove that entity or tombstones must be tracked.
- More complex command application and id/variant mismatch handling.
- The implementation is harder to audit than the current map-of-maps design.

Decision: keep the current map-based storage until query semantics and the
scheduler are stable under real usage. Use the benchmark suite before and after
any storage refactor, and only accept a sparse-storage change if the public
type-safe API and failure behavior stay unchanged.
