-- ============================================================
-- 08. Search Behavior by Product Exploration Depth
-- ============================================================
-- Question:
-- Does the relationship between search and purchase remain
-- when sessions are compared at similar exploration levels?
--
-- Purpose:
-- Search sessions had higher overall purchase rates, but they
-- also viewed substantially more products. Because exploration
-- depth was already strongly associated with purchase, I
-- stratified sessions by product-view depth before comparing
-- search and non-search sessions.
--
-- Important:
-- This controls for one important behavioral dimension but
-- does not establish causation or eliminate all confounding.
-- ============================================================

WITH events AS (
  SELECT
    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS session_id,

    event_name

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE event_name IN (
    'view_item',
    'view_search_results',
    'purchase'
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

    MAX(
      IF(event_name = 'purchase', 1, 0)
    ) AS purchased

  FROM events

  WHERE session_id IS NOT NULL

  GROUP BY
    user_pseudo_id,
    session_id
),

bucketed_sessions AS (
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
    END AS bucket_order

  FROM session_behavior

  WHERE product_views >= 1
)

SELECT
  view_bucket,

  IF(
    used_search = 1,
    'Used search',
    'Did not use search'
  ) AS search_behavior,

  COUNT(*) AS sessions,

  COUNTIF(
    purchased = 1
  ) AS purchasing_sessions,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(purchased = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS purchase_rate_pct

FROM bucketed_sessions

GROUP BY
  view_bucket,
  bucket_order,
  used_search

ORDER BY
  bucket_order,
  used_search DESC;
