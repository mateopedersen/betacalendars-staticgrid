# Blank grids

A blank grid is an undated rectangular structure, not a numbered month with
its labels hidden. Each BlankCell contains only a row and a column.

Compile-time example:

    alias Planner = StaticBlankGrid!(6, 7);
    static assert(Planner.cellCount == 42);

Runtime example:

    auto planner = BlankGrid.build(5, 7);
    BlankCell cell;
    assert(planner.tryCell(34, cell));

Rows and columns must each be between 1 and 16 in the runtime descriptor and
compile-time template. The independent [blank calendar reference](https://www.betacalendars.com/blank-calendar)
illustrates the structural use case.
