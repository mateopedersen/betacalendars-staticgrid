import betacalendars.staticgrid;

@safe pure nothrow @nogc
MonthGrid makeJanuary()
{
    return MonthGrid.build(YearMonth(2027, 1), WeekStart.monday);
}

void main()
{
    auto grid = makeJanuary();
    assert(grid.currentMonthMask.count == 31);
}
