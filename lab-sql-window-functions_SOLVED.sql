USE sakila;

-- This challenge consists of three exercises that will test your ability to use the SQL RANK() function. 

-- Rank films by their length and create an output table that includes the title, length, and rank columns only. 
-- Filter out any rows with null or zero values in the length column.

SELECT title, length, DENSE_RANK() OVER (ORDER BY length DESC) AS "rank"
FROM film
WHERE length IS NOT NULL AND length > 0;

-- Rank films by length within the rating category and create an output table that includes the title, 
-- length, rating and rank columns only. Filter out any rows with null or zero values in the length column.

SELECT title, length, rating, DENSE_RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS "rank"
FROM film
WHERE length IS NOT NULL AND length > 0;

-- Produce a list that shows for each film in the Sakila database, the actor or actress 
-- who has acted in the greatest number of films, as well as the total number of films in which 
-- they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH actor_film_counts AS (
    SELECT a.actor_id,
           CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
           fa.film_id,
           COUNT(*) AS total_films
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    GROUP BY a.actor_id, actor_name, fa.film_id
),
max_actor_films AS (
    SELECT film_id,
           MAX(total_films) AS max_total_films
    FROM actor_film_counts
    GROUP BY film_id
)
SELECT f.title AS film_title,
       afc.actor_name,
       m.max_total_films AS actor_total_films
FROM film f
JOIN actor_film_counts afc ON f.film_id = afc.film_id
JOIN max_actor_films m ON afc.film_id = m.film_id AND afc.total_films = m.max_total_films;

--  Retrieve the number of monthly active customers, i.e., 
-- the number of unique customers who rented a movie in each month.

SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
       COUNT(DISTINCT customer_id) AS monthly_active_customers
FROM rental
GROUP BY rental_month;

-- Retrieve the number of active users in the previous month.

SELECT rental_month,
       COUNT(DISTINCT customer_id) AS active_users,
       COUNT(DISTINCT customer_id) - LAG(COUNT(DISTINCT customer_id)) OVER (ORDER BY rental_month) AS user_difference
FROM (
    SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
           customer_id
    FROM rental
) monthly_rentals
GROUP BY rental_month
ORDER BY rental_month;

-- Calculate the percentage change in the number of 
-- active customers between the current and previous month.

WITH monthly_active_customers AS (
    SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
           COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY rental_month
)
SELECT rental_month,
       active_customers,
       LAG(active_customers) OVER (ORDER BY rental_month) AS previous_active_customers,
       ROUND(((active_customers - LAG(active_customers) OVER (ORDER BY rental_month)) / CAST(LAG(active_customers) OVER (ORDER BY rental_month) AS DECIMAL)) * 100, 2) AS percentage_change
FROM monthly_active_customers;

-- Calculate the number of retained customers every month, i.e., 
-- customers who rented movies in the current and previous months.

WITH monthly_rentals AS (
    SELECT DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
           customer_id
    FROM rental
),
previous_month_rentals AS (
    SELECT rental_month,
           customer_id
    FROM monthly_rentals
    WHERE rental_month = DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 1 MONTH), '%Y-%m')
)
SELECT m.rental_month,
       COUNT(DISTINCT m.customer_id) AS retained_customers
FROM monthly_rentals m
LEFT JOIN previous_month_rentals p ON m.customer_id = p.customer_id
GROUP BY m.rental_month
HAVING COUNT(DISTINCT p.customer_id) > 0
ORDER BY m.rental_month;

