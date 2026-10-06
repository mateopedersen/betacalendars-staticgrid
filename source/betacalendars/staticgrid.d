/**
 * BetaCalendars StaticGrid provides deterministic Gregorian civil dates and
 * fixed-capacity month topology designed for CTFE and allocation-free use.
 *
 * The module does not read the system clock, use time zones, or allocate while
 * building a grid. MonthGrid is the dynamic-value API; StaticMonth makes the
 * same topology available as compile-time constants.
 *
 * See_Also: $(LINK https://www.betacalendars.com/),
 * $(LINK https://www.betacalendars.com/blank-calendar)
 */
module betacalendars.staticgrid;

/// Monday-first numeric weekday order, used internally and by masks.
enum Weekday : ubyte
{
    monday = 0, tuesday, wednesday, thursday, friday, saturday, sunday
}

/// First weekday of a displayed week.
alias WeekStart = Weekday;

/// Month topology policy.
enum GridMode : ubyte
{
    /// Smallest number of complete weeks that contains the month.
    natural,
    /// Exactly six rows (42 cells), with adjacent-month dates as needed.
    fixedSixWeeks
}

/// Relationship of a date to the requested month.
enum MonthRelation : ubyte { previous, current, next }

/// Gregorian civil date. Use tryMake to validate external numeric input.
struct CivilDate
{
    int year;
    ubyte month;
    ubyte day;

    /// Returns whether this value is a valid date in years 1 through 9999.
    bool isValid() const @safe pure nothrow @nogc
    {
        return year >= 1 && year <= 9999 && month >= 1 && month <= 12 &&
            day >= 1 && day <= daysInMonth(year, month);
    }
}

/// Constructs a valid civil date, returning false instead of normalizing bad input.
bool tryMake(out CivilDate result, int year, int month, int day)
    @safe pure nothrow @nogc
{
    result = CivilDate.init;
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1 ||
        day > daysInMonth(year, cast(ubyte) month))
        return false;
    result = CivilDate(year, cast(ubyte) month, cast(ubyte) day);
    return true;
}

/// Gregorian leap-year rule.
bool isLeapYear(int year) @safe pure nothrow @nogc
{
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

/// Number of days in a Gregorian month, or zero when year/month is invalid.
ubyte daysInMonth(int year, ubyte month) @safe pure nothrow @nogc
{
    if (year < 1 || year > 9999 || month < 1 || month > 12) return 0;
    final switch (month)
    {
        case 1, 3, 5, 7, 8, 10, 12: return 31;
        case 4, 6, 9, 11: return 30;
        case 2: return isLeapYear(year) ? 29 : 28;
    }
}

/// Day number within the year, from 1 through 365 or 366; zero if invalid.
ushort ordinalDay(CivilDate date) @safe pure nothrow @nogc
{
    if (!date.isValid) return 0;
    ushort result = date.day;
    foreach (m; 1 .. date.month)
        result += daysInMonth(date.year, cast(ubyte) m);
    return result;
}

/// Returns the ISO-style Monday=0 weekday of a valid date.
///
/// The arithmetic uses the proleptic Gregorian calendar and has no dependency
/// on locale, time zone, operating-system services, or the current date.
Weekday dayOfWeek(CivilDate date) @safe pure nothrow @nogc
{
    static immutable ubyte[12] offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];
    if (!date.isValid) return Weekday.monday;
    int y = date.year;
    if (date.month < 3) --y;
    const sundayZero = (y + y / 4 - y / 100 + y / 400 +
        offsets[date.month - 1] + date.day) % 7;
    return cast(Weekday) ((sundayZero + 6) % 7);
}

/// Advances a valid date by one day. Returns false at 9999-12-31 or for invalid input.
bool tryNextDate(ref CivilDate date) @safe pure nothrow @nogc
{
    if (!date.isValid) return false;
    if (date.day < daysInMonth(date.year, date.month))
        ++date.day;
    else if (date.month < 12)
    {
        ++date.month;
        date.day = 1;
    }
    else if (date.year < 9999)
    {
        ++date.year;
        date.month = 1;
        date.day = 1;
    }
    else return false;
    return true;
}

/// Moves a valid date back one day. Returns false at 0001-01-01 or for invalid input.
bool tryPreviousDate(ref CivilDate date) @safe pure nothrow @nogc
{
    if (!date.isValid) return false;
    if (date.day > 1)
        --date.day;
    else if (date.month > 1)
    {
        --date.month;
        date.day = daysInMonth(date.year, date.month);
    }
    else if (date.year > 1)
    {
        --date.year;
        date.month = 12;
        date.day = 31;
    }
    else return false;
    return true;
}

/// Year and month with explicit validation and date-boundary helpers.
struct YearMonth
{
    int year;
    ubyte month;

    /// Creates a value. Invalid values remain detectable with isValid.
    this(int year, int month) @safe pure nothrow @nogc
    {
        this.year = year;
        this.month = (month >= 0 && month <= 255) ? cast(ubyte) month : 0;
    }

    /// True for years 1..9999 and months 1..12.
    bool isValid() const @safe pure nothrow @nogc
    {
        return year >= 1 && year <= 9999 && month >= 1 && month <= 12;
    }

    /// Days in this month, or zero when invalid.
    ubyte dayCount() const @safe pure nothrow @nogc
    {
        return isValid ? daysInMonth(year, month) : 0;
    }

    /// First date of this month, or CivilDate.init when invalid.
    CivilDate firstDay() const @safe pure nothrow @nogc
    {
        return isValid ? CivilDate(year, month, 1) : CivilDate.init;
    }

    /// Last date of this month, or CivilDate.init when invalid.
    CivilDate lastDay() const @safe pure nothrow @nogc
    {
        return isValid ? CivilDate(year, month, dayCount) : CivilDate.init;
    }

    /// Adds months into result; false when invalid or outside years 1..9999.
    bool tryShift(int amount, out YearMonth result) const @safe pure nothrow @nogc
    {
        result = YearMonth.init;
        if (!isValid) return false;
        const long index = cast(long) year * 12 + month - 1 + amount;
        const long y = index / 12;
        const long m = index % 12;
        if (y < 1 || y > 9999 || m < 0) return false;
        result = YearMonth(cast(int) y, cast(int) m + 1);
        return true;
    }

    /// Returns the following month in result; false at the supported upper bound.
    bool next(out YearMonth result) const @safe pure nothrow @nogc
    { return tryShift(1, result); }

    /// Returns the preceding month in result; false at the supported lower bound.
    bool previous(out YearMonth result) const @safe pure nothrow @nogc
    { return tryShift(-1, result); }

    version (D_BetterC) {}
    else
    {
        /// ISO-like year-month representation; empty for an invalid value.
        string toString() const
        {
            if (!isValid) return "";
            import std.format : format;
            return format("%04d-%02d", year, month);
        }
    }

    /// Lexicographic chronological comparison.
    int opCmp(const YearMonth rhs) const @safe pure nothrow @nogc
    {
        if (year != rhs.year) return year < rhs.year ? -1 : 1;
        if (month != rhs.month) return month < rhs.month ? -1 : 1;
        return 0;
    }
}

/// One date-bearing cell in a month grid.
struct CalendarCell
{
    CivilDate date;
    ubyte row;
    ubyte column;
    MonthRelation relation;

    /// Weekday represented by the date in this cell.
    Weekday weekday() const @safe pure nothrow @nogc { return dayOfWeek(date); }
}

/// A 64-bit calendar-specific mask; bits 0..41 correspond to row-major cells.
alias CellMask = ulong;

/// Returns true if a valid cell index is selected.
bool contains(CellMask mask, size_t index) @safe pure nothrow @nogc
{
    return index < 64 && (mask & (1UL << index)) != 0;
}

/// Counts selected cells.
size_t count(CellMask mask) @safe pure nothrow @nogc
{
    size_t n;
    while (mask != 0) { mask &= mask - 1; ++n; }
    return n;
}

/// Intersects two masks.
CellMask intersect(CellMask a, CellMask b) @safe pure nothrow @nogc { return a & b; }
/// Combines two masks.
CellMask combine(CellMask a, CellMask b) @safe pure nothrow @nogc { return a | b; }

/// Complements a mask within the first cellCount logical cells.
CellMask invertWithinGrid(CellMask mask, size_t cellCount) @safe pure nothrow @nogc
{
    if (cellCount == 0) return 0;
    if (cellCount >= 64) return ~mask;
    return (~mask) & ((1UL << cellCount) - 1);
}

private CellMask bit(size_t i) @safe pure nothrow @nogc { return 1UL << i; }

/// Fixed-capacity, allocation-free month grid for dynamic year/month inputs.
struct MonthGrid
{
    /// All fixed-capacity cells; only the first cellCount are active.
    CalendarCell[42] cells;
    /// Number of active cells (28, 35, or 42 in natural mode; 42 fixed).
    ubyte cellCount;
    /// Number of active rows.
    ubyte rowCount;
    /// Requested month, week start, and layout mode.
    YearMonth yearMonth;
    WeekStart weekStart;
    GridMode mode;
    /// Row-major masks with no bits outside active cells.
    CellMask currentMonthMask;
    CellMask previousMonthMask;
    CellMask nextMonthMask;
    CellMask weekendMask;

    /// Builds the requested month. Invalid input, or a grid whose padding
    /// would cross years 1..9999, yields an empty grid.
    static MonthGrid build(YearMonth ym, WeekStart start = WeekStart.monday,
        GridMode mode = GridMode.fixedSixWeeks) @safe pure nothrow @nogc
    {
        MonthGrid result;
        if (!ym.isValid || start > Weekday.sunday || mode > GridMode.fixedSixWeeks)
            return result;
        const first = ym.firstDay;
        const firstWeekday = cast(uint) dayOfWeek(first);
        const leading = (firstWeekday + 7 - cast(uint) start) % 7;
        const days = ym.dayCount;
        result.rowCount = mode == GridMode.fixedSixWeeks ? 6 :
            cast(ubyte) ((leading + days + 6) / 7);
        result.cellCount = cast(ubyte) (result.rowCount * 7);
        CivilDate cursor = first;
        foreach (_; 0 .. leading)
            if (!tryPreviousDate(cursor)) return MonthGrid.init;
        const trailing = result.cellCount - leading - days;
        CivilDate last = ym.lastDay;
        foreach (_; 0 .. trailing)
            if (!tryNextDate(last)) return MonthGrid.init;

        result.yearMonth = ym;
        result.weekStart = start;
        result.mode = mode;
        foreach (i; 0 .. result.cellCount)
        {
            auto relation = cursor.year == ym.year && cursor.month == ym.month ?
                MonthRelation.current :
                (cursor.year < ym.year || (cursor.year == ym.year && cursor.month < ym.month)) ?
                    MonthRelation.previous : MonthRelation.next;
            result.cells[i] = CalendarCell(cursor, cast(ubyte) (i / 7),
                cast(ubyte) (i % 7), relation);
            if (relation == MonthRelation.current) result.currentMonthMask |= bit(i);
            else if (relation == MonthRelation.previous) result.previousMonthMask |= bit(i);
            else result.nextMonthMask |= bit(i);
            const wd = dayOfWeek(cursor);
            if (wd == Weekday.saturday || wd == Weekday.sunday)
                result.weekendMask |= bit(i);
            if (i + 1 < result.cellCount && !tryNextDate(cursor))
                return MonthGrid.init;
        }
        return result;
    }

    /// Logical active-cell mask.
    CellMask activeMask() const @safe pure nothrow @nogc
    {
        return cellCount == 0 ? 0 : (1UL << cellCount) - 1;
    }

    /// Mask for all seven cells in the first active row.
    CellMask firstWeekMask() const @safe pure nothrow @nogc
    { return rowCount == 0 ? 0 : 0x7fUL; }

    /// Mask for all seven cells in the last active row.
    CellMask lastWeekMask() const @safe pure nothrow @nogc
    { return rowCount == 0 ? 0 : 0x7fUL << ((rowCount - 1) * 7); }

    /// Mask for the first date in the requested month.
    CellMask monthStartMask() const @safe pure nothrow @nogc
    {
        foreach (i; 0 .. cellCount)
            if (cells[i].relation == MonthRelation.current && cells[i].date.day == 1)
                return bit(i);
        return 0;
    }

    /// Mask for the last date in the requested month.
    CellMask monthEndMask() const @safe pure nothrow @nogc
    {
        foreach (i; 0 .. cellCount)
            if (cells[i].relation == MonthRelation.current && cells[i].date.day == yearMonth.dayCount)
                return bit(i);
        return 0;
    }

    /// First date in the requested month.
    CivilDate firstDay() const @safe pure nothrow @nogc { return yearMonth.firstDay; }
    /// Last date in the requested month.
    CivilDate lastDay() const @safe pure nothrow @nogc { return yearMonth.lastDay; }

    /// Mask selecting the specified weekday in the grid.
    CellMask weekdayMask(Weekday weekday) const @safe pure nothrow @nogc
    {
        CellMask result;
        if (weekday > Weekday.sunday) return result;
        foreach (i; 0 .. cellCount)
            if (dayOfWeek(cells[i].date) == weekday) result |= bit(i);
        return result;
    }

    /// Returns a seven-cell fixed row; invalid row indexes produce an empty view.
    WeekView week(size_t row) const @safe pure nothrow @nogc
    {
        WeekView result;
        if (row >= rowCount) return result;
        result.cells = cells;
        result.start = row * 7;
        result.valid = true;
        return result;
    }

    /// A value-owned, allocation-free lazy view over cells selected by mask.
    CellView select(CellMask mask) const @safe pure nothrow @nogc
    {
        return CellView(cells, mask & activeMask());
    }

    /// Current-month cells, in chronological grid order.
    CellView currentMonth() const @safe pure nothrow @nogc { return select(currentMonthMask); }
    /// All active date-bearing cells, in row-major chronological order.
    CellView activeCells() const @safe pure nothrow @nogc { return select(activeMask); }
    /// Weekend cells, in chronological grid order.
    CellView weekends() const @safe pure nothrow @nogc { return select(weekendMask); }
    /// Cells for a selected weekday, in chronological grid order.
    CellView weekday(Weekday day) const @safe pure nothrow @nogc
    {
        return select(weekdayMask(day));
    }
}

/// Input range of selected cells. It owns a fixed-size array copy, never a GC slice.
struct CellView
{
    private CalendarCell[42] storage;
    private CellMask selected;
    private size_t cursor;

    private this(CalendarCell[42] cells, CellMask mask) @safe pure nothrow @nogc
    { storage = cells; selected = mask; }

    private void skip() @safe pure nothrow @nogc
    { while (cursor < 42 && !contains(selected, cursor)) ++cursor; }

    /// True when there is a selected cell to read.
    bool empty() const @safe pure nothrow @nogc
    { size_t c = cursor; while (c < 42 && !contains(selected, c)) ++c; return c >= 42; }
    /// Current selected cell; valid while empty is false.
    const(CalendarCell) front() const @safe pure nothrow @nogc
    { size_t c = cursor; while (c < 42 && !contains(selected, c)) ++c; return storage[c]; }
    /// Advances to the next selected cell.
    void popFront() @safe pure nothrow @nogc
    { skip(); if (cursor < 42) ++cursor; skip(); }
    /// Number of selected cells remaining.
    size_t length() const @safe pure nothrow @nogc
    { size_t c = cursor; size_t n; while (c < 42) { if (contains(selected, c)) ++n; ++c; } return n; }
}

/// Seven-cell fixed row view.
struct WeekView
{
    private CalendarCell[42] cells;
    private size_t start;
    private bool valid;
    private size_t cursor;
    /// True after all seven cells have been consumed or for an invalid row.
    bool empty() const @safe pure nothrow @nogc { return !valid || cursor >= 7; }
    /// Current cell.
    const(CalendarCell) front() const @safe pure nothrow @nogc { return cells[start + cursor]; }
    /// Advance one position.
    void popFront() @safe pure nothrow @nogc { if (cursor < 7) ++cursor; }
    /// Remaining cells.
    size_t length() const @safe pure nothrow @nogc { return valid ? 7 - cursor : 0; }
}

/// Static, compile-time month representation with fixed-capacity cells and masks.
template StaticMonth(int Year, int Month, WeekStart Start = WeekStart.monday,
    GridMode Mode = GridMode.fixedSixWeeks)
{
    static assert(Year >= 1 && Year <= 9999, "StaticMonth year must be 1..9999");
    static assert(Month >= 1 && Month <= 12, "StaticMonth month must be 1..12");
    static assert(Start <= Weekday.sunday, "invalid week start");
    static assert(Mode <= GridMode.fixedSixWeeks, "invalid grid mode");
    struct StaticMonth
    {
        enum int year = Year;
        enum ubyte month = cast(ubyte) Month;
        enum WeekStart weekStart = Start;
        enum GridMode mode = Mode;
        enum ubyte dayCount = daysInMonth(Year, cast(ubyte) Month);
        enum Weekday firstWeekday = dayOfWeek(CivilDate(Year, cast(ubyte) Month, 1));
        enum Weekday lastWeekday = dayOfWeek(CivilDate(Year, cast(ubyte) Month, dayCount));
        enum size_t leadingCellCount =
            (cast(uint) firstWeekday + 7 - cast(uint) Start) % 7;
        enum ubyte rowCount = Mode == GridMode.fixedSixWeeks ? 6 :
            cast(ubyte) ((leadingCellCount + dayCount + 6) / 7);
        enum ubyte activeCellCount = rowCount * 7;
        enum MonthGrid grid = MonthGrid.build(YearMonth(Year, Month), Start, Mode);
        static assert(grid.cellCount != 0,
            "StaticMonth layout crosses the supported year range 1..9999");
        enum CalendarCell[42] cells = grid.cells;
        enum CellMask currentMonthMask = grid.currentMonthMask;
        enum CellMask previousMonthMask = grid.previousMonthMask;
        enum CellMask nextMonthMask = grid.nextMonthMask;
        enum CellMask weekendMask = grid.weekendMask;
        enum CellMask firstWeekMask = grid.firstWeekMask;
        enum CellMask lastWeekMask = grid.lastWeekMask;
        enum CellMask monthStartMask = grid.monthStartMask;
        enum CellMask monthEndMask = grid.monthEndMask;
        enum CellMask[7] weekdayMasks = [
            grid.weekdayMask(Weekday.monday), grid.weekdayMask(Weekday.tuesday),
            grid.weekdayMask(Weekday.wednesday), grid.weekdayMask(Weekday.thursday),
            grid.weekdayMask(Weekday.friday), grid.weekdayMask(Weekday.saturday),
            grid.weekdayMask(Weekday.sunday)
        ];
        enum CellMask currentMonth = currentMonthMask;
        enum CellMask weekends = weekendMask;

        /// Mask selecting a weekday; computed entirely during CTFE.
        static CellMask weekdayMask(Weekday day)() @safe pure nothrow @nogc
        { return grid.weekdayMask(day); }
    }
}

/// Undated structural cell; blank grids do not invent a month or date.
struct BlankCell
{
    ubyte row;
    ubyte column;
}

/// Compile-time blank rectangular grid dimensions.
template StaticBlankGrid(size_t Rows, size_t Columns = 7)
{
    static assert(Rows > 0 && Rows <= 16, "Rows must be in 1..16");
    static assert(Columns > 0 && Columns <= 16, "Columns must be in 1..16");
    struct StaticBlankGrid
    {
        enum size_t rowCount = Rows;
        enum size_t columnCount = Columns;
        enum size_t cellCount = Rows * Columns;
        enum BlankCell[cellCount] cells = makeCells();
        private static BlankCell[cellCount] makeCells() @safe pure nothrow @nogc
        {
            BlankCell[cellCount] result;
            foreach (i; 0 .. cellCount)
                result[i] = BlankCell(cast(ubyte) (i / Columns), cast(ubyte) (i % Columns));
            return result;
        }
    }
}

/// Runtime-sized blank grid descriptor (dimensions capped at 16×16).
struct BlankGrid
{
    ubyte rowCount;
    ubyte columnCount;
    /// Creates a dimension descriptor; invalid dimensions become zero.
    static BlankGrid build(size_t rows, size_t columns = 7) @safe pure nothrow @nogc
    {
        if (rows == 0 || rows > 16 || columns == 0 || columns > 16) return BlankGrid.init;
        return BlankGrid(cast(ubyte) rows, cast(ubyte) columns);
    }
    /// Number of structural positions.
    size_t cellCount() const @safe pure nothrow @nogc
    { return cast(size_t) rowCount * columnCount; }
    /// Maps an in-range row-major index to a structural blank cell.
    bool tryCell(size_t index, out BlankCell result) const @safe pure nothrow @nogc
    {
        result = BlankCell.init;
        if (columnCount == 0 || index >= cellCount) return false;
        result = BlankCell(cast(ubyte) (index / columnCount), cast(ubyte) (index % columnCount));
        return true;
    }
}

/// Compact structural key for comparing month layouts; not cryptographic.
struct CalendarFingerprint
{
    ubyte firstWeekday;
    ubyte dayCount;
    ubyte weekStart;
    ubyte rowCount;
    GridMode mode;

    /// Returns a documented compact integer encoding of the fields.
    ulong value() const @safe pure nothrow @nogc
    {
        return cast(ulong) firstWeekday | (cast(ulong) dayCount << 3) |
            (cast(ulong) weekStart << 9) | (cast(ulong) rowCount << 12) |
            (cast(ulong) mode << 16);
    }
}

/// Fingerprint of a valid month grid; invalid grids return the zero fingerprint.
CalendarFingerprint fingerprint(MonthGrid grid) @safe pure nothrow @nogc
{
    if (grid.cellCount == 0) return CalendarFingerprint.init;
    return CalendarFingerprint(cast(ubyte) dayOfWeek(grid.yearMonth.firstDay),
        grid.yearMonth.dayCount, cast(ubyte) grid.weekStart, grid.rowCount, grid.mode);
}

/// True when two grids have equivalent date-position topology, ignoring year/month labels.
bool sameTopology(MonthGrid a, MonthGrid b) @safe pure nothrow @nogc
{
    return fingerprint(a).value == fingerprint(b).value;
}

/// Compile-time year summary without embedding twelve grids.
template StaticYear(int Year, WeekStart Start = WeekStart.monday)
{
    static assert(Year >= 1 && Year <= 9999, "StaticYear year must be 1..9999");
    static assert(Start <= Weekday.sunday, "invalid week start");
    struct StaticYear
    {
        enum int year = Year;
        enum WeekStart weekStart = Start;
        enum bool leap = isLeapYear(Year);
        enum ubyte[12] monthLengths = makeLengths();
        enum Weekday[12] monthStarts = makeStarts();
        enum ushort totalDays = leap ? 366 : 365;
        private static ubyte[12] makeLengths() @safe pure nothrow @nogc
        { ubyte[12] a; foreach (i; 0 .. 12) a[i] = daysInMonth(Year, cast(ubyte) (i + 1)); return a; }
        private static Weekday[12] makeStarts() @safe pure nothrow @nogc
        { Weekday[12] a; foreach (i; 0 .. 12) a[i] = dayOfWeek(CivilDate(Year, cast(ubyte) (i + 1), 1)); return a; }
    }
}

/// Compile-time structural assertions for core calendar invariants.
static assert(!isLeapYear(1900) && isLeapYear(2000) && isLeapYear(2024));
static assert(!isLeapYear(2027) && !isLeapYear(2100) && isLeapYear(2400));
static assert(daysInMonth(2027, 2) == 28 && daysInMonth(2024, 2) == 29);
static assert(dayOfWeek(CivilDate(2027, 1, 1)) == Weekday.friday);
static assert(StaticMonth!(2027, 1).dayCount == 31);
static assert(StaticMonth!(2027, 2).dayCount == 28);
static assert(StaticMonth!(2024, 2).dayCount == 29);
static assert(StaticMonth!(2027, 1).currentMonthMask.count == 31);
static assert(StaticBlankGrid!(6, 7).cellCount == 42);

unittest
{
    foreach (y; 1600 .. 2401)
        foreach (m; 1 .. 13)
        {
            auto grid = MonthGrid.build(YearMonth(y, m));
            assert(grid.cellCount == 42 && grid.rowCount == 6);
            assert(grid.currentMonthMask.count == daysInMonth(y, cast(ubyte) m));
            assert((grid.currentMonthMask & grid.previousMonthMask) == 0);
            assert((grid.currentMonthMask & grid.nextMonthMask) == 0);
            assert((grid.previousMonthMask | grid.currentMonthMask | grid.nextMonthMask) == grid.activeMask);
            assert((grid.weekendMask & ~grid.activeMask) == 0);
            assert(grid.monthStartMask.count == 1 && grid.monthEndMask.count == 1);
            assert(grid.firstWeekMask.count == 7 && grid.lastWeekMask.count == 7);
            CellMask weekdayUnion;
            foreach (weekday; 0 .. 7)
            {
                const mask = grid.weekdayMask(cast(Weekday) weekday);
                assert((weekdayUnion & mask) == 0);
                weekdayUnion |= mask;
            }
            assert(weekdayUnion == grid.activeMask);
            assert((grid.weekendMask & grid.weekdayMask(Weekday.saturday)) ==
                grid.weekdayMask(Weekday.saturday));
            auto view = grid.currentMonth;
            ubyte expected = 1;
            foreach (cell; view)
            {
                assert(cell.relation == MonthRelation.current && cell.date.day == expected);
                ++expected;
            }
            assert(expected == daysInMonth(y, cast(ubyte) m) + 1);
            const natural = MonthGrid.build(YearMonth(y, m), WeekStart.monday, GridMode.natural);
            assert(natural.cellCount >= 28 && natural.cellCount <= 42);
            assert(natural.cellCount % 7 == 0);
        }
}

unittest
{
    foreach (ym; [YearMonth(2026, 11), YearMonth(2026, 12), YearMonth(2027, 1),
        YearMonth(2027, 2), YearMonth(2024, 2), YearMonth(2100, 2), YearMonth(2400, 2)])
    {
        auto runtime = MonthGrid.build(ym);
        assert(runtime.currentMonthMask.count == ym.dayCount);
        assert(runtime.firstDay().day == 1);
        assert(runtime.lastDay().day == ym.dayCount);
    }
    auto jan = MonthGrid.build(YearMonth(2027, 1));
    auto other = MonthGrid.build(YearMonth(2016, 1));
    assert(sameTopology(jan, other));
    assert(MonthGrid.build(YearMonth(2027, 1)).cells[0].date == CivilDate(2026, 12, 28));
    assert(MonthGrid.build(YearMonth(2027, 1), WeekStart.sunday).rowCount == 6);
    assert(MonthGrid.build(YearMonth(1, 1), WeekStart.monday).cellCount == 42);
    assert(MonthGrid.build(YearMonth(1, 1), WeekStart.tuesday).cellCount == 0);
    assert(MonthGrid.build(YearMonth(9999, 12), WeekStart.sunday).cellCount == 0);
}

unittest
{
    CivilDate date;
    assert(tryMake(date, 2000, 2, 29) && date.isValid);
    assert(!tryMake(date, 1900, 2, 29));
    assert(!tryMake(date, 2027, 13, 1));
    assert(daysInMonth(2027, 0) == 0 && daysInMonth(2027, 13) == 0);
    auto ym = YearMonth(2026, 12);
    YearMonth next;
    assert(ym.tryShift(1, next) && next == YearMonth(2027, 1));
    assert(ym.next(next) && next == YearMonth(2027, 1));
    assert(next.previous(ym) && ym == YearMonth(2026, 12));
    assert(YearMonth(2027, 1).toString == "2027-01");
    auto cursor = CivilDate(2026, 12, 31);
    assert(tryNextDate(cursor) && cursor == CivilDate(2027, 1, 1));
    assert(tryPreviousDate(cursor) && cursor == CivilDate(2026, 12, 31));
    assert(ordinalDay(CivilDate(2024, 12, 31)) == 366);
}

unittest
{
    auto grid = MonthGrid.build(YearMonth(2027, 1));
    foreach (row; 0 .. grid.rowCount)
    {
        auto week = grid.week(row);
        assert(week.length == 7);
        size_t seen;
        while (!week.empty) { ++seen; week.popFront(); }
        assert(seen == 7);
    }
    assert(grid.week(6).empty);
    assert(grid.weekdayMask(Weekday.monday).count == 6);
    assert(grid.activeCells.length == 42);
    assert(StaticYear!2027.monthLengths[1] == 28);
    assert(StaticMonth!(2027, 1).monthStartMask.count == 1);
    assert(StaticMonth!(2027, 1).monthEndMask.count == 1);
    assert(BlankGrid.build(6, 7).cellCount == 42);
    BlankCell blank;
    assert(BlankGrid.build(5, 7).tryCell(34, blank) && blank.row == 4 && blank.column == 6);
}
