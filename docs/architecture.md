# Architecture

The library separates Gregorian arithmetic, date values, cell topology, and
rendering-oriented masks. A month grid is a value: it contains at most 42
cells and associated metadata. No clock, time-zone database, process locale,
network service, or heap collection participates in the core calculations.

CivilDate and YearMonth cover Gregorian years 1 through 9999. Calendar
arithmetic is pure and deterministic. GridMode.natural uses the minimum whole
week count; GridMode.fixedSixWeeks always has six rows.

StaticMonth exposes a CTFE-evaluated MonthGrid and related constants. Use it
when the year, month, and week start are source-level constants. Use
MonthGrid.build for user input or other runtime values; that avoids requiring
template instantiation for each value.

The compact fingerprint encodes first weekday, day count, week start, row
count, and mode. It identifies layout-equivalent months only. It is neither a
cryptographic hash nor a unique identifier for a date or month.
