import betacalendars.staticgrid;

alias Planner = StaticBlankGrid!(6, 7);
static assert(Planner.cellCount == 42);

void main()
{
    auto blank = BlankGrid.build(Planner.rowCount, Planner.columnCount);
    assert(blank.cellCount == Planner.cellCount);
}
