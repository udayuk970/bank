{{ config(materialized='view') }}

-- Maps raw_tickets to the haunted house ticket schema.
-- Since raw_tickets has no haunted_house_id, we assign one deterministically
-- using MOD(ticket_id - 1, number_of_haunted_houses) + 1.
-- This distributes tickets evenly across haunted houses for analytical purposes.

with tickets as (
    select * ,
           ROW_NUMBER() OVER (ORDER BY ticket_id) AS ticket_rank from {{ source('external_haunted', 'haunted_house_tickets') }}
),
 
haunted_houses AS (
    SELECT
        ride_id AS haunted_house_id,
        ROW_NUMBER() OVER (ORDER BY ride_id) AS house_rank
    FROM DEV_DB.DBT_DEV_SCHEMA.raw_rides
    WHERE is_haunted = FALSE
),
house_count AS (
    SELECT COUNT(*) AS cnt 
    FROM haunted_houses
),
renamed AS (
    SELECT
        t.ticket_id,
        t.customer_id,
        h.haunted_house_id,
        TO_DATE(t.visit_date, 'DD-MM-YYYY')                     AS visit_date,
        t.final_price::NUMERIC(10,2)                             AS ticket_price,
        COALESCE(
            TRY_TO_TIMESTAMP(t.purchase_date, 'DD-MM-YYYY HH12:MI:SS AM'),
            TRY_TO_TIMESTAMP(t.purchase_date, 'DD-MM-YYYY HH12:MI AM')
        )                                                        AS created_at,
        COALESCE(
            TRY_TO_TIMESTAMP(t.purchase_date, 'DD-MM-YYYY HH12:MI:SS AM'),
            TRY_TO_TIMESTAMP(t.purchase_date, 'DD-MM-YYYY HH12:MI AM')
        )                                                        AS updated_at
    FROM tickets t
    CROSS JOIN house_count hc
    JOIN haunted_houses h
        ON h.house_rank = MOD(t.ticket_rank - 1, hc.cnt) + 1
)
SELECT * 
FROM renamed