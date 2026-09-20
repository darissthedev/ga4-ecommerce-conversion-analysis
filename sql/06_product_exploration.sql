-- ============================================================
-- 06. Product Exploration and Purchase Behavior
-- ============================================================
-- Question:
-- Is product exploration depth associated with purchase?
--
-- Purpose:
-- Device and acquisition segmentation did not provide a clear
-- explanation for conversion behavior. I shifted the analysis
-- toward what users actually did during their shopping sessions.
--
-- This analysis groups sessions by the number of product-view
-- events and compares purchase rates across exploration levels.
--
-- Important:
-- This analysis identifies an association between product
-- exploration and purchase. It does not establish causation.
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
  bucket_order

ORDER BY
  bucket_order;
