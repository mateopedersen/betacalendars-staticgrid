# Ranges

grid.currentMonth, grid.weekends, and grid.weekday(day) return input ranges in
chronological order. grid.week(row) provides seven consecutive cells for any
valid displayed row. An invalid row produces an empty view.

Views have fixed-capacity value storage and implement empty, front, popFront,
and length, so they work with D foreach and standard range algorithms. They do
not allocate GC memory; they copy the fixed-size backing cells when
constructed so they remain safe after the source grid goes out of scope.
