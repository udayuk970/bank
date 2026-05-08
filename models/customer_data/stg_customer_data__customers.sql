{{ config(materialized='view',
    schema='staging') }}

-- Maps RAW.raw_customers to the haunted house customer schema.
-- Missing columns (gender, address, zip_code, etc.) are derived or set to NULL.

with source as (
    select * from {{ source('customer_data', 'customers') }}
),

renamed as (
    select
        customer_id,
        first_name,
        last_name,
        lower(email)                                            as email,
        phone,
        null::varchar                                           as address,
        null::varchar                                           as city,
        null::varchar                                           as state,
        null::varchar                                           as zip_code,
        DATEDIFF('year', TO_DATE(date_of_birth, 'DD-MM-YYYY'), CURRENT_DATE())::INT AS age,
        null::varchar                                           as gender,
        iff(membership_type in ('gold', 'platinum'),
            true, false)::boolean                               as is_vip_member,
        false::boolean                                          as marketing_opt_in,
        case membership_type
            when 'platinum' then 3
            when 'gold'     then 2
            else 1
        end::int                                                as preferred_scare_level,
        case membership_type
            when 'platinum' then 1000
            when 'gold'     then 500
            when 'silver'   then 250
            else 100
        end::int                                                as loyalty_points,
        COALESCE(
            TRY_TO_TIMESTAMP(created_at, 'DD-MM-YYYY HH12:MI:SS AM'),
            TRY_TO_TIMESTAMP(created_at, 'DD-MM-YYYY HH12:MI AM')
        )::date                                                 as registration_date,
        COALESCE(
            TRY_TO_TIMESTAMP(created_at, 'DD-MM-YYYY HH12:MI:SS AM'),
            TRY_TO_TIMESTAMP(created_at, 'DD-MM-YYYY HH12:MI AM')
        )                                                       as created_at,
        COALESCE(
            TRY_TO_TIMESTAMP(created_at, 'DD-MM-YYYY HH12:MI:SS AM'),
            TRY_TO_TIMESTAMP(created_at, 'DD-MM-YYYY HH12:MI AM')
        )                                                       as updated_at
    from source
)
select * from renamed