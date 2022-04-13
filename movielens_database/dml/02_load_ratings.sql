CREATE TEMPORARY TABLE tmp_ratings (
    LIKE ratings INCLUDING ALL,
    "timestampRaw" int
);

COPY tmp_ratings("userId", "movieId", "rating", "timestampRaw")
FROM '/movielens_database/landing_zone/ratings.csv'
DELIMITER ','
CSV HEADER;

INSERT INTO public.ratings
SELECT
    "userId",
    "movieId",
    "rating",
    TO_TIMESTAMP("timestampRaw")
FROM tmp_ratings;

DROP TABLE tmp_ratings;

-- COPY ratings("userId", "movieId", "rating", "timestamp")
-- FROM '/movielens_database/landing_zone/ratings.csv'
-- DELIMITER ','
-- CSV HEADER;
