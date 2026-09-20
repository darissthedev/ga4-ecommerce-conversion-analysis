-- ============================================================
-- 10. High-Exploration Cart-to-Checkout Validation
-- ============================================================
-- Question:
-- Among high-exploration sessions that reach cart, are search
-- users less likely to progress from cart to checkout?
--
-- Purpose:
-- High-exploration search and non-search sessions reached cart
-- at similar rates, despite substantially different purchase
-- rates. I therefore investigated what happened after cart.
--
-- Rather than treating events that occurred anywhere in the
-- same session as sequential funnel behavior, this analysis
-- uses event timestamps to verify that checkout occurred after
-- an earlier cart event.
--
-- Method:
-- first_cart_time + last_checkout_time allows repeated cart
-- and checkout behavior while confirming that at least one
-- valid cart -> checkout sequence exists.
-- ============================================================

WITH events AS (
  SELECT
    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS session_id,

    event_name,
    event_timestamp

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE event_name IN (
    'view_item',
    'view_search_results',
    'add_to_cart',
    'begin_checkout'
  )
),

session_behavior AS (
  SELECT
    user_pseudo_id,
    session_id,

    COUNTIF(
      event_name = 'view_item'
    ) AS product_views,

    MAX(
      IF(event_name = 'view_search_results', 1, 0)
    ) AS used_search,

    MIN(
      IF(
        event_name = 'add_to_cart',
        event_timestamp,
        NULL
      )
    ) AS first_cart_time,

    MAX(
      IF(
        event_name = 'begin_checkout',
        event_timestamp,
        NULL
      )
    ) AS last_checkout_time

  FROM events

  WHERE session_id IS NOT NULL

  GROUP BY
    user_pseudo_id,
    session_id
),

eligible_sessions AS (
  SELECT
    *,

    IF(
      last_checkout_time > first_cart_time,
      1,
      0
    ) AS valid_cart_to_checkout

  FROM session_behavior

  WHERE
    product_views >= 11
    AND first_cart_time IS NOT NULL
)

SELECT
  IF(
    used_search = 1,
    'Used search',
    'Did not use search'
  ) AS search_behavior,

  COUNT(*) AS cart_sessions,

  COUNTIF(
    valid_cart_to_checkout = 1
  ) AS cart_to_checkout_sessions,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(valid_cart_to_checkout = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS cart_to_checkout_pct

FROM eligible_sessions

GROUP BY
  used_search

ORDER BY
  used_search DESC;
