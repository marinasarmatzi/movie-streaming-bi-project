-- =============================================================
-- MOVIE & STREAMING ANALYTICS — Business Analysis Queries
-- =============================================================
-- Project  : Movie & Streaming Analytics | BI Portfolio
-- Author   : Marina Sarmatzi
-- Database : MySQL 8.0+
--
-- Sections:
-- Q1-Q3   : Profitability Analysis
-- Q4-Q5   : Genre Analysis
-- Q6-Q7   : Franchise Analysis
-- Q8-Q9   : Director Analysis
-- Q10-Q11 : Actor Analysis
-- Q12     : Movie Ranking by Genre (bonus)
-- Q13-Q15 : Time & Trend Analysis
-- Q16     : Sequel Quality Analysis
-- Q17     : Studio Market Share
-- SQ1-SQ12: Streaming Platform Analysis
-- =============================================================

USE movie_analytics;


-- =============================================================
-- SECTION 1: PROFITABILITY ANALYSIS
-- =============================================================

-- Q1. Most profitable movies
-- Ranks all movies by absolute profit.
-- Reveals blockbusters and commercial powerhouses.
SELECT
    title,
    release_year,
    budget,
    revenue,
    profit,
    ROUND(roi_clean, 2) AS roi,
    vote_average
FROM fact_movies
WHERE profit IS NOT NULL
ORDER BY profit DESC
LIMIT 20;


-- Q2. Best ROI movies (budget >= 100K)
-- Identifies most capital-efficient films.
-- Small-budget films often dominate this list.
SELECT
    title,
    release_year,
    budget,
    revenue,
    ROUND(roi_clean, 2) AS roi,
    vote_average
FROM fact_movies
WHERE roi_clean IS NOT NULL
  AND budget >= 100000
ORDER BY roi_clean DESC
LIMIT 20;


-- Q3. Profit trend by year
-- Shows annual industry growth and key market shifts.
SELECT
    release_year,
    COUNT(*)                     AS movies_released,
    SUM(profit)                  AS total_profit,
    ROUND(AVG(roi_clean), 2)     AS avg_roi,
    ROUND(AVG(vote_average), 2)  AS avg_rating
FROM fact_movies
WHERE release_year IS NOT NULL
  AND release_year >= 1980
  AND budget > 0
GROUP BY release_year
ORDER BY release_year;


-- =============================================================
-- SECTION 2: GENRE ANALYSIS
-- =============================================================

-- Q4. Genre performance (profit + ROI + rating)
SELECT
    g.genre_name,
    COUNT(DISTINCT f.movie_id)    AS movie_count,
    ROUND(AVG(f.vote_average), 2) AS avg_rating,
    ROUND(AVG(f.roi_clean), 2)    AS avg_roi,
    SUM(f.profit)                 AS total_profit
FROM fact_movies f
JOIN bridge_movie_genres b ON f.movie_id = b.movie_id
JOIN dim_genres g          ON b.genre_id = g.genre_id
WHERE f.budget > 0
GROUP BY g.genre_name
ORDER BY total_profit DESC;


-- Q5. Genre ROI ranking with window functions
-- Shows rank and profit share per genre.
SELECT
    genre_name,
    movie_count,
    avg_roi,
    total_profit,
    RANK() OVER (ORDER BY avg_roi DESC)      AS roi_rank,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER ()                AS grand_total_profit,
    ROUND(100.0 * total_profit / SUM(total_profit) OVER (), 2) AS profit_share_pct
FROM (
    SELECT
        g.genre_name,
        COUNT(DISTINCT f.movie_id)    AS movie_count,
        ROUND(AVG(f.roi_clean), 2)    AS avg_roi,
        SUM(f.profit)                 AS total_profit
    FROM fact_movies f
    JOIN bridge_movie_genres b ON f.movie_id = b.movie_id
    JOIN dim_genres g          ON b.genre_id = g.genre_id
    WHERE f.budget > 0
    GROUP BY g.genre_name
) genre_summary
ORDER BY profit_rank;


-- =============================================================
-- SECTION 3: FRANCHISE ANALYSIS
-- =============================================================

-- Q6. Most profitable franchises
-- Franchise performance by total profit, avg ROI, avg rating.
-- Minimum 2 movies per franchise.
WITH franchise_summary AS (
    SELECT
        c.collection_name,
        COUNT(DISTINCT b.movie_id)    AS movies_in_franchise,
        SUM(f.profit)                 AS total_profit,
        ROUND(AVG(f.roi_clean), 2)    AS avg_roi,
        ROUND(AVG(f.vote_average), 2) AS avg_rating,
        MIN(f.release_year)           AS first_movie,
        MAX(f.release_year)           AS last_movie
    FROM bridge_movie_collections b
    JOIN dim_collections c ON b.collection_id = c.collection_id
    JOIN fact_movies f     ON b.movie_id      = f.movie_id
    WHERE f.budget > 0
      AND f.profit IS NOT NULL
    GROUP BY c.collection_name
    HAVING movies_in_franchise >= 2
)
SELECT *
FROM franchise_summary
ORDER BY total_profit DESC
LIMIT 20;


-- Q7. Franchise profit evolution
-- Running total profit within each franchise, movie by movie.
WITH franchise_movies AS (
    SELECT
        c.collection_name,
        f.title,
        f.release_year,
        f.profit,
        f.vote_average,
        ROW_NUMBER() OVER (
            PARTITION BY c.collection_name
            ORDER BY f.release_year, f.movie_id
        ) AS movie_number_in_franchise,
        SUM(f.profit) OVER (
            PARTITION BY c.collection_name
            ORDER BY f.release_year, f.movie_id
        ) AS running_franchise_profit
    FROM bridge_movie_collections b
    JOIN dim_collections c ON b.collection_id = c.collection_id
    JOIN fact_movies f     ON b.movie_id      = f.movie_id
    WHERE c.collection_name IN (
        'Star Wars Collection',
        'The Avengers Collection',
        'James Bond Collection',
        'The Dark Knight Collection',
        'Toy Story Collection'
    )
)
SELECT
    collection_name,
    movie_number_in_franchise,
    title,
    release_year,
    profit,
    running_franchise_profit
FROM franchise_movies
ORDER BY collection_name, movie_number_in_franchise;


-- =============================================================
-- SECTION 4: DIRECTOR ANALYSIS
-- =============================================================

-- Q8. Best directors by rating
-- Minimum 5 movies for statistical relevance.
SELECT
    p.person_name                 AS director,
    COUNT(DISTINCT b.movie_id)    AS movies_directed,
    ROUND(AVG(f.vote_average), 2) AS avg_rating,
    ROUND(AVG(f.roi_clean), 2)    AS avg_roi,
    SUM(f.profit)                 AS total_profit
FROM bridge_movie_directors b
JOIN dim_people p  ON b.person_id = p.person_id
JOIN fact_movies f ON b.movie_id  = f.movie_id
WHERE f.budget > 0
  AND f.profit IS NOT NULL
GROUP BY p.person_name
HAVING movies_directed >= 5
ORDER BY avg_rating DESC
LIMIT 20;


-- Q9. Director ranking within genre
-- Top 3 directors per genre by avg rating.
-- Minimum 3 movies per director per genre.
WITH director_genre AS (
    SELECT
        p.person_name                 AS director,
        g.genre_name,
        COUNT(DISTINCT f.movie_id)    AS movies,
        ROUND(AVG(f.vote_average), 2) AS avg_rating,
        SUM(f.profit)                 AS total_profit
    FROM bridge_movie_directors bd
    JOIN dim_people p         ON bd.person_id = p.person_id
    JOIN fact_movies f        ON bd.movie_id  = f.movie_id
    JOIN bridge_movie_genres bg ON f.movie_id = bg.movie_id
    JOIN dim_genres g         ON bg.genre_id  = g.genre_id
    WHERE f.budget > 0
      AND f.profit IS NOT NULL
    GROUP BY p.person_name, g.genre_name
    HAVING movies >= 3
),
ranked_directors AS (
    SELECT
        genre_name,
        director,
        movies,
        avg_rating,
        total_profit,
        RANK() OVER (
            PARTITION BY genre_name
            ORDER BY avg_rating DESC
        ) AS rating_rank_in_genre
    FROM director_genre
)
SELECT
    genre_name,
    director,
    movies,
    avg_rating,
    total_profit,
    rating_rank_in_genre
FROM ranked_directors
WHERE rating_rank_in_genre <= 3
ORDER BY genre_name, rating_rank_in_genre;


-- =============================================================
-- SECTION 5: ACTOR ANALYSIS
-- =============================================================

-- Q10. Top actors in high-rated movies
-- Only lead roles (cast_order <= 2), minimum 5 movies.
SELECT
    p.person_name                 AS actor,
    COUNT(DISTINCT b.movie_id)    AS movies,
    ROUND(AVG(f.vote_average), 2) AS avg_rating,
    ROUND(AVG(f.roi_clean), 2)    AS avg_roi,
    SUM(f.profit)                 AS total_profit
FROM bridge_movie_cast b
JOIN dim_people p  ON b.person_id = p.person_id
JOIN fact_movies f ON b.movie_id  = f.movie_id
WHERE b.cast_order <= 2
  AND f.budget > 0
  AND f.profit IS NOT NULL
GROUP BY p.person_name
HAVING movies >= 5
ORDER BY avg_rating DESC
LIMIT 20;


-- Q11. Actor career rolling average rating
-- 3-movie rolling average to show career trajectory.
-- Only lead roles (cast_order <= 2), minimum 10 movies.
WITH actor_movies AS (
    SELECT
        p.person_name AS actor,
        f.title,
        f.release_year,
        f.vote_average,
        f.profit,
        ROW_NUMBER() OVER (
            PARTITION BY p.person_name
            ORDER BY f.release_year
        ) AS movie_number
    FROM bridge_movie_cast b
    JOIN dim_people p  ON b.person_id = p.person_id
    JOIN fact_movies f ON b.movie_id  = f.movie_id
    WHERE b.cast_order <= 2
      AND f.budget > 0
),
actor_counts AS (
    SELECT actor, COUNT(*) AS total_movies
    FROM actor_movies
    GROUP BY actor
    HAVING total_movies >= 10
)
SELECT
    am.actor,
    am.title,
    am.release_year,
    am.vote_average,
    am.movie_number,
    ROUND(AVG(am.vote_average) OVER (
        PARTITION BY am.actor
        ORDER BY am.release_year
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_avg_rating
FROM actor_movies am
JOIN actor_counts ac ON am.actor = ac.actor
WHERE am.actor IN (
    'Tom Hanks', 'Meryl Streep', 'Robert De Niro',
    'Morgan Freeman', 'Cate Blanchett'
)
ORDER BY am.actor, am.release_year;


-- =============================================================
-- SECTION 6: TIME & TREND ANALYSIS
-- =============================================================

-- Q13. Year-over-year profit growth using LAG()
WITH yearly AS (
    SELECT
        release_year,
        SUM(profit)  AS total_profit,
        COUNT(*)     AS movies
    FROM fact_movies
    WHERE release_year >= 1980
      AND budget > 0
      AND profit IS NOT NULL
    GROUP BY release_year
),
yearly_with_lag AS (
    SELECT
        release_year,
        movies,
        total_profit,
        LAG(total_profit) OVER (ORDER BY release_year) AS prev_year_profit
    FROM yearly
)
SELECT
    release_year,
    movies,
    total_profit,
    prev_year_profit,
    ROUND(
        100.0 * (total_profit - prev_year_profit)
        / NULLIF(prev_year_profit, 0),
        2
    ) AS yoy_growth_pct
FROM yearly_with_lag
ORDER BY release_year;


-- Q14. ROI percentile ranking using PERCENT_RANK()
-- Budget >= 1M to exclude micro-budget outliers.
SELECT
    title,
    release_year,
    budget,
    ROUND(roi_clean, 2) AS roi,
    vote_average,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY roi_clean) * 100,
        1
    ) AS roi_percentile
FROM fact_movies
WHERE roi_clean IS NOT NULL
  AND budget >= 1000000
ORDER BY roi_clean DESC
LIMIT 30;


-- Q15. Top 5 movies per decade by profit
WITH movie_decade_rank AS (
    SELECT
        CONCAT(FLOOR(release_year / 10) * 10, 's') AS decade,
        title,
        release_year,
        profit,
        vote_average,
        ROW_NUMBER() OVER (
            PARTITION BY FLOOR(release_year / 10)
            ORDER BY profit DESC
        ) AS decade_rank
    FROM fact_movies
    WHERE release_year IS NOT NULL
      AND profit IS NOT NULL
      AND budget > 0
)
SELECT decade, decade_rank, title, release_year, profit, vote_average
FROM movie_decade_rank
WHERE decade_rank <= 5
ORDER BY decade, decade_rank;


-- =============================================================
-- SECTION 7: SEQUEL & STUDIO ANALYSIS
-- =============================================================

-- Q16. Franchise sequel quality change using LAG()
-- Shows rating drift from one sequel to the next.
WITH franchise_movies AS (
    SELECT
        c.collection_name,
        f.title,
        f.release_year,
        f.vote_average,
        f.profit,
        ROW_NUMBER() OVER (
            PARTITION BY c.collection_name
            ORDER BY f.release_year, f.title
        ) AS sequel_no
    FROM bridge_movie_collections b
    JOIN dim_collections c ON b.collection_id = c.collection_id
    JOIN fact_movies f     ON b.movie_id      = f.movie_id
),
franchise_with_lag AS (
    SELECT
        collection_name,
        title,
        release_year,
        vote_average,
        profit,
        sequel_no,
        LAG(vote_average) OVER (
            PARTITION BY collection_name
            ORDER BY sequel_no
        ) AS prev_rating
    FROM franchise_movies
)
SELECT
    collection_name,
    sequel_no,
    title,
    release_year,
    vote_average,
    prev_rating,
    ROUND(vote_average - prev_rating, 2) AS rating_change_vs_previous
FROM franchise_with_lag
ORDER BY collection_name, sequel_no;


-- Q17. Studio profit share by year
-- Market concentration analysis. Filter: > 1% annual share.
WITH studio_year_profit AS (
    SELECT
        f.release_year,
        c.company_name,
        SUM(f.profit) AS studio_profit
    FROM fact_movies f
    JOIN bridge_movie_companies b ON f.movie_id   = b.movie_id
    JOIN dim_companies c          ON b.company_id = c.company_id
    WHERE f.release_year IS NOT NULL
      AND f.profit IS NOT NULL
      AND f.budget > 0
    GROUP BY f.release_year, c.company_name
),
studio_share AS (
    SELECT
        release_year,
        company_name,
        studio_profit,
        SUM(studio_profit) OVER (PARTITION BY release_year) AS total_year_profit,
        ROUND(
            100.0 * studio_profit
            / NULLIF(SUM(studio_profit) OVER (PARTITION BY release_year), 0),
            2
        ) AS profit_share_pct
    FROM studio_year_profit
)
SELECT
    release_year,
    company_name,
    studio_profit,
    total_year_profit,
    profit_share_pct
FROM studio_share
WHERE profit_share_pct > 1
  AND release_year >= 1980
ORDER BY release_year, profit_share_pct DESC;


-- =============================================================
-- SECTION 8: STREAMING PLATFORM ANALYSIS
-- =============================================================

-- SQ1. Catalog size by platform
SELECT
    p.platform_name,
    COUNT(*) AS title_count
FROM bridge_movie_platforms b
JOIN dim_platforms p ON b.platform_id = p.platform_id
GROUP BY p.platform_name
ORDER BY title_count DESC;


-- SQ2. Exclusive vs multi-platform titles
SELECT
    CASE WHEN platform_count = 1 THEN 'Exclusive' ELSE 'Multi-platform' END AS availability_type,
    COUNT(*) AS title_count
FROM fact_streaming_movies
GROUP BY availability_type;


-- SQ3. Average RT score by platform
SELECT
    p.platform_name,
    COUNT(*) AS titles,
    ROUND(AVG(f.rt_score), 2) AS avg_rt_score
FROM bridge_movie_platforms b
JOIN dim_platforms p         ON b.platform_id  = p.platform_id
JOIN fact_streaming_movies f ON b.streaming_id = f.streaming_id
WHERE f.rt_score IS NOT NULL
GROUP BY p.platform_name
ORDER BY avg_rt_score DESC;


-- SQ4. Age rating mix by platform
SELECT
    p.platform_name,
    f.age_rating,
    COUNT(*) AS title_count
FROM bridge_movie_platforms b
JOIN dim_platforms p         ON b.platform_id  = p.platform_id
JOIN fact_streaming_movies f ON b.streaming_id = f.streaming_id
WHERE f.age_rating IS NOT NULL
GROUP BY p.platform_name, f.age_rating
ORDER BY p.platform_name, title_count DESC;


-- SQ5. Top 10 RT titles per platform
WITH ranked_titles AS (
    SELECT
        p.platform_name,
        f.title,
        f.release_year,
        f.rt_score,
        ROW_NUMBER() OVER (
            PARTITION BY p.platform_name
            ORDER BY f.rt_score DESC, f.release_year DESC, f.title
        ) AS platform_rank
    FROM bridge_movie_platforms b
    JOIN dim_platforms p         ON b.platform_id  = p.platform_id
    JOIN fact_streaming_movies f ON b.streaming_id = f.streaming_id
    WHERE f.rt_score IS NOT NULL
)
SELECT platform_name, title, release_year, rt_score, platform_rank
FROM ranked_titles
WHERE platform_rank <= 10
ORDER BY platform_name, platform_rank;


-- SQ6. Platform performance — matched movies only
-- Uses TMDB data (vote_average, ROI, profit) for matched titles.
SELECT
    p.platform_name,
    COUNT(DISTINCT fsm.streaming_id) AS matched_titles,
    ROUND(AVG(f.vote_average), 2)    AS avg_tmdb_rating,
    ROUND(AVG(f.roi_clean), 2)       AS avg_roi,
    SUM(f.profit)                    AS total_profit
FROM bridge_movie_platforms b
JOIN dim_platforms p         ON b.platform_id  = p.platform_id
JOIN fact_streaming_movies fsm ON b.streaming_id = fsm.streaming_id
JOIN fact_movies f           ON fsm.movie_id   = f.movie_id
WHERE fsm.movie_id IS NOT NULL
GROUP BY p.platform_name
ORDER BY total_profit DESC;


-- SQ7. Platform genre mix (matched movies only)
SELECT
    p.platform_name,
    g.genre_name,
    COUNT(DISTINCT f.movie_id) AS movie_count
FROM bridge_movie_platforms bp
JOIN dim_platforms p         ON bp.platform_id  = p.platform_id
JOIN fact_streaming_movies fs ON bp.streaming_id = fs.streaming_id
JOIN fact_movies f           ON fs.movie_id     = f.movie_id
JOIN bridge_movie_genres bg  ON f.movie_id      = bg.movie_id
JOIN dim_genres g            ON bg.genre_id     = g.genre_id
WHERE fs.movie_id IS NOT NULL
GROUP BY p.platform_name, g.genre_name
ORDER BY p.platform_name, movie_count DESC;


-- SQ8. Top 3 genres per platform using DENSE_RANK()
WITH platform_genres AS (
    SELECT
        p.platform_name,
        g.genre_name,
        COUNT(DISTINCT f.movie_id) AS movie_count
    FROM bridge_movie_platforms bp
    JOIN dim_platforms p          ON bp.platform_id  = p.platform_id
    JOIN fact_streaming_movies fs ON bp.streaming_id = fs.streaming_id
    JOIN fact_movies f            ON fs.movie_id     = f.movie_id
    JOIN bridge_movie_genres bg   ON f.movie_id      = bg.movie_id
    JOIN dim_genres g             ON bg.genre_id     = g.genre_id
    WHERE fs.movie_id IS NOT NULL
    GROUP BY p.platform_name, g.genre_name
),
ranked_platform_genres AS (
    SELECT
        platform_name,
        genre_name,
        movie_count,
        DENSE_RANK() OVER (
            PARTITION BY platform_name
            ORDER BY movie_count DESC
        ) AS genre_rank
    FROM platform_genres
)
SELECT platform_name, genre_name, movie_count, genre_rank
FROM ranked_platform_genres
WHERE genre_rank <= 3
ORDER BY platform_name, genre_rank;


-- SQ9. Platform release-year trend (matched movies only)
SELECT
    p.platform_name,
    f.release_year,
    COUNT(DISTINCT f.movie_id)    AS movie_count,
    ROUND(AVG(f.vote_average), 2) AS avg_rating,
    ROUND(AVG(f.roi_clean), 2)    AS avg_roi
FROM bridge_movie_platforms bp
JOIN dim_platforms p          ON bp.platform_id  = p.platform_id
JOIN fact_streaming_movies fs ON bp.streaming_id = fs.streaming_id
JOIN fact_movies f            ON fs.movie_id     = f.movie_id
WHERE fs.movie_id IS NOT NULL
  AND f.release_year >= 1980
GROUP BY p.platform_name, f.release_year
ORDER BY p.platform_name, f.release_year;


-- SQ10. Platform profit share (matched movies only)
WITH platform_profit AS (
    SELECT
        p.platform_name,
        SUM(f.profit) AS total_profit
    FROM bridge_movie_platforms bp
    JOIN dim_platforms p          ON bp.platform_id  = p.platform_id
    JOIN fact_streaming_movies fs ON bp.streaming_id = fs.streaming_id
    JOIN fact_movies f            ON fs.movie_id     = f.movie_id
    WHERE fs.movie_id IS NOT NULL
      AND f.profit IS NOT NULL
    GROUP BY p.platform_name
)
SELECT
    platform_name,
    total_profit,
    ROUND(100.0 * total_profit / NULLIF(SUM(total_profit) OVER (), 0), 2) AS profit_share_pct
FROM platform_profit
ORDER BY total_profit DESC;


-- SQ11. Top 5 matched movies per platform by profit
WITH ranked_platform_movies AS (
    SELECT
        p.platform_name,
        f.title,
        f.release_year,
        f.profit,
        ROW_NUMBER() OVER (
            PARTITION BY p.platform_name
            ORDER BY f.profit DESC
        ) AS movie_rank
    FROM bridge_movie_platforms bp
    JOIN dim_platforms p          ON bp.platform_id  = p.platform_id
    JOIN fact_streaming_movies fs ON bp.streaming_id = fs.streaming_id
    JOIN fact_movies f            ON fs.movie_id     = f.movie_id
    WHERE fs.movie_id IS NOT NULL
      AND f.profit IS NOT NULL
)
SELECT platform_name, title, release_year, profit, movie_rank
FROM ranked_platform_movies
WHERE movie_rank <= 5
ORDER BY platform_name, movie_rank;


-- SQ12. Platform overlap analysis
SELECT
    platform_count,
    COUNT(*) AS title_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_catalog
FROM fact_streaming_movies
GROUP BY platform_count
ORDER BY platform_count;
