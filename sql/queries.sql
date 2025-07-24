-- Insert artists data into `artists` table.
WITH distinct_artists (artist_name) AS (
	SELECT DISTINCT artist_name 
	FROM spotify_data 
)
INSERT INTO artists (artist_name)
SELECT da.artist_name
FROM distinct_artists AS da
LEFT JOIN artists AS a 
    ON da.artist_name = a.artist_name
WHERE a.artist_name IS NULL;


-- Populate the sd_artists_join table.
INSERT INTO sd_artists_join (artist_name, sd_id, artist_id)
SELECT
    sd.artist_name
    ,sd.id AS spotify_data_id
    ,a.id AS artist_id
FROM spotify_data as SD
LEFT JOIN artists as A
    ON sd.artist_name = a.artist_name
WHERE a.id IS NOT NULL;


-- Add seasonal data to records
UPDATE spotify_data
SET season = CASE
    WHEN (EXTRACT(MONTH FROM timestamp_column) = 12 AND EXTRACT(DAY FROM timestamp_column) >= 21)
      OR (EXTRACT(MONTH FROM timestamp_column) IN (1, 2))
      OR (EXTRACT(MONTH FROM timestamp_column) = 3 AND EXTRACT(DAY FROM timestamp_column) <= 19)
        THEN 'Winter'
    WHEN (EXTRACT(MONTH FROM timestamp_column) = 3 AND EXTRACT(DAY FROM timestamp_column) >= 20)
      OR (EXTRACT(MONTH FROM timestamp_column) IN (4, 5))
      OR (EXTRACT(MONTH FROM timestamp_column) = 6 AND EXTRACT(DAY FROM timestamp_column) <= 20)
        THEN 'Spring'
    WHEN (EXTRACT(MONTH FROM timestamp_column) = 6 AND EXTRACT(DAY FROM timestamp_column) >= 21)
      OR (EXTRACT(MONTH FROM timestamp_column) IN (7, 8))
      OR (EXTRACT(MONTH FROM timestamp_column) = 9 AND EXTRACT(DAY FROM timestamp_column) <= 22)
        THEN 'Summer'
    WHEN (EXTRACT(MONTH FROM timestamp_column) = 9 AND EXTRACT(DAY FROM timestamp_column) >= 23)
      OR (EXTRACT(MONTH FROM timestamp_column) IN (10, 11))
      OR (EXTRACT(MONTH FROM timestamp_column) = 12 AND EXTRACT(DAY FROM timestamp_column) <= 20)
        THEN 'Fall'
    ELSE 'Unknown'
END;


-- Populate year_played column
UPDATE spotify_data
SET year_played = EXTRACT(YEAR FROM timestamp_column)::INTEGER;


-- Alter `spotify_data` table to add in a time of day column.
-- The `postgres_setup.sql` file creates this column out-of-the-box.
-- We share details here for illustrative purposes.
-- ALTER TABLE spotify_data
-- ADD COLUMN time_of_day TEXT;

-- Add time of day label to our tracks
UPDATE spotify_data
SET time_of_day = CASE
  WHEN EXTRACT(HOUR FROM timestamp_column) BETWEEN 5 AND 11 THEN 'morning'
  WHEN EXTRACT(HOUR FROM timestamp_column) BETWEEN 12 AND 17 THEN 'afternoon'
  WHEN EXTRACT(HOUR FROM timestamp_column) BETWEEN 18 AND 22 THEN 'evening'
  ELSE 'night'
END;


---------------------
-- Create Temp Tables
---------------------

-- Create temp_most_played_tracks
CREATE TABLE temp_most_played_tracks AS (
	WITH track_count_cte AS 
		(
			SELECT 
				COUNT(timestamp_column) AS track_count
				,artist_name
				,track_name
				,album_name
				,spotify_track_uri
				,DATE_PART('year', timestamp_column) AS stream_year
			FROM spotify_data
			WHERE 
				ms_played > 5000
				AND artist_name IS NOT NULL
			GROUP BY 
			artist_name
			,track_name
			,album_name
			,spotify_track_uri
			,stream_year
		),
	tracks_and_genres AS
		(
			SELECT
				tce.stream_year
				,SUM(tce.track_count) AS times_played
				,RANK() OVER
				(
					PARTITION BY tce.stream_year
					ORDER BY SUM(tce.track_count) DESC
				) AS ranking
				,tce.artist_name
				,tce.track_name
				,a.genres AS genres
	
			FROM 
				track_count_cte AS tce
			LEFT JOIN 
				artists AS a 
			ON 
				tce.artist_name = a.artist_name
			GROUP BY 
				tce.artist_name
				,tce.track_name
				,tce.stream_year
				,a.genres
			ORDER BY 
				tce.stream_year
				,RANK() OVER
				(
					PARTITION BY tce.stream_year
					ORDER BY SUM(tce.track_count) DESC
				)
		)
	SELECT * 
	FROM tracks_and_genres
	WHERE ranking = 1
);


-- Create temp_lonngest_listening_days
CREATE TABLE temp_longest_listening_days AS (
	WITH daily_playtime AS (
		SELECT
			DATE_TRUNC('day', timestamp_column) AS calendar_day
			,DATE_PART('year', timestamp_column) AS year
			,ROUND(SUM(ms_played) / 3600000.0, 2) AS hours_played
		FROM spotify_data
		GROUP BY 
			year
			,calendar_day
	)
	,highest_days AS (
		SELECT
			calendar_day
			,year
		FROM (
			SELECT 
				calendar_day
				,year
				,hours_played
				,RANK() OVER (PARTITION BY year ORDER BY hours_played DESC) AS rank
			FROM daily_playtime
		) ranked
		WHERE rank = 1
	)
	SELECT
		hd.calendar_day
		,sd.timestamp_column
		,sd.platform
		,sd.ip_addr
		,sd.ms_played
		,sd.track_name
		,sd.artist_name
		,sd.spotify_track_uri
	FROM highest_days AS hd
	JOIN spotify_data AS sd
		ON DATE_TRUNC('day', sd.timestamp_column) = hd.calendar_day
	ORDER BY 
		hd.calendar_day
		,sd.timestamp_column DESC
);


-- Create temp_genre_track_avg_playtime
CREATE TABLE temp_genre_track_avg_playtime AS (
	WITH artist_playtime AS (
		SELECT a.artist_name
			,a.genres
			,sd.ms_played
			,DATE_PART('year', sd.timestamp_column) AS stream_year
		FROM artists AS a
		JOIN sd_artists_join AS sdj 
			ON a.id = sdj.artist_id
		JOIN spotify_data AS sd 
			ON sdj.sd_id = sd.id
	),
	genre_avg AS (
		SELECT
			stream_year
			,UNNEST(genres) AS genre
			,ROUND((CAST(AVG(ms_played) AS numeric)  / 60000) , 2) AS avg_mins_played
		FROM artist_playtime
		GROUP BY stream_year, genre
	)
	SELECT *
	FROM 
		genre_avg
	ORDER BY 
		stream_year
		,avg_mins_played DESC
)

------------------------
-- Data Cleaning Queries
------------------------

-- Check for NULLs in important columns in `spotify_data`
SELECT
    COUNT(*) FILTER (WHERE timestamp_column IS NULL) AS null_timestamps,
    COUNT(*) FILTER (WHERE ms_played IS NULL) AS null_ms_played,
    COUNT(*) FILTER (WHERE track_name IS NULL) AS null_track_names,
    COUNT(*) FILTER (WHERE artist_name IS NULL) AS null_artist_names,
    COUNT(*) FILTER (WHERE platform IS NULL) AS null_platforms,
    COUNT(*) FILTER (WHERE ip_addr IS NULL) AS null_ips
FROM spotify_data;


-- Check for empty strings
SELECT COUNT(*) FROM spotify_data WHERE track_name = '' OR track_name ~ '^\s+$';
SELECT COUNT(*) FROM spotify_data WHERE artist_name = '' OR artist_name ~ '^\s+$';


-- Detecting duplicate records
SELECT
  COUNT(*) AS dup_count
FROM spotify_data
GROUP BY
  timestamp_column,
  artist_name,
  track_name,
  ms_played,
  spotify_track_uri
HAVING COUNT(*) > 1
ORDER BY dup_count DESC;


-- Obtain count of duplicates
SELECT SUM(dup_count - 1) AS total_duplicates
FROM (
  SELECT COUNT(*) AS dup_count
  FROM spotify_data
  GROUP BY
    timestamp_column
    ,artist_name
    ,track_name
    ,ms_played
	,spotify_track_uri
	,ip_addr
  HAVING COUNT(*) > 1
) sub;


-- DELETE duplicate records. Be sure to backup tables prior to destructive actions.
DELETE FROM spotify_data a
USING spotify_data b
WHERE
  a.ctid < b.ctid AND  -- Keep the "first" row
  a.timestamp_column = b.timestamp_column AND
  a.artist_name = b.artist_name AND
  a.track_name = b.track_name AND
  a.spotify_track_uri = b.spotify_track_uri AND
  a.ip_addr = b.ip_addr AND
  a.ms_played = b.ms_played;


-- Check for suspicious values

-- Check for negative playtimes
SELECT * FROM spotify_data WHERE ms_played < 0;

-- Check for elongated playtime
SELECT * FROM spotify_data WHERE ms_played > 36000000; -- 10 hours

-- Check for playtimes in the future
SELECT * FROM spotify_data WHERE timestamp_column > now();


