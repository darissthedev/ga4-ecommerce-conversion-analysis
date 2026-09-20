-- ============================================================
-- 01. Event Exploration
-- ============================================================
-- Question:
-- What user behaviors are represented in the GA4 dataset?
--
-- Purpose:
-- Before defining a conversion funnel, I first explored the
-- available events to understand how shopping behavior is
-- represented in the dataset.
-- ============================================================

SELECT
  event_name,
  COUNT(*) AS event_count
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY
  event_name
ORDER BY
  event_count DESC;
