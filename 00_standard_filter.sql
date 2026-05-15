-- ============================================================
-- STANDARD FILTER
-- Coast Expansion Strategic Analysis
-- Analyst: Teresiah Njoroge | May 2026
-- ============================================================
-- Applied consistently across ALL queries in this analysis.
-- Excludes: deleted orders, zero-revenue orders, internal staff
-- accounts, test/tech accounts, and orders cancelled for
-- confirmed customer-preference reasons (not operational failures).
-- ============================================================

-- Paste this WHERE clause block into every query.
-- Adjust table aliases (o = orders, c = companies) as needed.

WHERE o.deleted_at IS NULL
  AND o.total_amount > 0

  -- Exclude internal staff accounts (identifiable by company name)
  AND c.name NOT ILIKE '%[COMPANY_INTERNAL]%'

  -- Exclude test and tech accounts (present in production DB)
  AND c.name NOT ILIKE '%[TEST_ACCOUNT_1]%'
  AND c.name NOT ILIKE '%[TEST_ACCOUNT_2]%'
  AND c.name NOT ILIKE '%[TECH_ACCOUNT_1]%'
  AND c.name NOT ILIKE '%[TECH_ACCOUNT_2]%'
  AND c.name NOT ILIKE '%[STAFF_ACCOUNT]%'

  -- Exclude orders cancelled for customer-preference reasons only
  -- (Operational cancellations are retained for performance tracking)
  AND NOT (
      o.status = 'Cancelled'
      AND o.cancellation_reason IN (
          'My plans and requirements have changed',
          'The delivery times no longer work for me',
          'I have concerns with the pricing'
      )
  )

-- ============================================================
-- MARKET SEGMENTATION
-- ============================================================
-- Mara market: customer_group_id IN (1, 5)
-- Nairobi (core): all other customers
--
-- CRITICAL: Do NOT use WHERE customer_group_id NOT IN (1, 5)
-- for the Nairobi segment. This silently drops all companies
-- where customer_group_id IS NULL (374 of 390 companies
-- in this dataset), leaving only 16 companies in the result.
--
-- Use CASE WHEN instead:

SELECT
    CASE
        WHEN c.customer_group_id IN (1, 5) THEN 'Maasai Mara'
        ELSE 'Core (Nairobi)'
    END AS market

-- This correctly includes NULL group_id companies in Nairobi.
-- ============================================================
