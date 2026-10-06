# Cell masks

Bits are row-major: bit zero selects cell (0, 0), and bit i selects cell i. A
fixed month uses at most 42 bits of the ulong mask.

currentMonthMask, previousMonthMask, and nextMonthMask partition all active
cells. weekendMask and weekdayMask(day) select dates by their Gregorian
weekday, regardless of the visual week start. contains, count, intersect,
combine, and invertWithinGrid provide focused operations.

Masks are not raw byte encodings and do not promise a serialization format.
