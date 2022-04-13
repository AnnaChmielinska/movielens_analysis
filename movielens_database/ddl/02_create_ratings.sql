\connect movielens

CREATE TABLE ratings (
    "userId" int,
    "movieId" int,
    "rating" numeric(3, 2),
    CHECK ("rating" BETWEEN 0.5 AND 5.0),
    "timestamp" timestamp
);
