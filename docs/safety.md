# Safety and attributes

Core calculations are annotated @safe pure nothrow @nogc where the compiler
verifies those properties. The examples/no_gc.d example places grid creation
inside a function that carries all four attributes; compiling it is a
compiler-checked attribute test.

Direct aggregate construction can represent invalid CivilDate fields. Call
isValid or use tryMake at input boundaries. Operations that can fail at
supported-year edges return bool and an output value instead of silently
wrapping.

No system clock or time-zone conversion is performed. The library models
civil dates only; it does not claim to convert instants or resolve DST gaps.

The core module also compiles with BetterC when the formatting-only
YearMonth.toString member is excluded by the compiler's D_BetterC version.
BetterC users retain the date, grid, mask, blank-grid, and fingerprint APIs;
string formatting is intentionally runtime-library dependent.
