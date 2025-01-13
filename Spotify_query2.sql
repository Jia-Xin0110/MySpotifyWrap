SELECT * FROM YourLibrary
SELECT * FROM Playlist
SELECT * FROM StreamingHistory


-- Return the proportion streaming songs in playlist and liked songs
SELECT COUNT(Playlist.trackName) AS Count_of_Streaming_of_SongsInPlaylist, 
	CAST(COUNT(StreamingHistory.trackName) AS float)/7808 AS Proportion_over_all_streaming
FROM StreamingHistory
INNER JOIN Playlist ON StreamingHistory.trackName = Playlist.trackName
GO

SELECT COUNT(YourLibrary.trackName) AS Count_of_Streaming_of_LikedSongs, 
	CAST(COUNT(StreamingHistory.trackName) AS float)/7808 AS Proportion_over_all_streaming
FROM StreamingHistory
INNER JOIN YourLibrary ON StreamingHistory.trackName = YourLibrary.trackName
GO

-- Return the latest streaming hour ever and the date, total streaming hours on that day.
With AdjustHours AS
(
	SELECT DATEADD(HOUR, 8, CAST(endTime AS datetime)) AS TimeGMT8, secondsPlayed
	FROM StreamingHistory
)
SELECT TOP 1 CAST(MAX(TimeGMT8) AS time) AS latestHour, CAST(TimeGMT8 AS date) AS date, SUM(secondsPlayed)/60 AS totalStreamingMinutes
FROM AdjustHours
WHERE CAST(timeGMT8 AS TIME) BETWEEN '00:00:00' AND '05:59:59'
GROUP BY CAST(TimeGMT8 AS date)
ORDER BY CAST(MAX(TimeGMT8) AS time) DESC



