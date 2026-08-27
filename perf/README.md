# Archived mecs 0.1 benchmark baseline

Recorded on 2026-08-27 for the archived 0.1 implementation copied from commit
`a6d8d92`. The benchmark source is
[`archived/mecs_bench_test.mbt`](../archived/mecs_bench_test.mbt), adapted
only to use the `@archived` package alias.

These numbers are a local baseline, not portable guarantees. Compare future
implementations against the same backend and machine. Native-to-Wasm ratios
also include backend and runtime differences; they do not isolate the cost of
the unified `Component` representation.

## Environment

- macOS 26.5.2 (25F84), arm64
- Apple M3 Max
- 128 GiB memory
- `moon 0.1.20260826 (aa7a05b 2026-08-26)`
- `moonc v0.10.11+08a1f6adb (2026-08-26)`
- `moonrun 0.1.20260826 (aa7a05b 2026-08-26)`
- Release mode, sequential benchmark execution
- Repository revision before adding the benchmark artifacts:
  `b3656508a41ee85af51684a7a4ea369dabac0e49`

## Commands

```sh
moon bench --package Milky2018/mecs/archived \
  --file mecs_bench_test.mbt --target native --release --no-parallelize

moon bench --package Milky2018/mecs/archived \
  --file mecs_bench_test.mbt --target wasm --release --no-parallelize
```

## Results

All workloads operate on 1000 entities or perform 1000 resource operations.

| Workload | Native mean | Wasm mean | Wasm / native |
|---|---:|---:|---:|
| Spawn | 105.05 µs | 326.02 µs | 3.10x |
| Despawn | 142.97 µs | 483.28 µs | 3.38x |
| Insert component | 238.23 µs | 802.99 µs | 3.37x |
| Remove component | 587.11 µs | 1.76 ms | 3.00x |
| Query1 | 15.70 µs | 50.43 µs | 3.21x |
| For-each1 | 3.35 µs | 10.38 µs | 3.10x |
| Query2 | 40.43 µs | 123.14 µs | 3.05x |
| For-each2 | 18.98 µs | 49.37 µs | 2.60x |
| Query3 | 56.94 µs | 137.36 µs | 2.41x |
| For-each3 | 34.76 µs | 78.86 µs | 2.27x |
| Query4 | 71.02 µs | 171.32 µs | 2.41x |
| For-each4 | 47.22 µs | 131.93 µs | 2.79x |
| Query5 | 87.34 µs | 198.92 µs | 2.28x |
| For-each5 | 59.10 µs | 121.77 µs | 2.06x |
| Sparse query3 | 14.03 µs | 35.68 µs | 2.54x |
| Sparse for-each3 | 7.69 µs | 23.28 µs | 3.03x |
| Filtered query2 with Health | 17.73 µs | 53.85 µs | 3.04x |
| Filtered query2 without Health | 90.06 µs | 285.51 µs | 3.17x |
| Set/get/remove resource | 84.53 µs | 398.75 µs | 4.72x |

The complete harness output, including standard deviation, min/max range, and
sample counts, is preserved in:

- [Native raw output](./2026-08-27-archived-0.1-native.txt)
- [Wasm raw output](./2026-08-27-archived-0.1-wasm.txt)
