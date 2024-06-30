-- Find the total number of movies released each year? 
SELECT year, COUNT(title) AS "No_of_movies_released"
FROM movie
GROUP BY year;
-- The highest number of movies produce in the year 2017 

-- How many movies were produced in the USA or India in the year 2019
SELECT year, COUNT(*) AS no_of_movies
FROM movie
WHERE year = "2019"
AND
(country LIKE "%USA%" OR country LIKE "%India%")
GROUP BY year;
-- USA and India produced more than a thousand movies(we know the exact number!) in the year 2019.

-- Which genre had the highest number of movies produced overall?
SELECT g.genre, COUNT(*) AS No_of_movies
FROM genre g
JOIN movie m
ON g.movie_id = m.id
GROUP BY genre
ORDER BY No_of_movies DESC
LIMIT 1;
-- So, based on the insight that we just drew, RSVP Movies should focus on the ‘Drama’ genre. 

-- What is the rank of the ‘thriller’ genre of movies among all the genres in terms of number of movies produced
WITH ct AS(
SELECT genre, COUNT(*) AS No_of_movies,
	RANK() OVER(ORDER BY COUNT(*) DESC) AS rk
FROM genre 
GROUP BY genre)
SELECT genre, No_of_movies, rk
FROM ct 
WHERE genre = "Thriller";
-- Thriller movies is in top 3 among all genres in terms of number of movies

-- Which are the top 10 movies based on average rating?
SELECT m.title,r.avg_rating
FROM movie m 
JOIN ratings r 
ON m.id = r.movie_id
ORDER BY avg_rating DESC
LIMIT 10;

-- Which production house has produced the most number of hit movies (average rating > 8)??
SELECT m.production_company,COUNT(m.id) AS hit_movies_count
FROM movie m 
JOIN ratings r 
ON m.id = r.movie_id
WHERE r.avg_rating > 8 AND m.production_company IS NOT NULL
GROUP BY m.production_company
HAVING hit_movies_count > 1
ORDER BY hit_movies_count DESC;

WITH HitMovies AS (
    SELECT m.production_company, COUNT(*) AS hit_count
    FROM Movie m
    JOIN Ratings r ON m.id = r.movie_id
    WHERE r.avg_rating > 8 AND m.production_company IS NOT NULL
    GROUP BY m.production_company
)
SELECT production_company
FROM HitMovies
WHERE hit_count = (SELECT MAX(hit_count) FROM HitMovies);


-- How many movies released in each genre during March 2017 in the USA had more than 1,000 votes?
SELECT g.genre, COUNT(*) AS No_of_movies
FROM genre g
JOIN movie m
ON g.movie_id = m.id
JOIN ratings r 
ON m.id = r.movie_id
WHERE m.year = "2017" AND m.country LIKE "%USA%" AND r.total_votes > 1000 AND MONTH(m.date_published) = 3
GROUP BY g.genre
ORDER BY No_of_movies DESC;

-- the movies released between 1 April 2018 and 1 April 2019, how many were given a median rating of 8?
SELECT r.median_rating,COUNT(m.id) AS Movies_count
FROM movie m 
JOIN ratings r 
ON m.id = r.movie_id
WHERE m.date_published BETWEEN '2018-04-01' AND '2019-03-31'
AND r.median_rating = 8
GROUP BY r.median_rating;

-- Who are the top three directors who gave more hits
SELECT n.name, COUNT(*) AS Movies_count
FROM director_mapping d 
JOIN names n
ON d.name_id = n.id
JOIN ratings r
ON r.movie_id = d.movie_id
WHERE r.avg_rating > 8
GROUP BY n.name
ORDER BY Movies_count DESC
LIMIT 3;

-- Which are the top three production houses based on the number of votes received by their movies?
SELECT m.production_company,SUM(total_votes) AS total_votes
FROM movie m 
JOIN ratings r 
ON m.id = r.movie_id
WHERE m.production_company IS NOT NULL
GROUP BY m.production_company
ORDER BY total_votes DESC
LIMIT 3;
-- Yes Marvel Studios rules the movie world.
-- So, these are the top three production houses based on the number of votes received by the movies they have produced.

-- Rank actors with movies released in India based on their average ratings. Which actor is at the top of the list?
-- Note: The actor should have acted in at least five Indian movies. 
WITH IndianMovies AS (
	SELECT id AS id
	FROM movie
	WHERE country LIKE '%India%'),
ActorMovies AS (
	SELECT rm.name_id,rm.category,im.id
	FROM role_mapping AS rm 
	JOIN IndianMovies im 
	ON im.id = rm.movie_id
    WHERE rm.category = 'actor'),
ActorRatings AS (
	SELECT ROUND(SUM(r.avg_rating*r.total_votes)/SUM(r.total_votes),2) AS avg_rating,am.name_id
	FROM ratings r 
	JOIN ActorMovies am 
	ON r.movie_id = am.id
    GROUP BY am.name_id
    HAVING COUNT(DISTINCT am.id) >4)
SELECT n.name,ar.avg_rating,
	DENSE_RANK() OVER(ORDER BY ar.avg_rating DESC) AS rk
FROM names n
JOIN ActorRatings ar 
ON n.id = ar.name_id;

WITH ActorRating AS(
SELECT n.name AS actor_name, 
	ROUND(SUM(r.avg_rating*r.total_votes)/SUM(r.total_votes),2) AS avg_rating,
    SUM(r.total_votes) AS total_votes,
    COUNT(m.id) AS movie_count
FROM role_mapping rm
JOIN movie m
ON rm.movie_id = m.id
JOIN ratings r
ON r.movie_id = m.id
JOIN names n
ON rm.name_id = n.id
WHERE m.country LIKE '%India%' AND rm.category = 'actor'
GROUP BY n.name
HAVING movie_count > 4)
SELECT * ,
	DENSE_RANK() OVER(ORDER BY avg_rating DESC) actor_rank
FROM ActorRating;

-- Who are the top 3 actresses in Hindi movies based on number of Super Hit movies (average rating >8) in drama genre?
SELECT n.name AS actress_name, COUNT(n.name) AS movies_count,
	ROUND(SUM(r.avg_rating*r.total_votes)/SUM(r.total_votes),2) AS avg_rating
FROM role_mapping rm
JOIN movie m
ON rm.movie_id = m.id
JOIN ratings r
ON r.movie_id = m.id
JOIN names n
ON rm.name_id = n.id
JOIN genre g 
ON m.id = g.movie_id
WHERE m.languages LIKE '%Hindi%' AND rm.category = 'actress' AND g.genre = 'Drama'
GROUP BY n.name
ORDER BY movies_count DESC;

/* Q24. Select thriller movies as per avg rating and classify them in the following category: 

			Rating > 8: Superhit movies
			Rating between 7 and 8: Hit movies
			Rating between 5 and 7: One-time-watch movies
			Rating < 5: Flop movies
--------------------------------------------------------------------------------------------*/
SELECT m.title AS movie,r.avg_rating,
CASE
	WHEN avg_rating > 8 THEN 'Superhit movies'
    WHEN avg_rating  BETWEEN 7 AND 8 THEN 'Hit movies'
    WHEN avg_rating BETWEEN 5 AND 7 THEN 'One-time-watch movies'
    ELSE 'Flop movies'
    END AS avg_rating_category
FROM movie m 
JOIN genre g 
ON m.id = g.movie_id
JOIN ratings r 
ON m.id = r.movie_id
WHERE g.genre = 'Thriller';

-- What are the top 10 highest-grossing movies of all time based on worldwide gross income?
SELECT title, worlwide_gross_income
FROM movie
ORDER BY worlwide_gross_income DESC
LIMIT 10;

-- What is the average duration of movies released in each year?
SELECT year,AVG(duration) AS average_duration
FROM movie
GROUP BY  year;

-- What is the distribution of genres among the movies in the dataset?
SELECT genre,
       COUNT(*) AS movies_count
FROM genre
GROUP BY genre;

-- Who are the top 10 directors with the highest number of movies in the dataset?
SELECT nm.name AS director_name, COUNT(dm.movie_id) AS movie_count
FROM director_mapping dm
JOIN names nm ON dm.name_id = nm.id
GROUP BY dm.name_id
ORDER BY movie_count DESC
LIMIT 10;






