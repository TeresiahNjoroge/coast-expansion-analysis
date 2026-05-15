-- ============================================================
-- QUERY 2A: SKU performance in the Mara market
-- ============================================================
-- Purpose: Generate the data underpinning the 3-tier product
-- launch recommendation for Coast expansion.
--
-- Tiering criteria applied to results (in priority order):
--   Tier 1 (launch immediately): gross margin >40%, shelf life
--     viable for 8-10hr Coast transit, rejection <1%,
--     consistent orders across 15+ months
--   Tier 2 (pilot carefully): margin or consistency just below
--     threshold, or specific operational risk present
--   Tier 3 (avoid): pricing errors confirmed, or margin too
--     thin for remote cold chain economics
--
-- Key design decisions:
-- • Variant-level granularity (product_unit_variant_id) because
--   some products have multiple variants with materially different
--   margins (e.g. two Alika Potato variants: 52.64% vs 50.24%).
-- • months_active distinguishes consistent demand from one-off
--   orders. A product ordered in 18 of 18 months is not the
--   same risk profile as one with a single large order.
-- • cogs > 0 filter excludes pre-backfill NULL COGS rows.
-- ============================================================

SELECT
    p.name                                              AS product_name,
    cat.name                                            AS category,
    oli.product_unit_variant_id                         AS variant_id,
    COUNT(DISTINCT o.id)                                AS times_ordered,
    COUNT(DISTINCT DATE_TRUNC('month', o.order_date))   AS months_active,
    ROUND(
        SUM(oli.selling_price * oli.quantity_dispatched)::numeric, 2
    )                                                   AS total_revenue,
    ROUND(
        ((SUM(oli.selling_price * oli.quantity_dispatched) - SUM(oli.cogs))
        / NULLIF(SUM(oli.selling_price * oli.quantity_dispatched), 0)
        * 100)::numeric, 2
    )                                                   AS gross_margin_pct,
    ROUND(
        (SUM(oli.quantity_rejected)
        / NULLIF(SUM(oli.quantity_dispatched), 0)
        * 100)::numeric, 2
    )                                                   AS rejection_rate_pct,
    ROUND(AVG(oli.quantity_dispatched)::numeric, 2)     AS avg_qty_per_order
FROM orders o
JOIN companies c ON c.id = o.company_id
JOIN order_line_items oli ON oli.order_id = o.id
JOIN product_unit_variants puv ON puv.id = oli.product_unit_variant_id
JOIN product_grade_variants pgv ON pgv.id = puv.product_grade_variant_id
JOIN products p ON p.id = pgv.product_id
JOIN categories cat ON cat.id = p.category_id
WHERE c.customer_group_id IN (1, 5)
  AND oli.deleted_at IS NULL
  AND oli.quantity_dispatched > 0
  AND oli.cogs > 0
  -- [apply standard filter from 00_standard_filter.sql]
GROUP BY 1, 2, 3
ORDER BY gross_margin_pct DESC, total_revenue DESC;

-- Tier 1 results (15 SKUs — launch immediately):
-- | Product                | Margin  | Orders | Rejection | Note                        |
-- |------------------------|---------|--------|-----------|-----------------------------|
-- | Red Cabbage            | 69.57%  | 242    | 0.04%     | Highest margin vegetable    |
-- | Butternut              | 64.94%  | 301    | 0.16%     | 28-day shelf life           |
-- | Mango Apple            | 60.11%  | 1,275  | 0.14%     | Natural coastal demand      |
-- | Beefsteak Tomato       | 54.51%  | 249    | 0.05%     |                             |
-- | Celery                 | 53.86%  | 1,462  | 0.11%     | Most ordered SKU in dataset |
-- | Banana Kampala         | 53.64%  | 1,300  | 0.13%     | Lowest rejection (fruits)   |
-- | Beetroot               | 53.13%  | 966    | 0.14%     | 18-day shelf life           |
-- | Alika Potato (var A)   | 52.64%  | 1,119  | 0.07%     | Bulk staple                 |
-- | Green Maize Unshelled  | 51.70%  | 914    | 0.17%     |                             |
-- | Alika Potato (var B)   | 50.24%  | 213    | 0.02%     | Lowest rejection overall    |
-- | Apple Crispy Red       | 47.99%  | 1,301  | 0.09%     | Highest revenue (KES 29.2M) |
-- | Streaky Bacon          | 47.35%  | 107    | 0.12%     | Cold chain: reefer resolved |
-- | French Bean            | 47.15%  | 343    | 0.07%     | Zero customer rejections    |
-- | Watermelon             | 46.81%  | 1,429  | 0.07%     | 21-day shelf life           |
-- | Asparagus              | 44.89%  | 248    | 0.01%     | Premium lodge ingredient    |


-- ============================================================
-- QUERY 2B: Supply reliability and price volatility per SKU
-- ============================================================
-- Purpose: Validate that Tier 1 SKUs are consistently ordered
-- across the full time series, not just high-margin anomalies.
-- Flag SKUs with supply chain instability before recommending
-- them for a new market.
--
-- Key design decisions:
-- • HAVING months_with_orders >= 3 removes SKUs with too little
--   history for meaningful volatility analysis.
-- • price_volatility_pct = (max - min) / avg × 100.
--   >30% signals supply chain instability (inconsistent supplier
--   pricing). This is a Coast launch risk flag.
-- • qty_volatility_pct is expected to be high for lodge customers
--   (bulk ordering is irregular by nature). High qty volatility
--   does NOT indicate supply risk — context matters.
-- ============================================================

SELECT
    p.name                                                  AS product_name,
    oli.product_unit_variant_id                             AS variant_id,
    COUNT(DISTINCT DATE_TRUNC('month', o.order_date))       AS months_with_orders,
    COUNT(DISTINCT o.id)                                    AS total_orders,
    ROUND(
        COUNT(DISTINCT o.id)::numeric
        / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', o.order_date)), 0), 1
    )                                                       AS avg_orders_per_month,
    ROUND(MIN(oli.selling_price)::numeric, 2)               AS min_price,
    ROUND(MAX(oli.selling_price)::numeric, 2)               AS max_price,
    ROUND(
        (MAX(oli.selling_price) - MIN(oli.selling_price))
        / NULLIF(AVG(oli.selling_price), 0) * 100::numeric, 2
    )                                                       AS price_volatility_pct,
    ROUND(MIN(oli.quantity_dispatched)::numeric, 2)         AS min_qty,
    ROUND(MAX(oli.quantity_dispatched)::numeric, 2)         AS max_qty,
    ROUND(
        (MAX(oli.quantity_dispatched) - MIN(oli.quantity_dispatched))
        / NULLIF(AVG(oli.quantity_dispatched), 0) * 100::numeric, 2
    )                                                       AS qty_volatility_pct
FROM orders o
JOIN companies c ON c.id = o.company_id
JOIN order_line_items oli ON oli.order_id = o.id
JOIN product_unit_variants puv ON puv.id = oli.product_unit_variant_id
JOIN product_grade_variants pgv ON pgv.id = puv.product_grade_variant_id
JOIN products p ON p.id = pgv.product_id
WHERE c.customer_group_id IN (1, 5)
  AND oli.deleted_at IS NULL
  AND oli.quantity_dispatched > 0
  AND oli.cogs > 0
  -- [apply standard filter from 00_standard_filter.sql]
GROUP BY 1, 2
HAVING COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) >= 3
ORDER BY months_with_orders DESC, total_orders DESC;

-- Key findings:
-- All 15 Tier 1 SKUs confirmed at 17–18 months consistent ordering.
-- Price volatility <25% across all Tier 1 (supply chain stable).
-- Qty volatility is high across all products — normal for lodge bulk
-- ordering, not a supply signal.
-- Flag: Avocado (var 25) — 43.96% price volatility + confirmed pricing
-- error. Excluded from Tier 1 despite 18 months of orders.
