# Spotify Tracks Analysis

SQL + Power BI analysis of 113,550 Spotify tracks across 114 genres, looking at what actually relates to popularity: danceability, genre, explicit content, and more.

![Dashboard](dashboard.png)

## What's in this repo
- `spotify_analysis.sql` — full script: database setup, data load (including fixes for a non-UTF8 source file and embedded quote characters), validation checks, and 20 business-question queries
- `Spotify_Theme.json` — the Spotify-branded Power BI theme used in the dashboard

## Key findings
- High-danceability tracks average the highest popularity (~33), suggesting more danceable songs perform slightly better
- Only 9% of all tracks are marked explicit
- About 14% of tracks show zero popularity, likely a data-collection gap rather than genuinely unpopular tracks

## Tools
Excel/Power Query, MySQL, Power BI

(Used Claude AI as a guide while debugging SQL load errors — the analysis and findings are my own work.)
