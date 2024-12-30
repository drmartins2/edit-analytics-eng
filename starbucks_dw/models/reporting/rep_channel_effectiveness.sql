{{
  config(
    materialized = 'view',
    )
}}


WITH 
    channel_engagement AS (
            SELECT 
                o.channel,
                fot.transaction_type,
                COUNT(*) AS event_count
            FROM 
                {{ ref('dim_offer') }} o
            INNER JOIN 
                {{ ref('fct_offer_transactions') }} fot ON o.offer_id = fot.offer_id
            GROUP BY o.channel, fot.transaction_type
    ),

final_channel as 
    (   SELECT 
            channel,
            SUM(CASE WHEN transaction_type = 'received' THEN event_count ELSE 0 END) AS offers_received,
            SUM(CASE WHEN transaction_type = 'viewed' THEN event_count ELSE 0 END) AS offers_viewed,
            SUM(CASE WHEN transaction_type = 'completed' THEN event_count ELSE 0 END) AS offers_completed,
            ROUND(SUM(CASE WHEN transaction_type = 'viewed' THEN event_count ELSE 0 END) * 100.0 / 
                NULLIF(SUM(CASE WHEN transaction_type = 'received' THEN event_count ELSE 0 END), 0), 2) AS view_rate,
            ROUND(SUM(CASE WHEN transaction_type = 'completed' THEN event_count ELSE 0 END) * 100.0 / 
                NULLIF(SUM(CASE WHEN transaction_type = 'received' THEN event_count ELSE 0 END), 0), 2) AS completion_rate,
            current_timestamp AS reporting_date
        FROM channel_engagement
        GROUP BY channel
        ORDER BY completion_rate DESC
    )

select *
from final_channel