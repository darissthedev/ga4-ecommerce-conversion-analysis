-- ============================================================
-- 03. Session-Level Chronological Funnel
-- ============================================================
-- Question:
-- Within a single shopping session, how many sessions progress
-- through the ecommerce funnel in chronological order?
--
-- Purpose:
-- The previous user-level analysis showed whether users
-- participated in funnel stages, but not whether those events
-- occurred in the same session or in the expected order.
--
-- This analysis uses:
--   ga_session_id   -> groups events into sessions
--   event_timestamp -> establishes event order
--
-- Funnel:
-- view_item -> add_to_cart -> begin_checkout ->
-- add_shipping_info -> add_payment_info -> purchase
--
-- Important limitation:
-- This is intentionally a strict funnel. Sessions that take
-- alternate paths, omit tracked events, or contain unusual
-- event sequences will not qualify for later stages.
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
    session_id
)

SELECT
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

FROM session_funnel;
