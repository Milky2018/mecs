# Archived mecs 0.1 implementation

This package preserves the last complete implementation before the 0.2 rewrite.
Its source files were copied without semantic changes from commit
`a6d8d92` (`Update MoonBit module syntax`).

Import it as `Milky2018/mecs/archived` when comparison code needs to compile
against the old API. It is archived reference code and will not evolve with the
new root package.

The package suppresses warning 79 because the preserved 0.1 source relies on
the former implicit promotion of derived trait methods.
