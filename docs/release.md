# Release Process

This document defines the production release policy for `mecs`.

## Supported Targets

`mecs` is intended to support MoonBit stable targets:

- `wasm`
- `wasm-gc`
- `js`
- `native`

The `llvm` target is not part of the supported release matrix.

## Semantic Versioning

After `1.0.0`, releases follow semantic versioning:

- Patch releases fix bugs without changing public APIs.
- Minor releases add backward-compatible APIs.
- Major releases may change or remove public APIs.

Before `1.0.0`, minor releases may include breaking changes. Patch releases
should still remain backward compatible.

## Public API Policy

The release API is the generated interface in `pkg.generated.mbti`. Before a
release, review this file and confirm that every exported type, trait, function,
method, and error is intentional.

`EntityId` is an opaque handle. Users receive it from `World::spawn`,
`World::spawn_with`, `Commands::spawn`, or query/entity APIs. They should not
construct arbitrary entity ids from integers. Use `EntityId::value` only for
diagnostics, logging, serialization keys, or tests.

## Required Checks

Run the full validation gate before tagging:

```sh
moon info
moon fmt
git diff --exit-code
moon check --warn-list +73
moon test --target all
moon bench --target all --release --build-only
git diff --check
```

Run performance benchmarks on `native` when a release includes query or storage
changes:

```sh
moon bench --target native --release
```

Record meaningful benchmark changes in `docs/performance.md`.

## Release Checklist

- [ ] Update `CHANGELOG.md`.
- [ ] Review `pkg.generated.mbti`.
- [ ] Confirm `moon.mod.json` has the intended version.
- [ ] Run the required checks.
- [ ] Confirm CI passes.
- [ ] Tag the release.
