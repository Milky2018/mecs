# Fixed-composition archetype benchmark

Recorded on 2026-08-27 for the fixed-composition typed-column implementation
in [`reference/mecs.mbt`](../reference/mecs.mbt).

The implementation creates the final archetype at spawn time. Component values
cannot be added or removed afterward. Each `ComponentKey[T]` indexes one
contiguous `Array[T]` per matching archetype, while `Query2[A, B]` caches
matching archetype ids and resolves typed columns outside the entity loop.

> Historical note: the full results below were measured before archetype
> identity moved from one `UInt64` to a dynamic `ComponentSet`. A 2026-09-03
> release-mode spawn smoke test of the dynamic implementation measured 85.92 µs
> for 1000 valtype entities and 94.56 µs for ordinary entities on Native, and
> 257.48 µs / 309.24 µs respectively on Wasm. Query workloads were not rerun.
> The later generational-entity/despawn implementation has not been benchmarked;
> these timings do not describe that version.

## Environment

- macOS 26.5.2 (25F84), arm64
- Apple M3 Max
- 128 GiB memory
- `moon 0.1.20260826 (4bca472 2026-08-26)`
- `moonc v0.10.10+62b3fef32-nightly (2026-08-26)`
- `moonrun 0.1.20260826 (4bca472 2026-08-26)`
- Release mode with sequential benchmark execution
- Base repository revision: `822f9be3feb9b44c316195a1fd640b3a74a9b61e`
- The implementation and benchmark were uncommitted when measured.

## Commands

```sh
moon bench --package Milky2018/mecs/reference --file mecs_bench_test.mbt \
  --target native --release --no-parallelize
moon bench --package Milky2018/mecs/reference --file mecs_bench_test.mbt \
  --target wasm --release --no-parallelize

moon bench --package Milky2018/mecs/archived \
  --file mecs_bench_test.mbt --index 4 \
  --target native --release --no-parallelize
moon bench --package Milky2018/mecs/archived \
  --file mecs_bench_test.mbt --index 4 \
  --target wasm --release --no-parallelize
```

## Typed-column results

Every world contains 1000 entities with Position, Velocity, and Health.
The read workloads sum the same Position and Velocity fields. Write workloads
then run a separate no-inline checksum so the compiler must observe the updated
columns. Ordinary components are measured both by replacing the whole object
and by mutating its fields in place.

| Workload | Native valtype | Native ordinary | Ordinary / valtype | Wasm valtype | Wasm ordinary | Ordinary / valtype |
|---|---:|---:|---:|---:|---:|---:|
| Spawn 1000 with three components | 65.89 µs | 76.53 µs | 1.16x | 205.38 µs | 253.75 µs | 1.24x |
| Query2 per entity read | 1.22 µs | 1.86 µs | 1.52x | 4.13 µs | 5.85 µs | 1.42x |
| Query2 batch read | 609.38 ns | 610.78 ns | 1.00x | 1.62 µs | 1.92 µs | 1.19x |
| Query2 per entity replace + checksum | 2.47 µs | 8.62 µs | 3.49x | 8.59 µs | 27.18 µs | 3.16x |
| Query2 batch replace + checksum | 1.40 µs | 6.61 µs | 4.72x | 6.12 µs | 19.73 µs | 3.22x |

The native batch-read result is almost representation-independent for this
small two-column arithmetic workload. Replacing an ordinary component remains
expensive because it allocates a new object.

### Mutable ordinary component

The third variant uses the same ordinary `BoxPosition` column but updates its
mutable fields through the object reference, without replacing the array slot.

| Workload | Native valtype replace | Native ordinary in-place | In-place / valtype | Wasm valtype replace | Wasm ordinary in-place | In-place / valtype |
|---|---:|---:|---:|---:|---:|---:|
| Query2 per entity write + checksum | 2.47 µs | 3.65 µs | 1.48x | 8.59 µs | 12.02 µs | 1.40x |
| Query2 batch write + checksum | 1.40 µs | 2.51 µs | 1.79x | 6.12 µs | 7.88 µs | 1.29x |

In-place mutation removes most of the ordinary-component write penalty, but in
this workload valtype replacement is still faster on both backends. This is not
an identical operation: the valtype path replaces an inline value, whereas the
ordinary path follows an object reference and mutates two fields.

## Comparable archived query

The closest archived workload is `for_each2`: it traverses the same 1000
Position/Velocity/Health entities and computes the same Position and Velocity
checksum without allocating a result array.

| Backend | Archived unified Component | Typed valtype per entity | Speedup | Typed ordinary per entity | Speedup |
|---|---:|---:|---:|---:|---:|
| Native | 18.08 µs | 1.22 µs | 14.82x | 1.86 µs | 9.72x |
| Wasm | 47.39 µs | 4.13 µs | 11.47x | 5.85 µs | 8.10x |

The typed batch interface is faster again, but it is not presented as an
interface-equivalent comparison because it gives the callback whole archetype
views rather than one entity at a time.

The new spawn workload is not directly comparable with the archived
`spawn 1000 entities` benchmark: the new workload creates all three component
columns at spawn, while the archived workload creates empty entities.

## Raw output

- [Native output](./2026-08-27-fixed-archetype-native.txt)
- [Wasm output](./2026-08-27-fixed-archetype-wasm.txt)
