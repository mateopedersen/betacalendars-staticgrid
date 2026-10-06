# BetaCalendars StaticGrid

Compile-time and allocation-free Gregorian calendar topology for D. The
library combines CTFE-friendly month construction with fixed-size runtime
storage, 64-bit cell masks, and fixed-storage range views.

- Project: [BetaCalendars](https://www.betacalendars.com/)
- Blank structural reference: [Blank calendar](https://www.betacalendars.com/blank-calendar)
- Reference layouts: [November](https://www.betacalendars.com/november-calendar.html),
  [December](https://www.betacalendars.com/december-calendar.html),
  [January](https://www.betacalendars.com/january-calendar.html), and
  [February](https://www.betacalendars.com/february-calendar.html)
- Developer guide: [StaticGrid documentation](https://mateopedersen.github.io/betacalendars-staticgrid/)

## Install

    dub add betacalendars-staticgrid

The package has no external runtime dependencies and is published as a DUB
source library.

## Compile-time grid

    import betacalendars.staticgrid;

    alias January2027 = StaticMonth!(2027, 1, WeekStart.monday);
    enum cells = January2027.cells;
    enum weekends = January2027.weekendMask;

    static assert(January2027.dayCount == 31);
    static assert(January2027.rowCount == 6);
    static assert(weekends.count > 0);

StaticMonth exposes cells, grid, date and row summaries, and compile-time
current/previous/next-month and weekday/weekend masks. Choose natural rows with
GridMode.natural.

## Dynamic values

    import betacalendars.staticgrid;

    auto grid = MonthGrid.build(YearMonth(2027, 1), WeekStart.monday);
    foreach (cell; grid.currentMonth)
        assert(cell.relation == MonthRelation.current);

    auto mondayCells = grid.weekday(Weekday.monday);
    auto firstWeek = grid.week(0);

MonthGrid.build stores at most 42 cells inline. Its currentMonth, weekends,
weekday, and week views use fixed-size value storage and do not create GC
arrays. Each view copies its fixed-capacity backing array, trading a bounded
value copy for a lifetime-safe range without allocation.

## Calendar arithmetic and invalid input

The supported proleptic Gregorian year range is 1 through 9999. Use tryMake
for untrusted fields; invalid dates are rejected instead of normalized.
YearMonth.tryShift, tryNextDate, and tryPreviousDate report range-boundary
failures explicitly. A month grid is empty when its required adjacent-month
padding would cross that range; for example, January year 1 with Monday start.

## Blank grids

Blank grids contain only row and column positions; they have no fabricated
date. Compile-time dimensions use StaticBlankGrid!(6, 7). Runtime dimensions
use BlankGrid.build(rows, columns), limited to 1..16 per dimension.

## Tests, examples, and benchmarks

    dub test
    dub run --config=inspect -- --year 2027 --month 1 --week-start monday
    dub run --config=benchmark --build=release

The test suite exhaustively checks every month from 1600 through 2400 and
includes compile-time assertions and boundary/reference-month cases. Benchmarks
are sanity measurements, not comparative performance claims.

## Documentation

See the architecture, compile-time grids, runtime grids, memory layout, masks,
ranges, blank grids, reference months, and safety guides in docs/.

## License

MIT. See LICENSE.
