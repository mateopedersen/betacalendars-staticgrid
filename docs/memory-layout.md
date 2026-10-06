# Memory layout

The source uses D static arrays and value types rather than GC dynamic arrays.
Measure layout on the target compiler and architecture with:

    dub run --config=benchmark --build=release

The benchmark prints CalendarCell.sizeof and MonthGrid.sizeof using the
compiler's actual target ABI. Field sizes alone do not determine aggregate
size: alignment and padding can add bytes, and sizes can differ across targets.

The public grid stores 42 cells inline; row-major cell masks fit in a 64-bit
ulong. Mask operations are logical integer operations, not serialized memory,
so their meaning is independent of endianness.

CellView and WeekView own fixed-size value copies. They do not allocate or
borrow an array through a pointer, so their lifetime is independent of the
source grid. This bounds storage and avoids dangling references at the cost of
copying the grid's fixed-capacity cells when a view is created.
