# Spotify Listening History Analysis

An end-to-end data analysis project using **Python**, **PostgreSQL**, and **JupyterLab** to explore, analyze, and visualize Spotify listening habits. 

---

## 🔥 Project Highlights

- 📊 Analyzed genre diversity and listening behavior across time
- 🧠 Derived insights from metadata (e.g., platform used, time-of-day trends)
- 🛠️ Built a PostgreSQL-backed data pipeline using Python
- 🎯 Produced actionable visualizations using `plotly`, `seaborn`, and `pandas`
- 🧹 Data cleaning  (CLEAN framework)

---

## 🗂️ Table of Contents

- [Project Setup](-#project-setup)
- [Obtain Your Spotify Data](#-obtain-your-spotify-data)
- [Setup PostgreSQL Database](#setup-postgresql-database)
- [How to Run Analysis](#-how-to-run-analysis)
- [Analysis Overview](#-analysis-overview)
- [Visualizations](#-visualizations)
- [Key Findings](#-key-findings)
- [Future Work](#-future-work)

---

## ⚙️ Project Setup

### 1. Clone This Repository
```
git clone https://github.com/terryjbates/Spotify-Listening-History-Analysis.git
cd Spotify-Listening-History-Analysis
```

### 2. Install Dependencies
We recommend using some version of a  Python [virtual environment](https://docs.python.org/3/library/venv.html), to more easily manage and control the sets of packages and dependencies for each project.
```
pip install -r requirements.txt
```

### 3. Environmental Variables
Create a `.env` file based on the `.env.example` file to store environmental variables. In our case, we also used this to help us safely load PostgreSQL credentials.
```
DB_HOST=localhost
DB_NAME=<database_name>
DB_USER=<database_user_name>
DB_PASS=<database_user_password>
```

## 📦 Obtain Your Spotify Data
This project analyzes the extended streaming history for an account.

1. Authenticate to your Spotify account. 
2. Go to your [Spotify account privacy settings](https://www.spotify.com/us/account/privacy/).
3. Deselect undesired options and tick the `Select Extended streaming history` box on the page.
4. Scroll to the bottom of the page and click `Request data`.
5. View the Spotify email confirming your history is ready to download and click the "Download" link.
6. Extract the `.json` files of the history download into of the `data/raw/` subdirectory.

## Setup PostgreSQL Database
1. Download the [latest PostgreSQL version](https://www.postgresql.org/download/) for your OS environment.
2. Follow the installation instructions for your OS environment. This project utilized the [Windows OS](https://www.w3schools.com/postgresql/postgresql_install.php) version.
3. After PostgreSQL installation, we recommend installing [pgAdmin](https://www.w3schools.com/postgresql/postgresql_install.php) GUI program.
4. Start the PostgreSQL service if necessary.
5. Create a database to store the listening data. This example uses `spotify_streaming`, but can be named anything.
```
CREATE DATABASE spotify_streaming;
```
5. Create a database user to access the database. This can be done via GUI within `pgadmin` or can be invoked on terminal using `psql`.
```
CREATE USER spotify_postgres_user WITH PASSWORD 'your_password';
```
6. Grant the database user access privileges to database.
```
GRANT ALL PRIVILEGES ON DATABASE spotify_streaming TO spotify_postgres_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO spotify_postgres_user; 
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO spotify_postgres_user;
```
7. (Optional) Run setup SQL Script.
```
psql -U spotify_postgres_user -d spotify -f setup/postgres_setup.sql
```
8. Configure `.env` with database config info.


## 🚀 How to Run Analysis

1. Extract data from Spotify JSON
```
python src/extract.py
```
2. Transform and clean the data
```
python src/transform.py
```
3. Load into PostgreSQL
```
python src/load.py
```
4. Open the analysis notebook
```
jupyter lab notebooks/spotify_analysis.ipynb
```

## 🔍 Analysis Overview
The notebook covers:
* Total and unique genres discovered by year
* Listening patterns by hour, weekday, and platform
* Repeat artist behavior and platform stickiness
* First-time genre discoveries by year

## 📈 Visualizations
* Scatter plots of genre discovery
* Time series of listening frequency
* Bar plots of top artists per year
* Correlation plots between metadata dimensions

## 💡 Key Findings
* I have a ever-tightening series of genres 2017–2020.
* My listening patterns shifted post-2021.
* Most listening times during summer months.

## 🔮 Future Work
* Connect to Spotify API to get track/genre metadata dynamically
* Add cluster analysis of genre affinity
* Publish to Quarto or Streamlit for web sharing
