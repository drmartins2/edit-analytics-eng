{{
  config(
    materialized = 'view',
    )
}}


WITH 
    customer_segments AS (
        SELECT 
            c.customer_id,
            c.age,
            CASE 
                WHEN c.gender = 'M' THEN 'Male'
                WHEN c.gender = 'F' THEN 'Female'
                ELSE 'Other'
            END AS gender ,
            c.income,
            CASE
            WHEN c.age < 30 THEN 'Young'
            WHEN c.age BETWEEN 30 AND 50 THEN 'Middle-aged'
            ELSE 'Senior'
            END AS age_group,
            CASE
            WHEN c.income < 50000 THEN 'Low'
            WHEN c.income BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'High'
            END AS income_group,
            COUNT(DISTINCT o.offer_id) AS total_offers_received,
            SUM(CASE WHEN o.transaction_type = 'completed' THEN 1 ELSE 0 END) AS offers_completed
        FROM 
            {{ ref('dim_customer') }} c
            INNER JOIN {{ ref('fct_customer_transactions') }}  o ON c.customer_id = o.customer_id
        GROUP BY 
            c.customer_id, c.age, c.gender, c.income
    ),

final_cust as 
    (   SELECT 
            age_group,
            gender,
            income_group,
            COUNT(*) AS segment_size,
            AVG(offers_completed * 100.0 / NULLIF(total_offers_received, 0)) AS avg_response_rate,
            current_timestamp AS reporting_date
        FROM 
            customer_segments
        GROUP BY 
            age_group, gender, income_group
        ORDER BY 
            avg_response_rate DESC
    )

select *
from final_cust