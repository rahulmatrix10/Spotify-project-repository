# Spotify Tracks Analysis using MySQL

## 📌 Project Overview

This project analyzes a large Spotify tracks dataset using **MySQL**.

The main goal was to clean, validate, and analyze Spotify track data to understand how different audio features and track characteristics are related to popularity.

The project includes data loading, validation, aggregation, filtering, grouping, subqueries, CASE statements, and business-focused analysis.

## 🛠️ Tools Used

* MySQL
* Excel / Power Query
* Kaggle Spotify Tracks Dataset

## 📊 Dataset

The dataset contains Spotify track information such as:

* Track ID
* Artist
* Album
* Track name
* Popularity
* Duration
* Explicit content
* Danceability
* Energy
* Loudness
* Speechiness
* Acousticness
* Instrumentalness
* Liveness
* Valence
* Tempo
* Time signature
* Track genre

The final table contains approximately **113,550 track rows**.

## 🔧 Data Preparation

The data was first cleaned using **Excel / Power Query** and then loaded into MySQL.

For the MySQL import, I used a staging table where numeric columns were initially loaded as text. The values were then validated using `REGEXP` before being converted into their required numeric data types.

This helped avoid import errors caused by inconsistent values in the source file.

## 🔍 Data Validation

The project includes checks for:

* Missing track IDs
* Missing popularity values
* Missing duration values
* Missing genres
* Duplicate track IDs
* Explicit content values
* Major/minor mode values
* Audio feature ranges
* Number of distinct genres
* Zero-popularity tracks
* Invalid numeric values during import

## 📈 Analysis Performed

Some of the business questions analyzed include:

1. Top genres by average popularity
2. Bottom genres by average popularity
3. Danceability vs. popularity
4. Energy vs. popularity
5. Explicit vs. non-explicit tracks
6. Artists with the highest number of tracks
7. Artists with the highest average popularity
8. Major vs. minor tracks
9. Genres with the highest average valence
10. Genres with the lowest average valence
11. Track length vs. popularity
12. Acousticness vs. popularity
13. Loudness vs. popularity
14. Speechiness vs. popularity
15. Live vs. studio recordings
16. Time-signature distribution
17. Zero-popularity tracks
18. Tempo vs. popularity and energy
19. Artist genre diversity
20. Overall dataset summary statistics

## 💡 Key SQL Concepts Used

* `CREATE DATABASE`
* `CREATE TABLE`
* `DROP TABLE`
* `LOAD DATA INFILE`
* `INSERT INTO ... SELECT`
* `CASE`
* `REGEXP`
* `CAST`
* `COUNT`
* `COUNT(DISTINCT)`
* `SUM`
* `AVG`
* `ROUND`
* `GROUP BY`
* `HAVING`
* `ORDER BY`
* `LIMIT`
* Subqueries
* Conditional aggregation

## 📁 Project Structure

```text
spotify-tracks-analysis/
│
├── spotify_tracks_analysis.sql
└── README.md
```

## 🎯 Project Objective

The objective of this project was to practice SQL on a large real-world dataset and answer practical analytical questions using MySQL.

The analysis focuses mainly on understanding **track popularity, genres, artists, and Spotify audio features**.

## Files
spotify_tracks_analysis.sql – Database setup, data import, validation, and analysis queries.

## Conclusion
This project helped me practice SQL on a large dataset and explore relationships between Spotify track characteristics, genres, artists, and popularity. The analysis focuses on identifying patterns in the data rather than assuming that audio features directly cause popularity.


## ⚠️ Note

Popularity and audio-feature comparisons in this project show relationships in the dataset. They should not be interpreted as proof that one feature directly causes a track to become more popular.

### Author
Rahul Ballidav
