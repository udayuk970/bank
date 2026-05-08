{{ config(materialized='view') }}

with source as (
    select * from {{ source('feedback', 'visitor_feedback') }}
),

renamed as (
    select
        feedback_id,
        customer_id,
        TO_DATE(visit_date, 'DD-MM-YYYY')                            as visit_date,
        try_to_number(ride_id::varchar)::int    as ride_id,
        rating::int             as rating,
        category,
        sentiment,
        comments,
        --submitted_at::timestamp as submitted_at,
        COALESCE(
            TRY_TO_TIMESTAMP(submitted_at, 'DD-MM-YYYY HH12:MI:SS AM'),
            TRY_TO_TIMESTAMP(submitted_at, 'DD-MM-YYYY HH12:MI AM')
        )                                                        AS submitted_at,
        
        case
            when rating::int >= 4 then 'positive'
            when rating::int = 3  then 'neutral'
            else 'negative'
        end                     as rating_category
    from source
)

select * from renamed
