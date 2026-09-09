# Sakila SQL Practice — Answer Key (60 Questions, 4 Sessions)

## Session 1

#1. List all films with a rental rate greater than 2.99.

SELECT * FROM film
WHERE rental_rate > 2.99;


#2. Find the total number of films in each category, ordered from highest to lowest.**

SELECT c.name AS category_name, COUNT(fc.film_id) AS total_films
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY total_films DESC;


#3. For each customer, rank their rentals from most recent to oldest using ROW_NUMBER().**
SELECT
    customer_id,
    rental_id,
    rental_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date DESC) AS rental_rank
FROM rental;


#4. Show all actors whose last name starts with "W".

SELECT * FROM actor
WHERE last_name LIKE 'W%';

#5. List customers who have never made a payment.
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
LEFT JOIN payment p ON c.customer_id = p.customer_id
WHERE p.payment_id IS NULL;

#6. Retrieve the first and last name of all staff members.
SELECT first_name, last_name FROM staff;

#7. Write a CTE that computes total revenue per store, then rank the stores by revenue.
WITH store_revenue AS (
    SELECT s.store_id, SUM(p.amount) AS total_revenue
    FROM store s
    JOIN staff st ON s.store_id = st.store_id
    JOIN payment p ON st.staff_id = p.staff_id
    GROUP BY s.store_id
)
SELECT
    store_id,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM store_revenue;


#8. Find the average rental duration per film category

SELECT c.name AS category_name, AVG(f.rental_duration) AS avg_rental_duration
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY avg_rental_duration DESC;

#9. Count how many films are rated 'PG-13'.
SELECT COUNT(*) AS pg13_count
FROM film
WHERE rating = 'PG-13';

#10. Using LAG(), find the number of days between each customer's consecutive rentals.**
SELECT
    customer_id,
    rental_id,
    rental_date,
    DATEDIFF(
        rental_date,
        LAG(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date)
    ) AS days_since_last_rental
FROM rental
ORDER BY customer_id, rental_date;

#11. List the top 5 customers by total amount paid.
SELECT c.customer_id, c.first_name, c.last_name, SUM(p.amount) AS total_paid
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_paid DESC
LIMIT 5;


#12. Show all films released in the year 2006.
SELECT * FROM film
WHERE release_year = 2006;

#13. Create a VIEW called film_revenue showing film title, category, and total revenue.
CREATE VIEW film_revenue AS
SELECT
    f.film_id,
    f.title,
    c.name AS category_name,
    SUM(p.amount) AS total_revenue
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY f.film_id, f.title, c.name;

SELECT * FROM film_revenue ORDER BY total_revenue DESC;

#14. Find all films that have never been rented.
SELECT f.film_id, f.title
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL;

#15. Using DENSE_RANK(), rank actors by number of films within each category

WITH actor_category_counts AS (
    SELECT
        fa.actor_id,
        a.first_name,
        a.last_name,
        c.category_id,
        c.name AS category_name,
        COUNT(fa.film_id) AS film_count
    FROM film_actor fa
    JOIN actor a ON fa.actor_id = a.actor_id
    JOIN film_category fc ON fa.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY fa.actor_id, a.first_name, a.last_name, c.category_id, c.name
)
SELECT
    category_name,
    first_name,
    last_name,
    film_count,
    DENSE_RANK() OVER (PARTITION BY category_name ORDER BY film_count DESC) AS actor_rank
FROM actor_category_counts
ORDER BY category_name, actor_rank;

## Session 2

#16. List all distinct film ratings available in the database.

SELECT DISTINCT rating FROM film;

#17. Find the number of customers registered at each store.
SELECT store_id, COUNT(customer_id) AS total_customers
FROM customer
GROUP BY store_id;

#18. Correlated subquery — customers who rented more films than the average customer.
SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(r.rental_id) AS total_rentals
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(r.rental_id) > (
    SELECT AVG(rental_count)
    FROM (
        SELECT COUNT(rental_id) AS rental_count
        FROM rental
        GROUP BY customer_id
    ) AS customer_rentals
);

#19. Show the address, district, and city for all customers.
SELECT c.customer_id, c.first_name, c.last_name,
       a.address, a.district, ci.city
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id;

#20. Find the 10 most rented films of all time.
SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC
LIMIT 10;

#21. List all languages available in the language table.
SELECT * FROM language;

#22. CTE — staff rentals processed, classified High/Medium/Low
WITH staff_rentals AS (
    SELECT st.staff_id, st.first_name, st.last_name,
           COUNT(r.rental_id) AS total_rentals
    FROM staff st
    JOIN rental r ON st.staff_id = r.staff_id
    GROUP BY st.staff_id, st.first_name, st.last_name
)
SELECT staff_id, first_name, last_name, total_rentals,
    CASE
        WHEN total_rentals >= 8000 THEN 'High'
        WHEN total_rentals >= 4000 THEN 'Medium'
        ELSE 'Low'
    END AS performance_tier
FROM staff_rentals
ORDER BY total_rentals DESC;

#23. Find customers who live in the same city as their registered store.
SELECT c.customer_id, c.first_name, c.last_name, cust_city.city AS customer_city
FROM customer c
JOIN address ca ON c.address_id = ca.address_id
JOIN city cust_city ON ca.city_id = cust_city.city_id
JOIN store s ON c.store_id = s.store_id
JOIN address sa ON s.address_id = sa.address_id
JOIN city store_city ON sa.city_id = store_city.city_id
WHERE cust_city.city = store_city.city;

#24. Count films with a replacement cost above $20.
SELECT COUNT(*) AS film_count
FROM film
WHERE replacement_cost > 20;

#25. Running (cumulative) total of monthly rental revenue.
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(payment_date, '%Y-%m') AS payment_month,
        SUM(amount) AS monthly_total
    FROM payment
    GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
)
SELECT
    payment_month,
    monthly_total,
    SUM(monthly_total) OVER (ORDER BY payment_month) AS running_total
FROM monthly_revenue
ORDER BY payment_month;

#26. Top 3 film categories by total number of rentals.
SELECT c.name AS category_name, COUNT(r.rental_id) AS total_rentals
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name
ORDER BY total_rentals DESC
LIMIT 3;

#27. Show all customers whose first name is "Mary".
SELECT * FROM customer
WHERE first_name = 'Mary';

#28. Using LEAD(), find each customer's next rental date and the gap in days.
SELECT
    customer_id,
    rental_id,
    rental_date,
    LEAD(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date) AS next_rental_date,
    DATEDIFF(
        LEAD(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date),
        rental_date
    ) AS days_until_next_rental
FROM rental
ORDER BY customer_id, rental_date;

#29. Find the average payment amount per store.
SELECT s.store_id, AVG(p.amount) AS avg_payment
FROM store s
JOIN staff st ON s.store_id = st.store_id
JOIN payment p ON st.staff_id = p.staff_id
GROUP BY s.store_id;


#30. Create a VIEW customer_rental_summary.
CREATE VIEW customer_rental_summary AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(r.rental_id) AS total_rentals,
    SUM(p.amount) AS total_amount_paid,
    MIN(r.rental_date) AS first_rental_date,
    MAX(r.rental_date) AS last_rental_date
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.customer_id, c.first_name, c.last_name;

SELECT * FROM customer_rental_summary ORDER BY total_amount_paid DESC;

## Session 3

#31. Films longer than 120 minutes.
SELECT * FROM film WHERE length > 120;

#32. Distinct customers who rented each film — top 10 descending.
SELECT f.film_id, f.title, COUNT(DISTINCT r.customer_id) AS distinct_renters
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title
ORDER BY distinct_renters DESC
LIMIT 10;

#33. 2nd most rented film in each category — without LIMIT.
WITH film_rentals AS (
    SELECT
        c.name AS category_name,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY c.name, f.title
),
ranked AS (
    SELECT
        category_name,
        title,
        rental_count,
        DENSE_RANK() OVER (PARTITION BY category_name ORDER BY rental_count DESC) AS rnk
    FROM film_rentals
)
SELECT category_name, title, rental_count
FROM ranked
WHERE rnk = 2;


#34. Active customers — full name and email.
SELECT customer_id, CONCAT(first_name, ' ', last_name) AS full_name, email
FROM customer WHERE active = 1;

#35. Films along with their category name.
SELECT f.film_id, f.title, c.name AS category_name
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id;

#36. Films each actor has starred in — top 10 descending.
SELECT actor_id, first_name, last_name, COUNT(film_id) AS film_count
FROM actor 
JOIN film_actor using( actor_id)
GROUP BY actor_id
ORDER BY film_count DESC
LIMIT 10;

#37. Correlated subquery — films costlier to replace than category average.
SELECT f.film_id, f.title, fc.category_id, f.replacement_cost
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
WHERE f.replacement_cost > (
    SELECT AVG(f2.replacement_cost)
    FROM film f2
    JOIN film_category fc2 ON f2.film_id = fc2.film_id
);

#38. Busiest day of the week for rentals.
SELECT
    DAYNAME(rental_date) AS day_of_week,
    COUNT(rental_id) AS total_rentals
FROM rental
GROUP BY DAYNAME(rental_date)
ORDER BY total_rentals DESC;


#39. Stores along with their manager's full name.
SELECT s.store_id, st.first_name, st.last_name
FROM store s
JOIN staff st ON s.manager_staff_id = st.staff_id;

#40. Top-grossing film per store — CTE + RANK().
WITH film_store_revenue AS (
    SELECT
        i.store_id,
        f.title,
        SUM(p.amount) AS total_revenue
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY i.store_id, f.title
),
ranked AS (
    SELECT
        store_id,
        title,
        total_revenue,
        RANK() OVER (PARTITION BY store_id ORDER BY total_revenue DESC) AS rnk
    FROM film_store_revenue
)
SELECT store_id, title, total_revenue
FROM ranked
WHERE rnk = 1;

#41. Customers who rented from both stores.
SELECT r.customer_id
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE i.store_id IN (1, 2)
GROUP BY r.customer_id
HAVING COUNT(DISTINCT i.store_id) = 2;

#42. Films without "Sequel" in the description.
SELECT film_id, title, description
FROM film
WHERE description NOT LIKE '%Sequel%';

#43. 3-month moving average of rental revenue per store.
WITH monthly_store_revenue AS (
    SELECT
        i.store_id,
        DATE_FORMAT(p.payment_date, '%Y-%m') AS payment_month,
        SUM(p.amount) AS monthly_total
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.store_id, DATE_FORMAT(p.payment_date, '%Y-%m')
)
SELECT
    store_id,
    payment_month,
    monthly_total,
    AVG(monthly_total) OVER (
        PARTITION BY store_id
        ORDER BY payment_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3month
FROM monthly_store_revenue
ORDER BY store_id, payment_month;

#44. Rentals handled by each staff member per month.
SELECT
    staff_id,
    DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
    COUNT(rental_id) AS total_rentals
FROM rental
GROUP BY staff_id, DATE_FORMAT(rental_date, '%Y-%m')
ORDER BY staff_id, rental_month;

#45. NTILE(4) — customer spend quartiles.
WITH customer_spend AS (
    SELECT c.customer_id, c.first_name, c.last_name,
           SUM(p.amount) AS total_spend
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    customer_id,
    first_name,
    last_name,
    total_spend,
    NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile
FROM customer_spend;

#Quartile 1 = top spenders, quartile 4 = lowest spenders — depends entirely on the ORDER BY direction chosen

## Session 4

#46. List all distinct categories in the category table.
SELECT * FROM category;

#47. Average film length per rating.
SELECT rating, AVG(length) AS avg_length
FROM film
GROUP BY rating
ORDER BY avg_length DESC;

#48. CTE — customers who rented films in every category available.
WITH customer_categories AS (
    SELECT r.customer_id, fc.category_id
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY r.customer_id, fc.category_id
),
category_total AS (
    SELECT COUNT(*) AS total_categories FROM category
)
SELECT cc.customer_id, COUNT(DISTINCT cc.category_id) AS categories_rented
FROM customer_categories cc
CROSS JOIN category_total ct
GROUP BY cc.customer_id, ct.total_categories
HAVING COUNT(DISTINCT cc.category_id) = MAX(ct.total_categories);

#49. Payments greater than $9.99.
SELECT * FROM payment
WHERE amount > 9.99;

#50. Which store generates more revenue, and by how much
WITH store_revenue AS (
    SELECT i.store_id, SUM(p.amount) AS total_revenue
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.store_id
)
SELECT
    store_id,
    total_revenue,
    total_revenue - LAG(total_revenue) OVER (ORDER BY total_revenue) AS revenue_difference
FROM store_revenue
ORDER BY total_revenue DESC;

#51. Actors who never appeared in a film.
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id
WHERE fa.film_id IS NULL;

#52. ROW_NUMBER() — each customer's first-ever rental.
WITH ranked_rentals AS (
    SELECT
        customer_id,
        rental_id,
        rental_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date ASC) AS rn
    FROM rental
)
SELECT customer_id, rental_id, rental_date
FROM ranked_rentals
WHERE rn = 1;

#53. Top 5 customers by total payments, with store and city.
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.store_id,
    ci.city,
    SUM(p.amount) AS total_paid
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.store_id, ci.city
ORDER BY total_paid DESC
LIMIT 5;

#54. Count of films per language.
SELECT l.name AS language_name, COUNT(f.film_id) AS total_films
FROM language l
JOIN film f ON l.language_id = f.language_id
GROUP BY l.name;


#55. Create a VIEW monthly_revenue_by_category
CREATE VIEW monthly_revenue_by_category AS
SELECT
    DATE_FORMAT(p.payment_date, '%Y-%m') AS payment_month,
    c.name AS category_name,
    SUM(p.amount) AS total_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film_category fc ON i.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY DATE_FORMAT(p.payment_date, '%Y-%m'), c.name;

SELECT * FROM monthly_revenue_by_category ORDER BY payment_month, total_revenue DESC;

#56. Films in inventory at both stores.
SELECT i.film_id, f.title
FROM inventory i
JOIN film f ON i.film_id = f.film_id
WHERE i.store_id IN (1, 2)
GROUP BY i.film_id, f.title
HAVING COUNT(DISTINCT i.store_id) = 2;

#57. Top 10 most expensive films to replace.
SELECT film_id, title, replacement_cost
FROM film
ORDER BY replacement_cost DESC
LIMIT 10;

#58. LAG()/LEAD() — customers with rental gaps greater than 60 days.
WITH rental_gaps AS (
    SELECT
        customer_id,
        rental_id,
        rental_date,
        DATEDIFF(
            rental_date,
            LAG(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date)
        ) AS days_since_last_rental
    FROM rental
)
SELECT customer_id, rental_id, rental_date, days_since_last_rental
FROM rental_gaps
WHERE days_since_last_rental > 60
ORDER BY customer_id, rental_date;

#59. Total rentals and revenue per category, sorted by revenue.
SELECT
    c.name AS category_name,
    COUNT(r.rental_id) AS total_rentals,
    SUM(p.amount) AS total_revenue
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY total_revenue DESC;

#60. Capstone — Customer Value Report.
WITH customer_summary AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.store_id,
        COUNT(r.rental_id) AS total_rentals,
        SUM(p.amount) AS total_spend
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.store_id
)
SELECT
    customer_id,
    customer_name,
    store_id,
    total_rentals,
    total_spend,
    RANK() OVER (ORDER BY total_spend DESC) AS overall_spend_rank,
    RANK() OVER (PARTITION BY store_id ORDER BY total_spend DESC) AS store_spend_rank
FROM customer_summary
ORDER BY overall_spend_rank;