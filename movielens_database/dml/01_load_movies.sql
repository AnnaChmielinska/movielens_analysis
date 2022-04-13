COPY movies
FROM '/movielens_database/landing_zone/movies.csv'
DELIMITER ','
CSV HEADER;
