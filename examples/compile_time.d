import betacalendars.staticgrid;

alias January2027 = StaticMonth!(2027, 1, WeekStart.monday);
enum staticCells = January2027.cells;

static assert(January2027.firstWeekday == Weekday.friday);
static assert(January2027.dayCount == 31);
static assert(January2027.weekendMask.count > 0);

void main()
{
    assert(staticCells.length == 42);
}
