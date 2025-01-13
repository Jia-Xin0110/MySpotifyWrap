SELECT * FROM StreamingHistory
ORDER BY FORMAT(endTime, 'HH:mm:ss')
GO

ALTER TABLE StreamingHistory DROP COLUMN timePlayed;
GO

-- Find TOP 20 Track Most Played
CREATE VIEW TOP20_Track AS
SELECT TOP 20 trackName, artistName, CONVERT(varchar, DATEADD(S, SUM(secondsPlayed), 0), 108)  AS totalTimePlayed, --108 is a datestyle- hh:mm:ss, 114 added with milliseconds
COUNT(trackName) AS CountPlayed
FROM StreamingHistory
GROUP BY trackName, artistName
ORDER BY COUNT(trackName) DESC
GO


--DROP FUNCTION dbo.Converttohhmmss
-- GO

CREATE FUNCTION dbo.Converttohhmmss
(
    @time decimal(28,3), 
    @unit varchar(20)
)
returns varchar(20)
as
begin

    declare @seconds decimal(18,3), @minutes int, @hours int;

    if(@unit = 'hour' or @unit = 'hh' )
        set @seconds = @time * 60 * 60;
    else if(@unit = 'minute' or @unit = 'mi' or @unit = 'n')
        set @seconds = @time * 60;
    else if(@unit = 'second' or @unit = 'ss' or @unit = 's')
        set @seconds = @time;
    else set @seconds = 0; -- unknown time units

    set @hours = convert(int, @seconds /60 / 60);
    set @minutes = convert(int, (@seconds / 60) - (@hours * 60 ));
    set @seconds = @seconds % 60;

    return 
        convert(varchar(9), convert(int, @hours)) + ':' +
        right('00' + convert(varchar(2), convert(int, @minutes)), 2) + ':' +
        right('00' + convert(varchar(6), @seconds), 2)

end

-- Total listening Time
SELECT dbo.Converttohhmmss(SUM(SecondsPlayed), 's') AS TotalListeningTime
FROM StreamingHistory
GO

-- Identify music habits each month
-- Truncate endtime until month only, then return only month and year
CREATE VIEW musicHabit AS
SELECT CONCAT(DATENAME(month, DATETRUNC(month, endTime)), ' ', DATENAME(year, DATETRUNC(month, endTime))) AS YearMonth, dbo.Converttohhmmss(SUM(SecondsPlayed), 's') AS TotalListeningTime
FROM StreamingHistory
GROUP BY DATETRUNC(month, endTime)
GO

SELECT * FROM musicHabit ORDER BY CAST(YearMonth AS datetime)

-- Top Artist
-- Don't sort using Converttohhmmss since it is  nvarchar tyep data
CREATE VIEW TopArtist AS
SELECT TOP 20 artistName, dbo.Converttohhmmss(SUM(SecondsPlayed), 's') AS TotalListeningTime
FROM StreamingHistory
GROUP BY artistName
ORDER BY SUM(SecondsPlayed) DESC

-- Top Artist in each month
-- WITH create a temporary result set
-- ROW_NUMBER() Assigns a row number (rank) to each artist within each month based on their listening time in descending order.
-- PARTITION BY clause ensures ranking is reset for each month.
CREATE VIEW TopArtist_month AS
WITH RankedArtist AS (
	SELECT artistName, SUM(SecondsPlayed) AS TotalListeningTime, FORMAT(endTime, 'yyyy-MM') AS Month,  ROW_NUMBER() OVER (PARTITION BY FORMAT(endTime, 'yyyy-MM') ORDER BY SUM(SecondsPlayed) DESC) AS Rank
	FROM StreamingHistory
	GROUP BY artistName, FORMAT(endTime, 'yyyy-MM')
)
SELECT 
    Month,
    artistName,
    dbo.Converttohhmmss(TotalListeningTime, 's') AS timePlayed
FROM RankedArtist
WHERE Rank <= 3 AND Month <> '2023-12'
SELECT * FROM TopArtist_month ORDER BY Month

-- testing FORMAT(endTime)
SELECT FORMAT(endTime, 'yyyy-MM') From StreamingHistory
GROUP BY FORMAT(endTime, 'yyyy-MM')
ORDER BY FORMAT(endTime, 'yyyy-MM')
GO


-- Return latest and earliest hour listen to Spotify
-- must add 8 hours since this is a UTC time
WITH AdjustTime AS(
SELECT endTime, DATEADD(HOUR, 8, CAST(endtime AS datetime)) AS timeGMT8, trackName, artistName
FROM StreamingHistory
)
-- must be HH to have 24 hour format since hh will return 12 hour format
SELECT CAST(timeGMT8 AS DATE) AS date, CAST(timeGMT8 AS time) AS time, trackName, artistName
FROM AdjustTime
ORDER BY FORMAT(timeGMT8, 'HH:mm:ss')
GO

--Return latest hour
WITH AdjustTime AS(
SELECT endTime, DATEADD(HOUR, 8, CAST(endtime AS datetime)) AS timeGMT8, trackName, artistName
FROM StreamingHistory
)
SELECT CONVERT(VARCHAR(8), MAX(CAST(timeGMT8 AS TIME)), 108) AS latestHour
FROM AdjustTime
WHERE
CAST(timeGMT8 AS TIME) BETWEEN '00:00:00' AND '05:59:59'


--return earliest hour
WITH AdjustTime AS(
SELECT endTime, DATEADD(HOUR, 8, CAST(endtime AS datetime)) AS timeGMT8, trackName, artistName
FROM StreamingHistory
)
SELECT CONVERT(VARCHAR(8), MIN(CAST(timeGMT8 AS TIME)), 108) AS latestHour
FROM AdjustTime
WHERE
CAST(timeGMT8 AS TIME) BETWEEN '06:00:00' AND '23:59:59'


-- RETURN distinct songs played and their count
SELECT DISTINCT trackName, artistName, COUNT(trackName) AS countPlayed
FROM StreamingHistory
GROUP BY trackName, artistName
ORDER BY trackName

















