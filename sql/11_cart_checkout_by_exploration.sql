-- ============================================================
-- 11. Cart-to-Checkout by Exploration Depth
-- ============================================================
-- Question:
-- Is the lower cart-to-checkout progression associated with
-- search present across all exploration levels, or concentrated
-- among highly exploratory sessions?
--
-- Purpose:
-- The previous analysis identified substantially lower
-- cart-to-checkout progression among search sessions with
-- 11+ product views. Before treating this as a general search
-- behavior pattern, I tested the relationship across multiple
-- product-exploration levels.
--
-- Method:
-- Sessions are grouped by product-view depth. Within each
-- group, search and non-search sessions that reached cart are
-- compared using a validated cart -> checkout sequence.
--
-- Important:
-- Differences are associative and do not establish that search
-- behavior causes changes in checkout progression.
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

    CASE
      WHEN product_views = 1 THEN '1'
      WHEN product_views BETWEEN 2 AND 3 THEN '2-3'
      WHEN product_views BETWEEN 4 AND 5 THEN '4-5'
      WHEN product_views BETWEEN 6 AND 10 THEN '6-10'
      WHEN product_views >= 11 THEN '11+'
    END AS view_bucket,

    CASE
      WHEN product_views = 1 THEN 1
      WHEN product_views BETWEEN 2 AND 3 THEN 2
      WHEN product_views BETWEEN 4 AND 5 THEN 3
      WHEN product_views BETWEEN 6 AND 10 THEN 4
      WHEN product_views >= 11 THEN 5
    END AS bucket_order,

    IF(
      last_checkout_time > first_cart_time,
      1,
      0
    ) AS valid_cart_to_checkout

  FROM session_behavior

  WHERE
    product_views >= 1
    AND first_cart_time IS NOT NULL
)

SELECT
  view_bucket,

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
  view_bucket,
  bucket_order,
  used_search

ORDER BY
  bucket_order,
  used_search DESC;
