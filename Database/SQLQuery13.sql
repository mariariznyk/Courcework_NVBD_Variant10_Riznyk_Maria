SET LANGUAGE English;
SET DATEFIRST 7;

DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dbo.DimDate (
        DateKey, 
        FullDate, 
        Year, 
        Month, 
        MonthName, 
        Quarter, 
        DayOfWeek, 
        DayName, 
        IsWeekend
    )
    SELECT 
        CAST(CONVERT(VARCHAR(8), @StartDate, 112) AS INT),
        @StartDate,
        YEAR(@StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DATEPART(QUARTER, @StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 1 ELSE 0 END;

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END
