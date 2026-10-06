# Runtime grids

    auto grid = MonthGrid.build(YearMonth(2027, 1), WeekStart.monday);
    assert(grid.cellCount == 42);
    assert(grid.currentMonthMask.count == 31);

The builder returns an initialized empty value for invalid year/month or enum
inputs. It also returns an empty grid when adjacent-month padding would cross
the supported civil-year range 1..9999. Valid months use the proleptic
Gregorian calendar. Fixed mode always contains 42 date-bearing cells; natural
mode contains four, five, or six full weeks.

Use tryMake to validate arbitrary date fields and YearMonth.tryShift or date
step helpers when crossing the documented supported-year boundaries.
