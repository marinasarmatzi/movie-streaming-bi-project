# 🎬 Cinematic Data Discovery  
*Movie Industry & Streaming Intelligence Dashboard*

An end-to-end BI project exploring 30+ years of cinematic data and the evolution of the streaming landscape.

---

## 📺 Demo
👉 [Watch the full dashboard demo](PASTE_YOUTUBE_LINK_HERE)

---

## 🧠 Key Business Questions
- What drives movie profitability at scale?
- Do franchises sustain long-term performance over time?
- How do streaming platforms differ in quality vs. catalog size?

---

## 🛠️ Tech Stack
- Python (Pandas) — data cleaning & preprocessing  
- SQL (MySQL) — star schema (14 tables)  
- Power BI & DAX — advanced KPIs and interactive analytics  

---

## ⚙️ Approach
Built entirely with native Power BI — no custom visuals or add-ons, keeping it scalable and business-ready.

---

## 📸 Dashboard Preview
<img width="1801" height="1120" alt="image" src="https://github.com/user-attachments/assets/4b5a9897-7a98-4110-9f16-55f9dbf5b48e" />
<img width="1672" height="1057" alt="image" src="https://github.com/user-attachments/assets/eeac4b07-ca78-48cf-a2a6-563b2d058778" />
<img width="1665" height="1033" alt="image" src="https://github.com/user-attachments/assets/1b1fe094-1d84-49bc-9446-e9c4ec70ec14" />
<img width="1693" height="1080" alt="image" src="https://github.com/user-attachments/assets/f3f3aef9-d186-449c-b194-d63dbe6ec2cf" />


---

## 📌 Project Overview
This project is an end-to-end Business Intelligence solution analyzing movie performance, profitability, and streaming platform distribution.

It combines **financial, content, and platform-level analytics** to answer key business questions such as:
- What drives movie profitability?
- Which genres and franchises perform best?
- How do streaming platforms differ in content strategy and quality?

The project integrates:
- **TMDB movie data (~45K movies)**
- **Streaming platform data (~9.5K titles)**

creating a unified analytical model.

---

## 🧠 Business Objectives
- Identify the most profitable movies, genres, and franchises  
- Evaluate ROI efficiency across the industry  
- Analyze director and actor performance  
- Compare streaming platforms (Netflix, Prime Video, Hulu, Disney+)  
- Understand platform content strategy (genres, ratings, audience targeting)  

---

## 📊 Data Sources
- TMDB Movies Dataset (Kaggle)  
- Streaming Movies Dataset (Netflix / Prime / Hulu / Disney+)  

---

## 🧱 Data Model
The project follows a **star schema with bridge tables**:

### Core Fact Table
- `fact_movies` → movie-level financial and performance metrics  

### Dimensions
- `dim_genres`  
- `dim_collections` (franchises)  
- `dim_companies`  
- `dim_people` (actors, directors, producers)  

### Bridge Tables
- `bridge_movie_genres`  
- `bridge_movie_collections`  
- `bridge_movie_companies`  
- `bridge_movie_cast`  
- `bridge_movie_directors`  
- `bridge_movie_producers`  

### Streaming Layer
- `fact_streaming_movies`  
- `dim_platforms`  
- `bridge_movie_platforms`  

---

## 📈 Key Metrics
- **Profit** = Revenue − Budget  
- **ROI (Return on Investment)**  
- **ROI Clean / ROI Capped** (outlier handling)  
- **Rating Efficiency** (rating per budget)  
- **Platform Coverage** (multi-platform presence)  

---

## 🔍 Key Insights

### 🎥 Profitability
- *Avatar* leads with ~$2.55B profit  
- Franchises dominate top positions (Star Wars, Avengers, etc.)  

### 💰 ROI Efficiency
- Low-budget films (e.g. *Rocky*, *E.T.*, *Jaws*) deliver extreme ROI  
- ROI ≠ Profit → efficiency vs scale trade-off  

### 🎭 Genre Performance
- **Adventure** → highest total profit  
- **Animation** → highest ROI efficiency  

### 🎬 Franchise Analysis
- Star Wars & Harry Potter lead in total profit  
- LOTR shows highest average rating  

### 📺 Streaming Platforms
- **Prime Video** → largest catalog  
- **Disney+** → highest average rating & strong profit share  
- **Netflix** → balanced scale and quality  
- **Hulu** → niche but high-quality content  

---

## 📊 Example Analyses
- Top profitable movies & ROI ranking  
- Genre ranking with window functions  
- Franchise profit evolution (running totals)  
- Director ranking within genre  
- Actor career trends (rolling averages)  
- Platform profit share & content distribution  

---

## 📁 Project Structure
```bash
movie-streaming-bi-project/
│
├── data/
│ ├── raw/
│ └── clean/
│
├── scripts/
│ ├── tmdb_preprocessing.py
│ └── streaming_preprocessing.py
│
├── sql/
│ ├── schema_setup.sql
│ ├── dimensions_bridges.sql
│ ├── business_analysis_queries.sql
│ └── streaming_layer.sql
│
├── visuals/
├── docs/
└── README.md


---

▶️ How to Run

1. Python preprocessing

Clean TMDB dataset

Clean streaming dataset

Export CSV files


2. SQL setup

Create schema

Load data using LOAD DATA INFILE

Build relationships & indexes


3. Analysis

Run business queries

Validate data quality

Explore insights


4. Power BI

Connect to MySQL

Build dashboards

Create interactive visuals



---

🚀 Key Takeaways

This project demonstrates:

End-to-end BI workflow

Data modeling (star schema + bridges)

Advanced SQL (window functions, ranking, trends)

Data integration across multiple sources

Business-driven analytics



---

👩‍💻 Author

Senior BI Analyst
Focus: Business Intelligence, Data Modeling, Advanced Analytics
