# GA4 Ecommerce Conversion Analysis

## Overview

This project investigates purchase conversion behavior using Google Analytics 4 (GA4) ecommerce event data.

The analysis started with a broad business question:

> **What behaviors distinguish purchasing sessions from non-purchasing sessions, and where should an ecommerce team investigate opportunities to improve conversion?**

Rather than assuming where users were dropping off, I used SQL in BigQuery to explore the customer journey, test potential explanations, segment user behavior, and validate findings before making recommendations.

## Business Problem

An ecommerce team wants to improve purchase conversion but needs to understand where meaningful differences in user behavior occur throughout the shopping journey.

The analysis focuses on three questions:

1. How do users progress through the ecommerce journey?
2. Which behaviors are associated with successful purchases?
3. Where does the data suggest the team should investigate opportunities to improve conversion?

## Dataset

**Source:** Google Analytics 4 sample ecommerce dataset  
**Platform:** Google BigQuery

The dataset contains event-level ecommerce activity, including behaviors such as:

- product views
- search activity
- add-to-cart events
- checkout initiation
- shipping and payment events
- purchases

## Tools

- SQL
- Google BigQuery
- Google Analytics 4 event data

## Analysis Approach

The analysis progressed through several stages:

1. Explore available ecommerce events
2. Define and validate the conversion funnel
3. Compare behavior across device and acquisition segments
4. Investigate product exploration depth
5. Analyze search behavior
6. Isolate high-exploration sessions
7. Validate cart-to-checkout behavior using event timestamps
8. Translate findings into a focused business recommendation

## Key Finding

Product exploration was strongly associated with purchase behavior, but the relationship between search and conversion changed depending on browsing depth.

Among sessions with **11+ product views that reached the cart**, sessions using site search were substantially less likely to progress from cart to checkout:

- **Used search:** 30.9%
- **Did not use search:** 52.6%

Once checkout occurred, purchase completion was similar between the two groups.

This suggests that highly exploratory search users represent a specific behavioral segment worth investigating rather than evidence that search itself causes lower conversion.

## Status

Analysis complete. Documentation and visualizations in progress.
