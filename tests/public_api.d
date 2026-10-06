import betacalendars.staticgrid;

alias Jan2027 = StaticMonth!(2027, 1, WeekStart.monday);
alias Nov2026 = StaticMonth!(2026, 11, WeekStart.monday);
alias Dec2026 = StaticMonth!(2026, 12, WeekStart.monday);
alias Feb2027 = StaticMonth!(2027, 2, WeekStart.monday);
alias Feb2024 = StaticMonth!(2024, 2, WeekStart.monday);
alias Feb2100 = StaticMonth!(2100, 2, WeekStart.monday);
alias Feb2400 = StaticMonth!(2400, 2, WeekStart.monday);

static assert(Nov2026.dayCount == 30 && Nov2026.firstWeekday == Weekday.sunday);
static assert(Dec2026.dayCount == 31 && Dec2026.firstWeekday == Weekday.tuesday);
static assert(Jan2027.dayCount == 31 && Jan2027.firstWeekday == Weekday.friday);
static assert(Feb2027.dayCount == 28 && Feb2027.firstWeekday == Weekday.monday);
static assert(Feb2024.dayCount == 29 && Feb2100.dayCount == 28 && Feb2400.dayCount == 29);
static assert(StaticMonth!(2027, 2, WeekStart.monday, GridMode.natural).rowCount == 4);
static assert(StaticBlankGrid!(5, 7).cells[34].column == 6);
static assert(StaticMonth!(2026, 11).grid.cells ==
    MonthGrid.build(YearMonth(2026, 11), WeekStart.monday).cells);
static assert(StaticMonth!(2026, 12).grid.cells ==
    MonthGrid.build(YearMonth(2026, 12), WeekStart.monday).cells);
static assert(Jan2027.grid.cells == MonthGrid.build(YearMonth(2027, 1), WeekStart.monday).cells);
static assert(Feb2027.grid.cells ==
    MonthGrid.build(YearMonth(2027, 2), WeekStart.monday).cells);
static assert(Feb2024.grid.cells ==
    MonthGrid.build(YearMonth(2024, 2), WeekStart.monday).cells);
static assert(Feb2100.grid.cells ==
    MonthGrid.build(YearMonth(2100, 2), WeekStart.monday).cells);
static assert(Feb2400.grid.cells ==
    MonthGrid.build(YearMonth(2400, 2), WeekStart.monday).cells);

unittest
{
    foreach (month; [
        YearMonth(2026, 11), YearMonth(2026, 12), YearMonth(2027, 1),
        YearMonth(2027, 2), YearMonth(2024, 2), YearMonth(2100, 2), YearMonth(2400, 2)
    ])
    {
        auto runtime = MonthGrid.build(month, WeekStart.monday);
        assert(runtime.currentMonthMask.count == month.dayCount);
        assert(runtime.rowCount == 6);
    }
    auto february = MonthGrid.build(YearMonth(2027, 2), WeekStart.monday, GridMode.natural);
    assert(february.rowCount == 4 && february.cellCount == 28);
    assert(february.weekdayMask(Weekday.monday).count == 4);
}
