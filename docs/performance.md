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

The baseline ECS benchmark suite lives in `mecs_bench_test.mbt` and covers:

- spawning 1000 entities
- despawning 1000 entities
- inserting 1000 components
- removing 1000 components
- `query1` over 1000 entities
- `query2` over 1000 entities
- `for_each2` over 1000 entities
- `query3` over 1000 entities
- `query4` over 1000 entities
- sparse `query3` over 1000 entities with one matching component on one in four
  entities
- setting, getting, and removing one resource 1000 times

The storage comparison suite lives in `storage_compare_bench_test.mbt` and
compares:

- current nested maps: `Map[EntityId, Map[ComponentId, Component]]`
- per-component builtin maps
- per-component `@hashmap.HashMap`s
- `@slotmap.SlotMap` entities plus `@slotmap.SecondaryMap` component columns
- `@slotmap.SlotMap` entities plus `@slotmap.SparseSecondaryMap` component
  columns
- entity churn with `Set`, builtin `Map`, `SlotMap`, and `DenseSlotMap`

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

## Optimized Native Results

Recorded on 2026-05-08 with:

```sh
moon bench --target native --release
```

| Storage | Spawn 1000 | Despawn 1000 | Insert 1000 | Remove 1000 | Query1 1000 | Dense Query2 1000 | Dense for_each2 1000 | Dense Query3 1000 | Dense for_each3 1000 | Dense Query4 1000 | Sparse Query3 1000 | Sparse for_each3 1000 | Resource 1000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Original nested maps | 118.21 us | 163.29 us | 196.04 us | 480.26 us | N/A | N/A | N/A | 181.69 us | N/A | N/A | N/A | N/A | 107.25 us |
| HashMap component columns + direct probes | 103.54 us | 152.07 us | 242.69 us | 606.82 us | 16.25 us | 36.55 us | 17.25 us | 48.88 us | 29.53 us | 63.92 us | 12.75 us | 6.82 us | 110.39 us |

The current storage is query-oriented. Dense `query3` is about 30% faster on
native from the column-store layout alone, and direct cached store probes bring
the measured dense `query3` to about three times faster than the original nested
map baseline. Sparse `query3` can drive from the smallest component column and
avoid repeated component-id/store lookup work. `query2`, `query3`, and `query4`
bypass the entity-returning row iterator when entity ids are not requested.
`query1` also drives directly from its component store instead of mapping over
`query1_entities` and discarding entity ids. `for_each3` avoids the result array
allocation used by `query3().to_array()` and drives directly from the selected
component store, bypassing the row iterator path.
Insert and remove are slower because writes maintain both the entity
component-id list and the component column. The remove benchmark also includes
world construction, so it captures part of the insertion cost.

## Storage Comparison

Recorded on 2026-05-08 with:

```sh
moon bench --target native --release
```

These comparisons use simplified integer component values. They are meant to
compare storage layout costs, not the full public ECS API cost. The full ECS
benchmarks still include extensible-enum conversion, typed query construction,
and `to_array` collection.

Dense storage with three components on every entity:

| Storage | Build 1000 x3 | Dense Query3 1000 | Remove Position 1000 | Despawn 1000 |
|---|---:|---:|---:|---:|
| Nested builtin maps | 111.06 us | 21.30 us | 118.02 us | 128.56 us |
| Component builtin maps | 110.93 us | 20.83 us | 120.63 us | 151.67 us |
| Component hashmaps | 62.76 us | 22.43 us | 89.95 us | 109.15 us |
| SlotMap + SecondaryMap | 52.29 us | 19.66 us | 55.71 us | 74.66 us |
| SlotMap + SparseSecondaryMap | 186.65 us | 42.14 us | 198.35 us | 252.48 us |

Sparse query with `Health` present on one in four entities:

| Storage | Dense-Drive Query3 | Sparse-Drive Query3 |
|---|---:|---:|
| Nested builtin maps | 21.62 us | N/A |
| Component builtin maps | 19.23 us | 4.73 us |
| Component hashmaps | 18.54 us | 4.26 us |
| SlotMap + SecondaryMap | 21.80 us | 5.08 us |
| SlotMap + SparseSecondaryMap | 44.37 us | 9.80 us |

Entity churn with 1000 live entities and 1000 remove/insert rounds:

| Entity Store | Churn 1000 |
|---|---:|
| Set[Int] | 96.53 us |
| Map[Int, Int] | 86.12 us |
| SlotMap | 44.59 us |
| DenseSlotMap | 60.50 us |

Storage conclusions:

- `SlotMap` is a strong candidate for entity allocation and stale entity-key
  protection. It roughly halves entity churn cost in this native run.
- `SlotMap + SecondaryMap` is the best measured column-store candidate for
  dense ECS components. It wins build, dense query, remove, and eager despawn in
  this storage-only comparison.
- `SparseSecondaryMap` is not a good default for this ECS workload. It is slower
  in both dense and sparse component scenarios here; keep it only as a possible
  memory-saving option that needs a separate memory benchmark.
- `@hashmap.HashMap` component columns are also competitive, especially for
  sparse-drive queries. They should be compared against `SecondaryMap` in any
  real storage refactor.
- Choosing the smallest component table as the query driver matters more than
  the container choice for sparse queries. In this run, sparse-drive query3 is
  about four to five times faster than dense-drive query3.

## Current Storage

The current storage shape is:

- `Set[EntityId]` for live entities.
- `Map[EntityId, Array[ComponentId]]` for each entity's component ids.
- `Map[ComponentId, @hashmap.HashMap[EntityId, Component]]` for component
  values.
- `Map[ResourceId, Resource]` for resources.

This keeps the public API portable and compatible with extensible-enum
component values while making queries column-oriented. Entity rows store only
component ids for despawn bookkeeping; component values live in per-component
hashmap columns.

The main tradeoff is mutation cost. Inserts, removes, and despawns must keep the
entity component-id list and component columns in sync. Queries avoid scanning
unrelated entity rows and can iterate the smallest matching component column.

## Sparse Storage Evaluation

The implemented sparse storage keeps the same public API by storing each
component id in its own `@hashmap.HashMap[EntityId, Component]`:

- Public typed API remains `ComponentValue` plus extensible enum conversion.
- `World::insert_component` writes to storage for `C::component_id()`.
- `World::get_component` reads the component id storage, then validates the
  extensible enum variant with `C::from_component`.
- Queries can iterate the smallest component table, then probe the other
  component tables.
- Query iterators cache the chosen component stores and probe them directly
  instead of calling `World::get_component` for each candidate entity.
- `query2`, `query3`, and `query4` have direct value iterators so they do not build
  `Iter2[EntityId, (...)]` rows when callers do not need entity ids.
- `query1` has a direct value iterator so it does not build
  `Iter2[EntityId, C]` rows when callers do not need entity ids.
- `for_each2` and `for_each3` provide streaming traversal when callers do not
  need an allocated result array, and drive directly from the chosen component
  store instead of consuming `queryN_entities`.

Expected benefits:

- Fewer component-id lookups inside wide queries.
- Better query locality for common component types.
- Faster component removal when the component id table is already known.
- Lower allocation overhead for system-style query traversal.

Costs and risks:

- More storage bookkeeping when despawning an entity, because every component
  table must remove that entity or tombstones must be tracked.
- More complex command application and id/variant mismatch handling.
- The implementation is harder to audit than the original map-of-maps design.

Decision: keep the hashmap column backend for now because it improves real query
performance without changing the public API. Do not adopt `SlotMap` entity keys
until we are ready to revisit the public `EntityId = UInt` type. Do not adopt
`SparseSecondaryMap` as the default unless a future memory benchmark justifies
the slower runtime profile.
