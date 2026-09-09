# SQL_Sakila_Project
A broad exploratory data analysis using a sample database in MySQL

## About the Database 
Sakila database is a sample database in MSQL that allows beginners to practice, learn and get familiar with SQL syntaxes.

### Few Sample Questions
**1. List all films with a rental rate greater than 2.99**
```sql
SELECT *
FROM film
WHERE rental_rate > 2.99;
```
**2. Using LAG(), find the number of days between each customer's consecutive rentals.**
```sql
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
```

[Linkedin](www.linkedin.com/in/olanrewaju-j-timmy)

