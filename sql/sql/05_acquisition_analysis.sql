-- ============================================================
-- 05. Funnel Analysis by Acquisition Source
-- ============================================================
-- Question:
-- Does funnel progression differ meaningfully based on how
-- users were originally acquired?
--
-- Purpose:
-- Device category did not explain the funnel pattern, so I
-- tested whether users from different acquisition sources
-- showed meaningfully different progression.
--
-- Important:
-- GA4 traffic_source.source and traffic_source.medium describe
-- user acquisition, not necessarily the source/medium of the
-- individual session being analyzed.
-- ============================================================

WITH events AS (
  SELECT
    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS session_id,

    traffic_source.source AS source,
    traffic_source.medium AS medium,

    event_name,
    event_timestamp

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE event_name IN (
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'add_shipping_info',
    'add_payment_info',
    'purchase'
  )
),

session_funnel AS (
  SELECT
    user_pseudo_id,
    session_id,
    source,
    medium,

    MIN(IF(
      event_name = 'view_item',
      event_timestamp,
      NULL
    )) AS view_time,

    MIN(IF(
      event_name = 'add_to_cart',
      event_timestamp,
      NULL
    )) AS cart_time,

    MIN(IF(
      event_name = 'begin_checkout',
      event_timestamp,
      NULL
    )) AS checkout_time,

    MIN(IF(
      event_name = 'add_shipping_info',
      event_timestamp,
      NULL
    )) AS shipping_time,

    MIN(IF(
      event_name = 'add_payment_info',
      event_timestamp,
      NULL
    )) AS payment_time,

    MIN(IF(
      event_name = 'purchase',
      event_timestamp,
      NULL
    )) AS purchase_time

  FROM events

  WHERE session_id IS NOT NULL

  GROUP BY
    user_pseudo_id,
    session_id,
    source,
    medium
),

funnel_counts AS (
  SELECT
    source,
    medium,

    COUNTIF(
      view_time IS NOT NULL
    ) AS viewed_item,

    COUNTIF(
      cart_time > view_time
    ) AS added_to_cart,

    COUNTIF(
      cart_time > view_time
      AND checkout_time > cart_time
    ) AS began_checkout,

    COUNTIF(
      cart_time > view_time
      AND checkout_time > cart_time
      AND shipping_time > checkout_time
    ) AS added_shipping,

    COUNTIF(
      cart_time > view_time
      AND checkout_time > cart_time
      AND shipping_time > checkout_time
      AND payment_time > shipping_time
    ) AS added_payment,

    COUNTIF(
      cart_time > view_time
      AND checkout_time > cart_time
      AND shipping_time > checkout_time
      AND payment_time > shipping_time
      AND purchase_time > payment_time
    ) AS purchased

  FROM session_funnel

  GROUP BY
    source,
    medium
)

SELECT
  source,
  medium,
  viewed_item,
  added_to_cart,
  began_checkout,
  added_shipping,
  added_payment,
  purchased

FROM funnel_counts

WHERE viewed_item >= 100

ORDER BY viewed_item DESC;
