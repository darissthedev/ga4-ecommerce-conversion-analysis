-- ============================================================
-- 09. High-Exploration Cart Behavior
-- ============================================================
-- Question:
-- Among sessions with 11+ product views, does cart behavior
-- differ between search and non-search sessions?
--
-- Purpose:
-- Search sessions with 11+ product views had substantially
-- lower purchase rates than comparable non-search sessions.
-- I tested whether that difference appeared at the point where
-- users added products to their carts.
--
-- Important:
-- This analysis compares behavioral associations within the
-- high-exploration segment. It does not establish causation.
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
    'add_to_cart',
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

    COUNTIF(
      event_name = 'add_to_cart'
    ) AS cart_events,

    MAX(
      IF(event_name = 'view_search_results', 1, 0)
    ) AS used_search,

    MAX(
      IF(event_name = 'add_to_cart', 1, 0)
    ) AS reached_cart,

    MAX(
      IF(event_name = 'purchase', 1, 0)
    ) AS purchased

  FROM events

  WHERE session_id IS NOT NULL

  GROUP BY
    user_pseudo_id,
    session_id
)

SELECT
  IF(
    used_search = 1,
    'Used search',
    'Did not use search'
  ) AS search_behavior,

  COUNT(*) AS sessions,

  ROUND(
    AVG(product_views),
    2
  ) AS avg_product_views,

  COUNTIF(
    reached_cart = 1
  ) AS sessions_with_cart,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(reached_cart = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS cart_rate_pct,

  ROUND(
    AVG(cart_events),
    2
  ) AS avg_cart_events,

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

FROM session_behavior

WHERE product_views >= 11

GROUP BY
  used_search

ORDER BY
  used_search DESC;
