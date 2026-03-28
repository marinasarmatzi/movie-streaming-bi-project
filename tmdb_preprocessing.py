# =============================================================
# TMDB Movie Dataset — Preprocessing Script
# =============================================================
# Project  : Movie & Streaming Analytics | BI Portfolio
# Author   : Marina
# Dataset  : The Movies Dataset (Kaggle / TMDB)
#            https://www.kaggle.com/datasets/rounakbanik/the-movies-dataset
#
# Input files (place in data/raw/):
#   - movies_metadata.csv
#   - credits.csv
#
# Output files (written to data/clean/):
#   - movies_clean.csv
#   - movie_genres.csv        / dim_genres.csv        / bridge_movie_genres.csv
#   - movie_collections.csv   / dim_collections.csv   / bridge_movie_collections.csv
#   - movie_companies.csv     / dim_companies.csv     / bridge_movie_companies.csv
#   - movie_cast.csv          / dim_actors.csv        / bridge_movie_cast.csv
#   - movie_directors.csv     / dim_directors.csv     / bridge_movie_directors.csv
#   - movie_producers.csv     / dim_producers.csv     / bridge_movie_producers.csv
#   - dim_people.csv
# =============================================================

import os
import csv
import ast
import pandas as pd
import numpy as np

# =============================================================
# CONFIGURATION — update paths if needed
# =============================================================

RAW_PATH   = os.path.join("data", "raw")
CLEAN_PATH = os.path.join("data", "clean")

os.makedirs(CLEAN_PATH, exist_ok=True)


# =============================================================
# 1. LOAD RAW FILES
# =============================================================

print("Loading raw files...")

movies = pd.read_csv(
    os.path.join(RAW_PATH, "movies_metadata.csv"),
    low_memory=False
)

credits = pd.read_csv(
    os.path.join(RAW_PATH, "credits.csv")
)

print(f"  movies shape : {movies.shape}")
print(f"  credits shape: {credits.shape}")


# =============================================================
# 2. KEEP ONLY REQUIRED COLUMNS
# =============================================================

movies = movies[[
    "id",
    "title",
    "genres",
    "belongs_to_collection",
    "budget",
    "revenue",
    "release_date",
    "runtime",
    "vote_average",
    "vote_count",
    "popularity",
    "poster_path",
    "overview",
    "production_companies",
    "original_language"
]].copy()

credits = credits[["id", "cast", "crew"]].copy()


# =============================================================
# 3. HELPER FUNCTIONS FOR JSON-LIKE COLUMNS
# =============================================================

def safe_eval_list(value):
    """
    Safely parse a string that looks like a Python list of dicts.
    Returns an empty list if the value is null or malformed.
    Used for: genres, production_companies, cast, crew
    """
    try:
        if pd.isna(value):
            return []
        result = ast.literal_eval(value)
        return result if isinstance(result, list) else []
    except (ValueError, SyntaxError, TypeError):
        return []


def safe_eval_dict(value):
    """
    Safely parse a string that looks like a Python dict.
    Returns None if the value is null or malformed.
    Used for: belongs_to_collection
    """
    try:
        if pd.isna(value):
            return None
        result = ast.literal_eval(value)
        return result if isinstance(result, dict) else None
    except (ValueError, SyntaxError, TypeError):
        return None


# =============================================================
# 4. CLEAN MOVIE IDs
# =============================================================
# The id column in movies_metadata contains some non-numeric
# garbage rows. We convert safely and drop invalid entries.
# This is critical because movie_id is the join key for the
# entire schema.

movies["movie_id"] = pd.to_numeric(movies["id"], errors="coerce")
movies = movies[movies["movie_id"].notna()].copy()
movies["movie_id"] = movies["movie_id"].astype(int)
movies = movies.drop(columns=["id"])

credits["movie_id"] = pd.to_numeric(credits["id"], errors="coerce")
credits = credits[credits["movie_id"].notna()].copy()
credits["movie_id"] = credits["movie_id"].astype(int)
credits = credits.drop(columns=["id"])

print(f"  movies after ID cleaning : {movies.shape}")
print(f"  credits after ID cleaning: {credits.shape}")


# =============================================================
# 5. CLEAN NUMERIC COLUMNS
# =============================================================
# budget/revenue are intentionally left as NaN when missing.
# Filling with 0 would produce misleading ROI / profit values.

numeric_cols = ["budget", "revenue", "runtime", "vote_average", "vote_count", "popularity"]

for col in numeric_cols:
    movies[col] = pd.to_numeric(movies[col], errors="coerce")


# =============================================================
# 6. CLEAN DATE COLUMN
# =============================================================

movies["release_date"] = pd.to_datetime(movies["release_date"], errors="coerce")
movies["release_year"] = movies["release_date"].dt.year


# =============================================================
# 7. CREATE BUSINESS METRICS
# =============================================================

# Profit
movies["profit"] = movies["revenue"] - movies["budget"]

# ROI — only when budget > 0 to avoid division by zero
movies["roi"] = np.where(
    movies["budget"] > 0,
    movies["revenue"] / movies["budget"],
    np.nan
)

# ROI clean — excludes extreme outliers (roi > 100x)
movies["roi_clean"] = np.where(
    (movies["roi"].notna()) & (movies["roi"] <= 100),
    movies["roi"],
    np.nan
)

# ROI capped — caps at 95th percentile for chart-friendly visuals
roi_cap = movies["roi"].quantile(0.95)
movies["roi_capped"] = np.where(
    movies["roi"].notna(),
    movies["roi"].clip(upper=roi_cap),
    np.nan
)

# ROI outlier flag — marks movies with extreme ROI
movies["roi_outlier_flag"] = np.where(
    movies["roi"] > roi_cap, 1, 0
)

# Rating efficiency — avg rating per $1M of budget
movies["rating_per_million_budget"] = np.where(
    movies["budget"] > 0,
    movies["vote_average"] / (movies["budget"] / 1_000_000),
    np.nan
)


# =============================================================
# 8. PARSE JSON-LIKE COLUMNS
# =============================================================

print("Parsing JSON-like columns...")

movies["genres_parsed"]     = movies["genres"].apply(safe_eval_list)
movies["collection_parsed"] = movies["belongs_to_collection"].apply(safe_eval_dict)
movies["companies_parsed"]  = movies["production_companies"].apply(safe_eval_list)

credits["cast_parsed"] = credits["cast"].apply(safe_eval_list)
credits["crew_parsed"] = credits["crew"].apply(safe_eval_list)


# =============================================================
# 9. BUILD NORMALIZED TABLES
# =============================================================

# -------------------------
# 9A. Genres
# -------------------------

movie_genres = (
    movies[["movie_id", "genres_parsed"]]
    .explode("genres_parsed")
    .dropna(subset=["genres_parsed"])
    .copy()
)
movie_genres["genre_id"]   = movie_genres["genres_parsed"].apply(lambda x: x.get("id")   if isinstance(x, dict) else None)
movie_genres["genre_name"] = movie_genres["genres_parsed"].apply(lambda x: x.get("name") if isinstance(x, dict) else None)
movie_genres = movie_genres[["movie_id", "genre_id", "genre_name"]].drop_duplicates()

dim_genres          = movie_genres[["genre_id", "genre_name"]].drop_duplicates()
bridge_movie_genres = movie_genres[["movie_id", "genre_id"]].drop_duplicates()

print(f"  movie_genres : {movie_genres.shape} | dim_genres: {dim_genres.shape}")


# -------------------------
# 9B. Collections / Franchises
# -------------------------

movie_collections = movies.loc[
    movies["collection_parsed"].notna(),
    ["movie_id", "collection_parsed"]
].copy()

movie_collections["collection_id"]   = movie_collections["collection_parsed"].apply(lambda x: x.get("id")   if isinstance(x, dict) else None)
movie_collections["collection_name"] = movie_collections["collection_parsed"].apply(lambda x: x.get("name") if isinstance(x, dict) else None)

dim_collections = (
    movie_collections[["collection_id", "collection_name"]]
    .dropna()
    .drop_duplicates()
    .sort_values("collection_id")
    .reset_index(drop=True)
)

bridge_movie_collections = (
    movie_collections[["movie_id", "collection_id"]]
    .dropna()
    .drop_duplicates()
    .reset_index(drop=True)
)

print(f"  dim_collections: {dim_collections.shape} | bridge: {bridge_movie_collections.shape}")


# -------------------------
# 9C. Production Companies
# -------------------------

movie_companies = (
    movies[["movie_id", "companies_parsed"]]
    .explode("companies_parsed")
    .dropna(subset=["companies_parsed"])
    .copy()
)
movie_companies["company_id"]   = movie_companies["companies_parsed"].apply(lambda x: x.get("id")   if isinstance(x, dict) else None)
movie_companies["company_name"] = movie_companies["companies_parsed"].apply(lambda x: x.get("name") if isinstance(x, dict) else None)
movie_companies = movie_companies[["movie_id", "company_id", "company_name"]].drop_duplicates()

dim_companies           = movie_companies[["company_id", "company_name"]].drop_duplicates()
bridge_movie_companies  = movie_companies[["movie_id", "company_id"]].drop_duplicates()

print(f"  dim_companies: {dim_companies.shape} | bridge: {bridge_movie_companies.shape}")


# -------------------------
# 9D. Cast (Actors)
# -------------------------

movie_cast = (
    credits[["movie_id", "cast_parsed"]]
    .explode("cast_parsed")
    .dropna(subset=["cast_parsed"])
    .copy()
)
movie_cast["person_id"]      = movie_cast["cast_parsed"].apply(lambda x: x.get("id")        if isinstance(x, dict) else None)
movie_cast["person_name"]    = movie_cast["cast_parsed"].apply(lambda x: x.get("name")      if isinstance(x, dict) else None)
movie_cast["character_name"] = movie_cast["cast_parsed"].apply(lambda x: x.get("character") if isinstance(x, dict) else None)
movie_cast["cast_order"]     = movie_cast["cast_parsed"].apply(lambda x: x.get("order")     if isinstance(x, dict) else None)
movie_cast = movie_cast[["movie_id", "person_id", "person_name", "character_name", "cast_order"]].drop_duplicates()

dim_actors          = movie_cast[["person_id", "person_name"]].drop_duplicates()
bridge_movie_cast   = movie_cast[["movie_id", "person_id", "character_name", "cast_order"]].drop_duplicates()

print(f"  movie_cast: {movie_cast.shape} | dim_actors: {dim_actors.shape}")


# -------------------------
# 9E. Directors
# -------------------------

crew_exploded = (
    credits[["movie_id", "crew_parsed"]]
    .explode("crew_parsed")
    .dropna(subset=["crew_parsed"])
    .copy()
)

movie_directors = crew_exploded[
    crew_exploded["crew_parsed"].apply(
        lambda x: isinstance(x, dict) and x.get("job") == "Director"
    )
].copy()
movie_directors["person_id"]   = movie_directors["crew_parsed"].apply(lambda x: x.get("id"))
movie_directors["person_name"] = movie_directors["crew_parsed"].apply(lambda x: x.get("name"))
movie_directors = movie_directors[["movie_id", "person_id", "person_name"]].drop_duplicates()

dim_directors           = movie_directors[["person_id", "person_name"]].drop_duplicates()
bridge_movie_directors  = movie_directors[["movie_id", "person_id"]].drop_duplicates()

print(f"  movie_directors: {movie_directors.shape}")


# -------------------------
# 9F. Producers
# -------------------------

movie_producers = crew_exploded[
    crew_exploded["crew_parsed"].apply(
        lambda x: isinstance(x, dict) and x.get("job") == "Producer"
    )
].copy()
movie_producers["person_id"]   = movie_producers["crew_parsed"].apply(lambda x: x.get("id"))
movie_producers["person_name"] = movie_producers["crew_parsed"].apply(lambda x: x.get("name"))
movie_producers = movie_producers[["movie_id", "person_id", "person_name"]].drop_duplicates()

dim_producers           = movie_producers[["person_id", "person_name"]].drop_duplicates()
bridge_movie_producers  = movie_producers[["movie_id", "person_id"]].drop_duplicates()

print(f"  movie_producers: {movie_producers.shape}")


# -------------------------
# 9G. Unified People Dimension
# -------------------------

dim_people = pd.concat([
    dim_actors.rename(columns={"person_id": "people_id", "person_name": "people_name"}),
    dim_directors.rename(columns={"person_id": "people_id", "person_name": "people_name"}),
    dim_producers.rename(columns={"person_id": "people_id", "person_name": "people_name"})
], ignore_index=True).drop_duplicates()

print(f"  dim_people: {dim_people.shape}")


# =============================================================
# 10. BUILD CLEAN FACT TABLE
# =============================================================

movies_clean = movies[[
    "movie_id",
    "title",
    "release_date",
    "release_year",
    "runtime",
    "budget",
    "revenue",
    "profit",
    "roi",
    "roi_clean",
    "roi_capped",
    "roi_outlier_flag",
    "vote_average",
    "vote_count",
    "popularity",
    "rating_per_million_budget",
    "poster_path",
    "overview",
    "original_language"
]].copy()

movies_clean = movies_clean.drop_duplicates(subset=["movie_id"])

print(f"  movies_clean: {movies_clean.shape}")


# =============================================================
# 11. EXPORT ALL CLEAN FILES
# =============================================================

def export_csv(df, filename):
    path = os.path.join(CLEAN_PATH, filename)
    df.to_csv(
        path,
        index=False,
        encoding="utf-8",
        quoting=csv.QUOTE_ALL,
        lineterminator="\n"
    )

print("Exporting clean CSV files...")

export_csv(movies_clean,           "movies_clean.csv")

export_csv(movie_genres,           "movie_genres.csv")
export_csv(dim_genres,             "dim_genres.csv")
export_csv(bridge_movie_genres,    "bridge_movie_genres.csv")

export_csv(movie_collections,      "movie_collections.csv")
export_csv(dim_collections,        "dim_collections.csv")
export_csv(bridge_movie_collections, "bridge_movie_collections.csv")

export_csv(movie_companies,        "movie_companies.csv")
export_csv(dim_companies,          "dim_companies.csv")
export_csv(bridge_movie_companies, "bridge_movie_companies.csv")

export_csv(movie_cast,             "movie_cast.csv")
export_csv(dim_actors,             "dim_actors.csv")
export_csv(bridge_movie_cast,      "bridge_movie_cast.csv")

export_csv(movie_directors,        "movie_directors.csv")
export_csv(dim_directors,          "dim_directors.csv")
export_csv(bridge_movie_directors, "bridge_movie_directors.csv")

export_csv(movie_producers,        "movie_producers.csv")
export_csv(dim_producers,          "dim_producers.csv")
export_csv(bridge_movie_producers, "bridge_movie_producers.csv")

export_csv(dim_people,             "dim_people.csv")

print("All clean CSV files exported successfully.")
print(f"Output folder: {os.path.abspath(CLEAN_PATH)}")


import pandas as pd

