import std.stdio : write, writeln;
import std.conv : to;
import betacalendars.staticgrid;

int main(string[] args)
{
    int year = 2027;
    int month = 1;
    WeekStart start = WeekStart.monday;
    size_t argIndex = 1;
    while (argIndex < args.length)
    {
        if (args[argIndex] == "--year" && argIndex + 1 < args.length) { year = to!int(args[argIndex + 1]); argIndex += 2; }
        else if (args[argIndex] == "--month" && argIndex + 1 < args.length) { month = to!int(args[argIndex + 1]); argIndex += 2; }
        else if (args[argIndex] == "--week-start" && argIndex + 1 < args.length)
        {
            const name = args[argIndex + 1];
            if (name == "monday") start = WeekStart.monday;
            else if (name == "tuesday") start = WeekStart.tuesday;
            else if (name == "wednesday") start = WeekStart.wednesday;
            else if (name == "thursday") start = WeekStart.thursday;
            else if (name == "friday") start = WeekStart.friday;
            else if (name == "saturday") start = WeekStart.saturday;
            else if (name == "sunday") start = WeekStart.sunday;
            else { writeln("unknown weekday: ", name); return 2; }
            argIndex += 2;
        }
        else { writeln("usage: --year YEAR --month MONTH --week-start monday|...|sunday"); return 2; }
    }
    auto grid = MonthGrid.build(YearMonth(year, month), start);
    if (grid.cellCount == 0) { writeln("invalid year, month, or week start"); return 2; }
    static immutable string[7] labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    foreach (i; 0 .. 7) write(labels[(cast(size_t) start + i) % 7], i == 6 ? "\n" : " ");
    foreach (i; 0 .. grid.cellCount)
    {
        if (i % 7 == 0) write(grid.cells[i].row == 0 ? "" : "\n");
        if (grid.cells[i].relation != MonthRelation.current) write("   ");
        else
        {
            auto day = to!string(grid.cells[i].date.day);
            if (day.length == 1) write(" ");
            write(day, " ");
        }
    }
    writeln("\nrows=", grid.rowCount, " fingerprint=", fingerprint(grid).value,
        " current-mask=0x", grid.currentMonthMask.to!string(16));
    return 0;
}
