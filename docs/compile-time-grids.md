# Compile-time grids

    alias January2027 = StaticMonth!(2027, 1, WeekStart.monday);
    enum cells = January2027.cells;
    enum weekendCells = January2027.weekendMask;

    static assert(January2027.dayCount == 31);
    static assert(January2027.firstWeekday == Weekday.friday);

The template evaluates the same month builder used by runtime grids. Its
compile-time constants include 42-cell backing storage, active row/cell counts,
weekday summaries, and previous/current/next-month and weekend masks. Natural
mode keeps the fixed backing representation but marks only its natural cells
as active.

Compile-time specialization is useful when those constants feed another
template or static table. For changing dates, prefer the runtime API to avoid
creating needless template instances.

StaticYear!2027 provides month lengths and starting weekdays without embedding
twelve complete grids.
