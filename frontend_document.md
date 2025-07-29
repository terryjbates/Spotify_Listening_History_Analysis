# Frontend: Spotify Listening History Analysis

By: [Terry Bates](https://github.com/terryjbates)
## Overview

This project examines over a decade of personal Spotify listening history data, emphasizing when, how, and what I listened to over time. Using a combination of Python, SQL, and PostgreSQL, I investigated temporal trends, genre evolution, and personal media habits. The work combines structured querying, visualization, and utilized data from [Every Noise at Once](https://everynoise.com) to plot genres within a coordinate system  to derive meaningful insights about listening behavior and provide listening recommendations. The project is built atop the platform of the [Spotify Wrapped question set](https://support.spotify.com/us/article/understanding-my-data/) and unfolds via analytical narrative exploration and personal introspection. 

The notebook integrates both internal data cleaning and exploratory data analysis (EDA) steps, moving from raw JSON exports to final PostgreSQL storage and SQL for data analysis. Key visual outputs highlight daily patterns, genre diversity shifts, listening-time plots, and spatial representations of musical preferences across years.

---

## Project Metadata

- **Role**: Sole Contributor
- **Project Type**: Personal Analytical Study
- **Stack**: Python, Pandas, Plotly, PostgreSQL, SQLAlchemy, Matplotlib
- **Timeline**: ~10 Years of Listening Data | Project conducted in 2025
- **Notebook**: [`notebooks/spotify_analysis.qmd`](notebooks/spotify_analysis.qmd) 
- **Code + Data**: [`spotify_data.csv`](data/extract/spotify_data.csv)

---

## Core Focus

- Map genre preferences over time, especially identifying "musical centers of gravity"
- Highlight temporal trends in listening intensity by time of day, season, and year
- Contextualize podcast listening anomalies and their behavioral significance
- Augment listening data with genre metadata to position taste spatially
- Document methods clearly enough for replication or adaptation by others

---

## Notable Features

- **ENAO Integration**: Used [Every Noise At Once](https://everynoise.com) genre coordinates to project annual listening profiles into 2D space
- **Temporal Slicing**: Grouped activity by season, weekday, and time of day to reveal behavioral shifts
- **Anomaly Focus**: 2020 presented reduced hours played but increased genre exploration—possibly a COVID-era response

---

## Why It Matters

Streaming data is real-world data. Parsed correctly, this data reveals personal habits, signal life events, uncover latent genre interest, and reveal contextual shifts in attention. This project goes beyond "Spotify Wrapped" summaries and asks: How does music fit into the rhythms of our lives? How do moods, seasons, or disruptions like a pandemic reshape media choices? 

---

## Suggested Entry Points

- Start with the [Insights Summary](notebooks/spotify_analysis.qmd) cell at the top of the notebook.
- View the [Listening Time Per Month Plot](exports/charts/listening_time_per_month.png) and [Track Count by Time of Day](exports/charts/track_count_time_of_day.png) plots to peruse streaming activity.
- View the [Genre Vectors Plot](exports/charts/genre_vector_sample.png) to understand the spatial analysis.
- Review [`setup/postres_setup.sql`](setup/postgres_setup.sql) and (setup/postgres_setup.sql) [`sql/queries.sql`](sql/queries.sql) for modular, reusable query logic.

---

