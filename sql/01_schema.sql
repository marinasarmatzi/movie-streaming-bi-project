-- =============================================================
-- MOVIE & STREAMING ANALYTICS — Database Schema
-- =============================================================
-- Project  : Movie & Streaming Analytics | BI Portfolio
-- Author   : Marina Sarmatzi
-- Database : MySQL 8.0+
--
-- Description:
-- Full schema setup for the movie analytics database.
-- Includes fact tables, dimension tables, bridge tables,
-- indexes, and data loading for both TMDB and streaming layers.
--
-- Load order:
-- 1. fact_movies
-- 2. dim_genres + bridge_movie_genres
-- 3. dim_collections + bridge_movie_collections
-- 4. dim_companies + bridge_movie_companies
-- 5. dim_people
-- 6. bridge_movie_cast
-- 7. bridge_movie_directors
-- 8. bridge_movie_producers
-- 9. dim_platforms
-- 10. fact_streaming_movies
-- 11. bridge_movie_platforms
-- =============================================================


-- =============================================================
-- 0. CREATE / USE SCHEMA
-- =============================================================

CREATE DATABASE IF NOT EXISTS movie_analytics;
USE movie_analytics;

SET GLOBAL local_infile = 1;


-- =============================================================
-- 1. FACT TABLE: fact_movies
-- =============================================================
-- Main analytical fact table at movie grain.
-- 1 row = 1 movie
-- Contains descriptive attributes and business metrics
-- (budget, revenue, profit, ROI, rating efficiency).
-- =============================================================

DROP TABLE IF EXISTS fact_movies;

CREATE TABLE fact_movies (
    movie_id                  INT            NOT NULL,
    title                     VARCHAR(255)   NOT NULL,
    release_date              DATE           NULL,
    release_year              SMALLINT       NULL,
    runtime                   INT            NULL,
    budget                    BIGINT         NULL,
    revenue                   BIGINT         NULL,
    profit                    BIGINT         NULL,
    roi                       DECIMAL(18,6)  NULL,
    roi_clean                 DECIMAL(18,6)  NULL,
    roi_capped                DECIMAL(18,6)  NULL,
    roi_outlier_flag          TINYINT        NULL,
    vote_average              DECIMAL(4,2)   NULL,
    vote_count                INT            NULL,
    popularity                DECIMAL(14,6)  NULL,
    rating_per_million_budget DECIMAL(18,6)  NULL,
    poster_path               VARCHAR(255)   NULL,
    overview                  TEXT           NULL,
    original_language         VARCHAR(10)    NULL,
    PRIMARY KEY (movie_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/movies_clean.csv'
INTO TABLE fact_movies
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    movie_id, title, release_date, release_year, runtime,
    budget, revenue, profit, roi, roi_clean, roi_capped,
    roi_outlier_flag, vote_average, vote_count, popularity,
    rating_per_million_budget, poster_path, overview, original_language
);

-- Post-load cleanup: blank strings → NULL
UPDATE fact_movies SET poster_path = NULL WHERE TRIM(poster_path) = '';
UPDATE fact_movies SET overview    = NULL WHERE TRIM(overview)    = '';
UPDATE fact_movies SET title       = NULL WHERE TRIM(title)       = '';

-- Business rule: ROI fields undefined when budget = 0
UPDATE fact_movies SET roi = NULL, roi_clean = NULL, roi_capped = NULL,
    rating_per_million_budget = NULL
WHERE budget IS NULL OR budget = 0;

-- Remove known malformed rows
DELETE FROM fact_movies WHERE movie_id IN (82663, 122662, 249260);

-- Indexes
CREATE INDEX idx_fact_movies_release_year ON fact_movies(release_year);
CREATE INDEX idx_fact_movies_language     ON fact_movies(original_language);
CREATE INDEX idx_fact_movies_profit       ON fact_movies(profit);
CREATE INDEX idx_fact_movies_roi_clean    ON fact_movies(roi_clean);


-- =============================================================
-- 2. DIMENSION: dim_genres
-- =============================================================

DROP TABLE IF EXISTS bridge_movie_genres;
DROP TABLE IF EXISTS dim_genres;

CREATE TABLE dim_genres (
    genre_id   INT          NOT NULL,
    genre_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (genre_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/dim_genres.csv'
INTO TABLE dim_genres
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(genre_id, genre_name);


-- =============================================================
-- 3. BRIDGE: bridge_movie_genres
-- =============================================================

CREATE TABLE bridge_movie_genres (
    movie_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    CONSTRAINT fk_bmg_movie  FOREIGN KEY (movie_id) REFERENCES fact_movies(movie_id),
    CONSTRAINT fk_bmg_genre  FOREIGN KEY (genre_id) REFERENCES dim_genres(genre_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/bridge_movie_genres.csv'
INTO TABLE bridge_movie_genres
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(movie_id, genre_id);


-- =============================================================
-- 4. DIMENSION: dim_collections
-- =============================================================
-- Uses TEXT for collection_name to avoid truncation.
-- utf8mb4 required for special characters.

DROP TABLE IF EXISTS bridge_movie_collections;
DROP TABLE IF EXISTS dim_collections;

CREATE TABLE dim_collections (
    collection_id   INT  NOT NULL,
    collection_name TEXT NOT NULL,
    PRIMARY KEY (collection_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/dim_collections.csv'
INTO TABLE dim_collections
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(collection_id, collection_name);


-- =============================================================
-- 5. BRIDGE: bridge_movie_collections
-- =============================================================

CREATE TABLE bridge_movie_collections (
    movie_id      INT NOT NULL,
    collection_id INT NOT NULL,
    PRIMARY KEY (movie_id, collection_id),
    CONSTRAINT fk_bmcol_movie       FOREIGN KEY (movie_id)      REFERENCES fact_movies(movie_id),
    CONSTRAINT fk_bmcol_collection  FOREIGN KEY (collection_id) REFERENCES dim_collections(collection_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/bridge_movie_collections.csv'
INTO TABLE bridge_movie_collections
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(movie_id, collection_id);


-- =============================================================
-- 6. DIMENSION: dim_companies
-- =============================================================

DROP TABLE IF EXISTS bridge_movie_companies;
DROP TABLE IF EXISTS dim_companies;

CREATE TABLE dim_companies (
    company_id   INT  NOT NULL,
    company_name TEXT NOT NULL,
    PRIMARY KEY (company_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/dim_companies.csv'
INTO TABLE dim_companies
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(company_id, company_name);


-- =============================================================
-- 7. BRIDGE: bridge_movie_companies
-- =============================================================

CREATE TABLE bridge_movie_companies (
    movie_id   INT NOT NULL,
    company_id INT NOT NULL,
    PRIMARY KEY (movie_id, company_id),
    CONSTRAINT fk_bmco_movie    FOREIGN KEY (movie_id)   REFERENCES fact_movies(movie_id),
    CONSTRAINT fk_bmco_company  FOREIGN KEY (company_id) REFERENCES dim_companies(company_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/bridge_movie_companies.csv'
INTO TABLE bridge_movie_companies
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(movie_id, company_id);


-- =============================================================
-- 8. DIMENSION: dim_people
-- =============================================================
-- Central people table for cast, directors and producers.
-- Tab-separated due to commas in person names.

DROP TABLE IF EXISTS bridge_movie_cast;
DROP TABLE IF EXISTS bridge_movie_directors;
DROP TABLE IF EXISTS bridge_movie_producers;
DROP TABLE IF EXISTS dim_people;

CREATE TABLE dim_people (
    person_id   INT          NOT NULL,
    person_name VARCHAR(500) NOT NULL,
    PRIMARY KEY (person_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/dim_people_tab.csv'
INTO TABLE dim_people
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(person_id, person_name);


-- =============================================================
-- 9. BRIDGE: bridge_movie_cast
-- =============================================================
-- Tab-separated due to commas in character names.

CREATE TABLE bridge_movie_cast (
    movie_id       INT          NOT NULL,
    person_id      INT          NOT NULL,
    character_name VARCHAR(500) NULL,
    cast_order     INT          NULL,
    PRIMARY KEY (movie_id, person_id),
    CONSTRAINT fk_bmc_movie   FOREIGN KEY (movie_id)  REFERENCES fact_movies(movie_id),
    CONSTRAINT fk_bmc_person  FOREIGN KEY (person_id) REFERENCES dim_people(person_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/bridge_movie_cast_tab.csv'
INTO TABLE bridge_movie_cast
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(movie_id, person_id, character_name, cast_order);


-- =============================================================
-- 10. BRIDGE: bridge_movie_directors
-- =============================================================

CREATE TABLE bridge_movie_directors (
    movie_id  INT NOT NULL,
    person_id INT NOT NULL,
    PRIMARY KEY (movie_id, person_id),
    CONSTRAINT fk_bmd_movie   FOREIGN KEY (movie_id)  REFERENCES fact_movies(movie_id),
    CONSTRAINT fk_bmd_person  FOREIGN KEY (person_id) REFERENCES dim_people(person_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/bridge_movie_directors.csv'
INTO TABLE bridge_movie_directors
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(movie_id, person_id);


-- =============================================================
-- 11. BRIDGE: bridge_movie_producers
-- =============================================================

CREATE TABLE bridge_movie_producers (
    movie_id  INT NOT NULL,
    person_id INT NOT NULL,
    PRIMARY KEY (movie_id, person_id),
    CONSTRAINT fk_bmp_movie   FOREIGN KEY (movie_id)  REFERENCES fact_movies(movie_id),
    CONSTRAINT fk_bmp_person  FOREIGN KEY (person_id) REFERENCES dim_people(person_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/bridge_movie_producers.csv'
INTO TABLE bridge_movie_producers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(movie_id, person_id);


-- =============================================================
-- STREAMING LAYER
-- =============================================================

-- =============================================================
-- 12. DIMENSION: dim_platforms
-- =============================================================

DROP TABLE IF EXISTS bridge_movie_platforms;
DROP TABLE IF EXISTS fact_streaming_movies;
DROP TABLE IF EXISTS dim_platforms;

CREATE TABLE dim_platforms (
    platform_id   TINYINT     NOT NULL,
    platform_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (platform_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/dim_platforms.csv'
INTO TABLE dim_platforms
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(platform_id, platform_name);


-- =============================================================
-- 13. FACT TABLE: fact_streaming_movies
-- =============================================================
-- 1 row = 1 streaming title
-- movie_id is NULL for titles not matched to TMDB

CREATE TABLE fact_streaming_movies (
    streaming_id   INT           NOT NULL,
    movie_id       INT           NULL,
    title          VARCHAR(500)  NOT NULL,
    release_year   SMALLINT      NULL,
    age_rating     VARCHAR(10)   NULL,
    rt_score       DECIMAL(5,2)  NULL,
    on_netflix     TINYINT       NOT NULL DEFAULT 0,
    on_hulu        TINYINT       NOT NULL DEFAULT 0,
    on_prime       TINYINT       NOT NULL DEFAULT 0,
    on_disney      TINYINT       NOT NULL DEFAULT 0,
    match_status   VARCHAR(20)   NOT NULL DEFAULT 'unmatched',
    platform_count TINYINT       NOT NULL DEFAULT 0,
    PRIMARY KEY (streaming_id),
    CONSTRAINT fk_streaming_movie
        FOREIGN KEY (movie_id) REFERENCES fact_movies(movie_id)
        ON DELETE SET NULL
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/fact_streaming_movies.csv'
INTO TABLE fact_streaming_movies
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    streaming_id, @movie_id, title, @release_year,
    @age_rating, @rt_score,
    on_netflix, on_hulu, on_prime, on_disney,
    match_status, platform_count
)
SET
    movie_id     = NULLIF(@movie_id, ''),
    release_year = NULLIF(@release_year, ''),
    age_rating   = NULLIF(@age_rating, ''),
    rt_score     = NULLIF(@rt_score, '');

CREATE INDEX idx_streaming_year     ON fact_streaming_movies(release_year);
CREATE INDEX idx_streaming_match    ON fact_streaming_movies(match_status);
CREATE INDEX idx_streaming_movie_id ON fact_streaming_movies(movie_id);


-- =============================================================
-- 14. BRIDGE: bridge_movie_platforms
-- =============================================================

CREATE TABLE bridge_movie_platforms (
    streaming_id INT     NOT NULL,
    movie_id     INT     NULL,
    platform_id  TINYINT NOT NULL,
    PRIMARY KEY (streaming_id, platform_id),
    CONSTRAINT fk_bridge_streaming FOREIGN KEY (streaming_id) REFERENCES fact_streaming_movies(streaming_id),
    CONSTRAINT fk_bridge_platform  FOREIGN KEY (platform_id)  REFERENCES dim_platforms(platform_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

LOAD DATA LOCAL INFILE 'C:/movies/bridge_movie_platforms.csv'
INTO TABLE bridge_movie_platforms
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@streaming_id, @movie_id, platform_id)
SET
    streaming_id = @streaming_id,
    movie_id     = NULLIF(@movie_id, '');
