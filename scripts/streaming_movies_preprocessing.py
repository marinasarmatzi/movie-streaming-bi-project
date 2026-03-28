import os
import csv
import pandas as pd
import numpy as np

RAW_PATH   = os.path.join("data", "raw")
CLEAN_PATH = os.path.join("data", "clean")
os.makedirs(CLEAN_PATH, exist_ok=True)

# =============================================================
# 1. LOAD
# =============================================================

print("Loading streaming_movies.csv...")
streaming = pd.read_csv(os.path.join(RAW_PATH, "streaming_movies.csv"))
print(f"  Raw shape: {streaming.shape}")

print("Loading movies_clean.csv (for join)...")
movies = pd.read_csv(os.path.join(CLEAN_PATH, "movies_clean.csv"))
print(f"  movies_clean shape: {movies.shape}")


# =============================================================
# 2. CLEAN STREAMING DATA
# =============================================================

streaming = streaming.drop(columns=["Unnamed: 0", "Type"])
streaming = streaming.rename(columns={
    "ID"             : "streaming_id",
    "Title"          : "title",
    "Year"           : "release_year",
    "Age"            : "age_rating",
    "Rotten Tomatoes": "rt_raw",
    "Prime Video"    : "prime_video",
    "Disney+"        : "disney_plus"
})

# Parse RT score: "98/100" → 98
streaming["rt_score"] = (
    streaming["rt_raw"]
    .str.split("/")
    .str[0]
    .pipe(pd.to_numeric, errors="coerce")
)

# Standardize age rating
age_map = {"all": "All", "7+": "7+", "13+": "13+", "16+": "16+", "18+": "18+"}
streaming["age_rating"] = streaming["age_rating"].map(age_map)

# Clean title for matching
streaming["title_clean"] = streaming["title"].str.lower().str.strip()


# =============================================================
# 3. JOIN WITH TMDB fact_movies (title + year match)
# =============================================================

print("\nAttempting title + year match with fact_movies...")

movies["title_clean"]      = movies["title"].str.lower().str.strip()
movies["release_year_int"] = movies["release_year"].fillna(0).astype(int)
streaming["release_year_int"] = streaming["release_year"].fillna(0).astype(int)

merged = streaming.merge(
    movies[["movie_id", "title_clean", "release_year_int"]],
    on=["title_clean", "release_year_int"],
    how="left"
)

matched   = merged["movie_id"].notna().sum()
unmatched = merged["movie_id"].isna().sum()
match_pct = round(matched / len(merged) * 100, 1)

print(f"  Matched  : {matched} ({match_pct}%)")
print(f"  Unmatched: {unmatched}")


# =============================================================
# 4. BUILD fact_streaming_movies
# =============================================================

fact_streaming_movies = merged[[
    "streaming_id",
    "movie_id",       # tmdb movie_id (null if no match)
    "title",
    "release_year",
    "age_rating",
    "rt_score",
    "Netflix",
    "Hulu",
    "prime_video",
    "disney_plus"
]].copy()

fact_streaming_movies = fact_streaming_movies.rename(columns={
    "Netflix"    : "on_netflix",
    "Hulu"       : "on_hulu",
    "prime_video": "on_prime",
    "disney_plus": "on_disney"
})

fact_streaming_movies["platform_count"] = (
    fact_streaming_movies["on_netflix"] +
    fact_streaming_movies["on_hulu"] +
    fact_streaming_movies["on_prime"] +
    fact_streaming_movies["on_disney"]
)

print(f"\n  fact_streaming_movies: {fact_streaming_movies.shape}")


# =============================================================
# 5. BUILD dim_platforms
# =============================================================

dim_platforms = pd.DataFrame([
    {"platform_id": 1, "platform_name": "Netflix"},
    {"platform_id": 2, "platform_name": "Hulu"},
    {"platform_id": 3, "platform_name": "Prime Video"},
    {"platform_id": 4, "platform_name": "Disney+"},
])


# =============================================================
# 6. BUILD bridge_movie_platforms (unpivot)
# =============================================================

platform_cols = {
    "on_netflix": 1,
    "on_hulu"   : 2,
    "on_prime"  : 3,
    "on_disney" : 4
}

bridge_rows = []
for col, platform_id in platform_cols.items():
    subset = fact_streaming_movies[
        fact_streaming_movies[col] == 1
    ][["streaming_id", "movie_id"]].copy()
    subset["platform_id"] = platform_id
    bridge_rows.append(subset)

bridge_movie_platforms = pd.concat(bridge_rows, ignore_index=True)
bridge_movie_platforms = bridge_movie_platforms.sort_values(
    ["streaming_id", "platform_id"]
).reset_index(drop=True)

print(f"  bridge_movie_platforms: {bridge_movie_platforms.shape}")


# =============================================================
# 7. VALIDATION SUMMARY
# =============================================================

print("\nValidation:")
print(f"  Total movies         : {len(fact_streaming_movies)}")
print(f"  Matched with TMDB    : {fact_streaming_movies['movie_id'].notna().sum()}")
print(f"  With RT score        : {fact_streaming_movies['rt_score'].notna().sum()}")
print(f"  With age rating      : {fact_streaming_movies['age_rating'].notna().sum()}")
print(f"  On 1 platform        : {(fact_streaming_movies['platform_count'] == 1).sum()}")
print(f"  On 2+ platforms      : {(fact_streaming_movies['platform_count'] >= 2).sum()}")

print("\nPlatform breakdown:")
for col, name in [("on_netflix","Netflix"),("on_hulu","Hulu"),("on_prime","Prime"),("on_disney","Disney+")]:
    print(f"  {name}: {fact_streaming_movies[col].sum()}")

# Top unmatched titles (for reference)
unmatched_df = merged[merged["movie_id"].isna()][["title","release_year"]].head(10)
print(f"\nSample unmatched titles:")
print(unmatched_df.to_string(index=False))


# =============================================================
# 8. EXPORT
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
    print(f"  Exported: {filename}")

print("\nExporting...")
export_csv(fact_streaming_movies,  "fact_streaming_movies.csv")
export_csv(dim_platforms,          "dim_platforms.csv")
export_csv(bridge_movie_platforms, "bridge_movie_platforms.csv")

print("\nStreaming movies preprocessing complete.")
