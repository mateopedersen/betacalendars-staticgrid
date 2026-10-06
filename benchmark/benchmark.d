import std.datetime.stopwatch : StopWatch, AutoStart;
import std.stdio : writeln;
import betacalendars.staticgrid;

void main()
{
    enum iterations = 1_000_000;
    ulong checksum;
    auto timer = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        auto grid = MonthGrid.build(YearMonth(1900 + cast(int) (i % 800), cast(int) (i % 12) + 1));
        checksum += grid.currentMonthMask ^ grid.weekendMask ^ grid.cells[0].date.day;
    }
    const elapsed = timer.peek.total!"usecs";
    writeln("runtime builds: ", iterations);
    writeln("elapsed microseconds: ", elapsed);
    writeln("builds/second: ", cast(double) iterations * 1_000_000 / elapsed);
    writeln("checksum: ", checksum);
    writeln("sizeof(CalendarCell): ", CalendarCell.sizeof);
    writeln("sizeof(MonthGrid): ", MonthGrid.sizeof);
}
