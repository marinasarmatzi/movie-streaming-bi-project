# 🎬 Movie & Streaming Analytics | End-to-End BI Project

## 📌 Project Overview

This project is an end-to-end Business Intelligence solution analyzing movie performance, profitability, and streaming platform distribution.

It combines **financial, content, and platform-level analytics** to answer key business questions such as:

* What drives movie profitability?
* Which genres and franchises perform best?
* How do streaming platforms differ in content strategy and quality?

The project integrates **TMDB movie data (~45K movies)** with **streaming platform data (~9.5K titles)**, creating a unified analytical model.

---

## 🧠 Business Objectives

* Identify the most profitable movies, genres, and franchises
* Evaluate ROI efficiency across the industry
* Analyze director and actor performance
* Compare streaming platforms (Netflix, Prime Video, Hulu, Disney+)
* Understand platform content strategy (genres, ratings, audience targeting)

---

## 🛠️ Tech Stack

* **Python (Pandas)** → Data cleaning & preprocessing
* **SQL (MySQL)** → Data modeling & analysis
* **Power BI** → Interactive dashboard & visualization

---

## 📊 Data Sources

* TMDB Movies Dataset (Kaggle)
* Streaming Movies Dataset (Netflix / Prime / Hulu / Disney+)

---

## 🧱 Data Model

The project follows a **star schema with bridge tables**:

### Core Fact Table

* `fact_movies` → movie-level financial and performance metrics

### Dimensions

* `dim_genres`
* `dim_collections` (franchises)
* `dim_companies`
* `dim_people` (actors, directors, producers)

### Bridge Tables

* `bridge_movie_genres`
* `bridge_movie_collections`
* `bridge_movie_companies`
* `bridge_movie_cast`
* `bridge_movie_directors`
* `bridge_movie_producers`

### Streaming Layer

* `fact_streaming_movies`
* `dim_platforms`
* `bridge_movie_platforms`

---

## 📈 Key Metrics

* **Profit** = Revenue − Budget
* **ROI (Return on Investment)**
* **ROI Clean / ROI Capped** (outlier handling)
* **Rating Efficiency** (rating per budget)
* **Platform Coverage** (multi-platform presence)

---

## 🔍 Key Insights

### 🎥 Profitability

* *Avatar* leads with ~$2.55B profit
* Franchises dominate top positions (Star Wars, Avengers, etc.)

### 💰 ROI Efficiency

* Low-budget films (e.g. *Rocky*, *E.T.*, *Jaws*) deliver extreme ROI
* ROI ≠ Profit → efficiency vs scale trade-off

### 🎭 Genre Performance

* **Adventure** → highest total profit
* **Animation** → highest ROI efficiency

### 🎬 Franchise Analysis

* Star Wars & Harry Potter lead in total profit
* LOTR shows highest average rating

### 🎯 Streaming Platforms

* **Prime Video** → largest catalog
* **Disney+** → highest average rating & strongest profit share
* **Netflix** → strong balance of scale + quality
* **Hulu** → niche but high-quality content

---

## 📊 Example Analyses

* Top profitable movies & ROI ranking
* Genre ranking with window functions
* Franchise profit evolution (running totals)
* Director ranking within genre
* Actor career trends (rolling averages)
* Platform profit share & content distribution

---

## 📁 Project Structure

```bash
movie-streaming-bi-project/
│
├── data/
│   ├── raw/
│   └── clean/
│
├── scripts/
│   ├── tmdb_preprocessing.py
│   └── streaming_preprocessing.py
│
├── sql/
│   ├── schema_setup.sql
│   ├── dimensions_bridges.sql
│   ├── business_analysis_queries.sql
│   └── streaming_layer.sql
│
├── visuals/
├── docs/
└── README.md
```

---

## ▶️ How to Run

### 1. Python preprocessing

* Clean TMDB dataset
* Clean streaming dataset
* Export CSV files

### 2. SQL setup

* Create schema
* Load data using `LOAD DATA INFILE`
* Build relationships & indexes

### 3. Analysis

* Run business queries
* Validate data quality
* Explore insights

### 4. Power BI

* Connect to MySQL
* Build dashboards
* Create interactive visuals

---

## 📊 Dashboard (Coming Soon)

Planned features:

* Movie selection panel with posters
* KPI overview (profit, ROI, rating)
* Genre & franchise analysis
* Platform comparison
* Interactive drill-down

---

## 🚀 Key Takeaways

This project demonstrates:

* End-to-end BI workflow
* Data modeling (star schema + bridges)
* Advanced SQL (window functions, ranking, trends)
* Data integration across multiple sources
* Business-driven analytics

---

## 👩‍💻 Author

Senior BI Analyst | Data & Analytics
Focus: Business Intelligence, Data Modeling, Advanced Analytics
