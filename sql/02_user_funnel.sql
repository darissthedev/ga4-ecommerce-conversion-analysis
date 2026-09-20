-- ============================================================
-- 02. User-Level Funnel
-- ============================================================
-- Question:
-- How many users participated in each stage of the ecommerce
-- journey?
--
-- Purpose:
-- Event counts can include multiple actions from the same user.
-- I shifted to a user-level view to understand how many users
-- participated in progressively deeper stages of the journey.
--
-- Important limitation:
-- This query identifies whether a user performed each event,
-- but it does NOT prove the events happened in chronological
-- order or within the same session.
-- ============================================================

WITH user_funnel AS (
  SELECT
    user_pseudo_id,

    MAX(IF(event_name = 'view_item', 1, 0))
      AS viewed_item,

    MAX(IF(event_name = 'add_to_cart', 1, 0))
      AS added_to_cart,

    MAX(IF(event_name = 'begin_checkout', 1, 0))
      AS began_checkout,

    MAX(IF(event_name = 'add_shipping_info', 1, 0))
      AS added_shipping,

    MAX(IF(event_name = 'add_payment_info', 1, 0))
      AS added_payment,

    MAX(IF(event_name = 'purchase', 1, 0))
      AS purchased

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  GROUP BY
    user_pseudo_id
)

SELECT
  COUNTIF(viewed_item = 1)
    AS viewed_item,

  COUNTIF(
    viewed_item = 1
    AND added_to_cart = 1
  ) AS added_to_cart,

  COUNTIF(
    viewed_item = 1
    AND added_to_cart = 1
    AND began_checkout = 1
  ) AS began_checkout,

  COUNTIF(
    viewed_item = 1
    AND added_to_cart = 1
    AND began_checkout = 1
    AND added_shipping = 1
  ) AS added_shipping,

  COUNTIF(
    viewed_item = 1
    AND added_to_cart = 1
    AND began_checkout = 1
    AND added_shipping = 1
    AND added_payment = 1
  ) AS added_payment,

  COUNTIF(
    viewed_item = 1
    AND added_to_cart = 1
    AND began_checkout = 1
    AND added_shipping = 1
    AND added_payment = 1
    AND purchased = 1
  ) AS purchased

FROM user_funnel;
