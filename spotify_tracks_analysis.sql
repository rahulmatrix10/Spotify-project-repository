-- =========================================================
-- SPOTIFY TRACKS ANALYSIS
-- Rahul Ballidav
-- Dataset: Kaggle Spotify Tracks Dataset
-- Data preparation: Excel / Power Query; analysis: MySQL
-- =========================================================

-- =========================================================
-- SECTION 1: DATABASE + TABLE
-- =========================================================

CREATE DATABASE IF NOT EXISTS spotify_project;
USE spotify_project;

-- WARNING: This removes the previous analysis table each time the script runs.
-- Keep this line for a clean reload; comment it out if you need to preserve existing data.
DROP TABLE IF EXISTS spotify_tracks;

CREATE TABLE spotify_tracks (
    track_id VARCHAR(50),
    artists TEXT,
    album_name TEXT,
    track_name TEXT,
    popularity INT,
    duration_ms INT,
    explicit VARCHAR(10),
    danceability DECIMAL(6,4),
    energy DECIMAL(6,4),
    `key` INT,
    loudness DECIMAL(8,4),
    mode_flag INT,
    speechiness DECIMAL(6,4),
    acousticness DECIMAL(6,4),
    instrumentalness DECIMAL(10,8),
    liveness DECIMAL(6,4),
    valence DECIMAL(6,4),
    tempo DECIMAL(8,3),
    time_signature INT,
    track_genre VARCHAR(50)
);

-- =========================================================
-- SECTION 2: STAGE + LOAD
-- This import path is specific to the MySQL installation on my computer.
-- Change it if the CSV is stored somewhere else. The file is staged as text
-- first so values can be checked before converting numeric columns.
-- latin1 and ESCAPED BY '"' were used for this CSV export's encoding/quotes.
-- =========================================================

DROP TABLE IF EXISTS temp_spotify_check;

CREATE TABLE temp_spotify_check (
    track_id VARCHAR(50),
    artists TEXT,
    album_name TEXT,
    track_name TEXT,
    popularity VARCHAR(20),
    duration_ms VARCHAR(20),
    explicit VARCHAR(10),
    danceability VARCHAR(20),
    energy VARCHAR(20),
    key_col VARCHAR(20),
    loudness VARCHAR(20),
    mode_flag VARCHAR(20),
    speechiness VARCHAR(20),
    acousticness VARCHAR(20),
    instrumentalness VARCHAR(30),
    liveness VARCHAR(20),
    valence VARCHAR(20),
    tempo VARCHAR(20),
    time_signature VARCHAR(20),
    track_genre VARCHAR(50)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/spotify.csv'
INTO TABLE temp_spotify_check
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) AS staged_rows FROM temp_spotify_check;  -- =113550

INSERT INTO spotify_tracks
SELECT
  track_id,
  artists,
  album_name,
  track_name,
  CASE WHEN popularity REGEXP '^[0-9]+$' THEN CAST(popularity AS UNSIGNED) END,
  CASE WHEN duration_ms REGEXP '^[0-9]+$' THEN CAST(duration_ms AS UNSIGNED) END,
  explicit,
  CASE WHEN danceability REGEXP '^[0-9.]+$' THEN CAST(danceability AS DECIMAL(6,4)) END,
  CASE WHEN energy REGEXP '^[0-9.]+$' THEN CAST(energy AS DECIMAL(6,4)) END,
  CASE WHEN key_col REGEXP '^[0-9]+$' THEN CAST(key_col AS UNSIGNED) END,
  CASE WHEN loudness REGEXP '^-?[0-9.]+$' THEN CAST(loudness AS DECIMAL(8,4)) END,
  CASE WHEN mode_flag REGEXP '^[0-9]+$' THEN CAST(mode_flag AS UNSIGNED) END,
  CASE WHEN speechiness REGEXP '^[0-9.]+$' THEN CAST(speechiness AS DECIMAL(6,4)) END,
  CASE WHEN acousticness REGEXP '^[0-9.]+$' THEN CAST(acousticness AS DECIMAL(6,4)) END,
  CASE WHEN instrumentalness REGEXP '^[0-9.eE-]+$' THEN CAST(instrumentalness AS DECIMAL(10,8)) END,
  CASE WHEN liveness REGEXP '^[0-9.]+$' THEN CAST(liveness AS DECIMAL(6,4)) END,
  CASE WHEN valence REGEXP '^[0-9.]+$' THEN CAST(valence AS DECIMAL(6,4)) END,
  CASE WHEN tempo REGEXP '^[0-9.]+$' THEN CAST(tempo AS DECIMAL(8,3)) END,
  CASE WHEN time_signature REGEXP '^[0-9]+$' THEN CAST(time_signature AS UNSIGNED) END,
  track_genre
FROM temp_spotify_check;

SELECT COUNT(*) AS final_rows FROM spotify_tracks;  -- =113550

DROP TABLE temp_spotify_check;

-- =========================================================
-- SECTION 3: DATA VALIDATION 
-- =========================================================

-- V1. How many distinct genres are actually present?
-- Compare the result with the dataset description; counts can differ by version.
SELECT COUNT(DISTINCT track_genre) AS genre_count FROM spotify_tracks;

-- V2. Any tracks with missing core fields?
SELECT
    SUM(track_id IS NULL OR TRIM(track_id) = '') AS missing_track_id,
    SUM(popularity IS NULL) AS missing_popularity,
    SUM(duration_ms IS NULL) AS missing_duration,
    SUM(track_genre IS NULL OR TRIM(track_genre) = '') AS missing_genre
FROM spotify_tracks;

-- V3. Any duplicate track_id values?
SELECT track_id, COUNT(*) AS occurrences
FROM spotify_tracks
WHERE track_id IS NOT NULL AND TRIM(track_id) <> ''
GROUP BY track_id
HAVING COUNT(*) > 1
LIMIT 10;
-- Note: the same track can legitimately appear once per genre it is
-- tagged with, so duplicate track_id is expected and not an error by
-- itself 

-- V4. Explicit and mode_flag distinct values (confirm they're clean flags)
SELECT explicit, COUNT(*) FROM spotify_tracks GROUP BY explicit;
SELECT mode_flag, COUNT(*) FROM spotify_tracks GROUP BY mode_flag;

-- V5. Range checks on 0-1 scored audio features (should never be <0 or >1)
SELECT
    SUM(danceability < 0 OR danceability > 1) AS bad_danceability,
    SUM(energy < 0 OR energy > 1) AS bad_energy,
    SUM(speechiness < 0 OR speechiness > 1) AS bad_speechiness,
    SUM(acousticness < 0 OR acousticness > 1) AS bad_acousticness,
    SUM(instrumentalness < 0 OR instrumentalness > 1) AS bad_instrumentalness,
    SUM(liveness < 0 OR liveness > 1) AS bad_liveness,
    SUM(valence < 0 OR valence > 1) AS bad_valence
FROM spotify_tracks;

-- V6. Check popularity, duration, key and mode values
SELECT
    SUM(popularity < 0 OR popularity > 100) AS bad_popularity,
    SUM(duration_ms <= 0) AS nonpositive_duration,
    SUM(`key` < 0 OR `key` > 11) AS bad_key,
    SUM(mode_flag NOT IN (0, 1)) AS bad_mode_flag
FROM spotify_tracks;

-- V7. Check explicit values for unexpected labels
SELECT explicit, COUNT(*) AS row_count
FROM spotify_tracks
GROUP BY explicit
ORDER BY row_count DESC;

-- =========================================================
-- SECTION 4: BUSINESS QUESTIONS
-- =========================================================

-- Q1. Top 10 genres by average popularity (minimum 50 tracks, to avoid
-- a tiny/rare genre producing a misleadingly extreme average)
SELECT track_genre, COUNT(*) AS num_tracks, ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
GROUP BY track_genre
HAVING COUNT(*) >= 50
ORDER BY avg_popularity DESC
LIMIT 10;

-- Q2. Bottom 10 genres by average popularity (same minimum-sample rule)
SELECT track_genre, COUNT(*) AS num_tracks, ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
GROUP BY track_genre
HAVING COUNT(*) >= 50
ORDER BY avg_popularity ASC
LIMIT 10;

-- Q3. How does average popularity vary across danceability groups?
SELECT
  CASE WHEN danceability < 0.3 THEN '1. Low (0-0.3)'
       WHEN danceability < 0.6 THEN '2. Medium (0.3-0.6)'
       ELSE '3. High (0.6-1.0)' END AS danceability_band,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE danceability IS NOT NULL
GROUP BY danceability_band
ORDER BY danceability_band;

-- Q4. How does average popularity vary across energy groups?
SELECT
  CASE WHEN energy < 0.3 THEN '1. Low (0-0.3)'
       WHEN energy < 0.6 THEN '2. Medium (0.3-0.6)'
       ELSE '3. High (0.6-1.0)' END AS energy_band,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE energy IS NOT NULL
GROUP BY energy_band
ORDER BY energy_band;

-- Q5. Explicit vs. non-explicit: popularity difference
SELECT explicit, COUNT(*) AS num_tracks, ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
GROUP BY explicit;

-- Q6. Top 15 artists by number of tracks, with their average popularity
-- Note: "artists" can contain multiple collaborating names joined by
-- semicolons, so this groups by the exact combination as credited,
-- not by each individual performer separately.
SELECT artists, COUNT(*) AS num_tracks, ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
GROUP BY artists
ORDER BY num_tracks DESC
LIMIT 15;

-- Q7. Most popular single artist credits (by avg popularity, min 20 tracks)
SELECT artists, COUNT(*) AS num_tracks, ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
GROUP BY artists
HAVING COUNT(*) >= 20
ORDER BY avg_popularity DESC
LIMIT 15;

-- Q8. Major vs. minor key (mode_flag): popularity and mood (valence) difference
-- mode_flag: 1 = major key, 0 = minor key
SELECT mode_flag, COUNT(*) AS num_tracks,
       ROUND(AVG(popularity),2) AS avg_popularity,
       ROUND(AVG(valence),3) AS avg_valence
FROM spotify_tracks
GROUP BY mode_flag;

-- Q9. Top 5 "happiest" genres by average valence (min 50 tracks)
SELECT track_genre, COUNT(*) AS num_tracks, ROUND(AVG(valence),3) AS avg_valence
FROM spotify_tracks
GROUP BY track_genre
HAVING COUNT(*) >= 50
ORDER BY avg_valence DESC
LIMIT 5;

-- Q10. Bottom 5 "saddest" genres by average valence (min 50 tracks)
SELECT track_genre, COUNT(*) AS num_tracks, ROUND(AVG(valence),3) AS avg_valence
FROM spotify_tracks
GROUP BY track_genre
HAVING COUNT(*) >= 50
ORDER BY avg_valence ASC
LIMIT 5;

-- Q11. Track length vs. popularity (streaming-era "shorter songs win" check)
SELECT
  CASE WHEN duration_ms < 180000 THEN '1. Under 3 min'
       WHEN duration_ms < 240000 THEN '2. 3-4 min'
       WHEN duration_ms < 300000 THEN '3. 4-5 min'
       ELSE '4. Over 5 min' END AS length_band,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE duration_ms IS NOT NULL
GROUP BY length_band
ORDER BY length_band;

-- Q12. Acousticness vs. popularity
SELECT
  CASE WHEN acousticness < 0.33 THEN '1. Low acoustic'
       WHEN acousticness < 0.66 THEN '2. Medium acoustic'
       ELSE '3. High acoustic' END AS acoustic_band,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE acousticness IS NOT NULL
GROUP BY acoustic_band
ORDER BY acoustic_band;

-- Q13. Loudness vs. popularity (are louder-mastered tracks more popular?)
SELECT
  CASE WHEN loudness < -15 THEN '1. Very quiet (<-15dB)'
       WHEN loudness < -8 THEN '2. Quiet (-15 to -8dB)'
       WHEN loudness < -4 THEN '3. Moderate (-8 to -4dB)'
       ELSE '4. Loud (-4dB+)' END AS loudness_band,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE loudness IS NOT NULL
GROUP BY loudness_band
ORDER BY loudness_band;

-- Q14. Speechiness: identifying spoken-word/rap-heavy tracks and their popularity
-- Spotify's own guidance: >0.66 mostly spoken word, 0.33-0.66 mixed (often rap), <0.33 music
SELECT
  CASE WHEN speechiness > 0.66 THEN '1. Spoken word'
       WHEN speechiness > 0.33 THEN '2. Mixed (rap-like)'
       ELSE '3. Music' END AS speech_band,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE speechiness IS NOT NULL
GROUP BY speech_band
ORDER BY speech_band;

-- Q15. Liveness: live-performance-flagged tracks vs. studio tracks
-- Spotify's own guidance: >0.8 strong likelihood the track is live
SELECT
  CASE WHEN liveness > 0.8 THEN '1. Likely live recording'
       ELSE '2. Likely studio' END AS live_flag,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE liveness IS NOT NULL
GROUP BY live_flag;

-- Q16. Time signature distribution
SELECT time_signature, COUNT(*) AS num_tracks, ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_tracks
WHERE time_signature IS NOT NULL
GROUP BY time_signature
ORDER BY num_tracks DESC;

-- Q17. Data-quality check: tracks with zero popularity (this does not necessarily mean never played)
SELECT
  COUNT(*) AS zero_popularity_tracks,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM spotify_tracks), 2) AS pct_of_total
FROM spotify_tracks
WHERE popularity = 0;

-- Q18. Tempo bands vs. popularity and energy (do faster songs feel more energetic AND more popular?)
SELECT
  CASE WHEN tempo < 90 THEN '1. Slow (<90 BPM)'
       WHEN tempo < 120 THEN '2. Moderate (90-120 BPM)'
       WHEN tempo < 150 THEN '3. Fast (120-150 BPM)'
       ELSE '4. Very fast (150+ BPM)' END AS tempo_band,
  COUNT(*) AS num_tracks,
  ROUND(AVG(popularity),2) AS avg_popularity,
  ROUND(AVG(energy),3) AS avg_energy
FROM spotify_tracks
WHERE tempo IS NOT NULL
GROUP BY tempo_band
ORDER BY tempo_band;

-- Q19. Genre diversity: how many genres does each top artist appear under?
-- (an artist appearing under many genres may indicate cross-genre appeal
-- or simply that Spotify tagged the same track multiple ways)
SELECT artists, COUNT(DISTINCT track_genre) AS genres_spanned, COUNT(*) AS total_track_rows
FROM spotify_tracks
GROUP BY artists
ORDER BY genres_spanned DESC
LIMIT 15;

-- Q20. Overall summary stats 
SELECT
  COUNT(*) AS total_tracks,
  COUNT(DISTINCT track_genre) AS total_genres,
  COUNT(DISTINCT artists) AS total_artist_credits,
  ROUND(AVG(popularity),2) AS avg_popularity,
  ROUND(AVG(duration_ms)/60000, 2) AS avg_duration_minutes,
  ROUND(SUM(explicit = 'TRUE') * 100.0 / COUNT(*), 2) AS pct_explicit
FROM spotify_tracks;

-- Q21. Top 10 genres by number of tracks in the dataset
SELECT
    track_genre,
    COUNT(*) AS num_tracks,
    ROUND(AVG(popularity), 2) AS avg_popularity
FROM spotify_tracks
GROUP BY track_genre
ORDER BY num_tracks DESC
LIMIT 10;

-- Q22. Tracks with high popularity (80+) and their audio features
SELECT
    track_name,
    artists,
    track_genre,
    popularity,
    ROUND(danceability, 3) AS danceability,
    ROUND(energy, 3) AS energy,
    ROUND(valence, 3) AS valence
FROM spotify_tracks
WHERE popularity >= 80
ORDER BY popularity DESC, track_name
LIMIT 25;

-- =========================================================
-- END OF SCRIPT
-- =========================================================
