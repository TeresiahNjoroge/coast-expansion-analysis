-- ============================================================
-- QUERY 1A: Order-level metrics by market
-- ============================================================
-- Purpose: Establish baseline OTIF, order value, and shipping
-- cost comparison between Mara and Nairobi markets.
--
-- Key design decisions:
-- • OTIF uses NULLIF to avoid divide-by-zero and only counts
--   orders where on_time_delivery IS NOT NULL.
--   Critical: Mara has only 2 populated values out of 153 real
--   orders — the denominator matters significantly here.
-- • Median order value included alongside average to flag
--   the right-skew from large standalone lodge orders.
-- ============================================================

SELECT
    CASE
        WHEN c.customer_group_id IN (1, 5) THEN 'Maasai Mara'
        ELSE 'Core (Nairobi)'
    END AS market,
    COUNT(DISTINCT o.id)                                        AS total_orders,
    COUNT(DISTINCT o.company_id)                               AS unique_customers,
    ROUND(AVG(o.total_amount)::numeric, 2)                     AS avg_order_value,
    ROUND(
        (PERCENTILE_CONT(0.5) WITHIN GROUP
            (ORDER BY o.total_amount))::numeric, 2
    )                                                           AS median_order_value,
    ROUND(AVG(o.shipping_cost)::numeric, 2)                    AS avg_shipping_cost,
    COUNT(CASE WHEN o.on_time_delivery = true THEN 1 END)      AS on_time_orders,
    ROUND(
        (COUNT(CASE WHEN o.on_time_delivery = true THEN 1 END)::numeric
        / NULLIF(COUNT(CASE WHEN o.on_time_delivery IS NOT NULL THEN 1 END), 0)
        * 100)::numeric, 2
    )                                                           AS otif_pct
FROM orders o
JOIN companies c ON o.company_id = c.id
-- [apply standard filter from 00_standard_filter.sql]
GROUP BY 1
ORDER BY 1;

-- Results:
-- | Market         | Orders | Customers | Avg Order Value | Median    | OTIF   |
-- |----------------|--------|-----------|-----------------|-----------|--------|
-- | Core (Nairobi) | 10,080 | 151       | KES 12,536      | KES 6,000 | 56.19% |
-- | Maasai Mara    | 7,702  | 8         | KES 20,397      | KES 9,838 | 85.52% |


-- ============================================================
-- QUERY 1B: Gross margin and rejection rate by market
-- ============================================================
-- Purpose: Compare profitability and product quality performance
-- across markets at the order line item level.
--
-- Key design decisions:
-- • Revenue = selling_price × quantity_dispatched (not total_amount).
--   total_amount can include adjustments and doesn't reflect
--   what was actually delivered.
-- • COGS filter (cogs > 0) excludes pre-backfill NULL rows from
--   the margin denominator. Without this, the margin calculates
--   incorrectly for rows where backfill did not succeed.
-- • Revenue totals are noted but not compared directly between
--   markets: Mara includes 7,546 synthetic orders.
-- ============================================================

SELECT
    CASE
        WHEN c.customer_group_id IN (1, 5) THEN 'Maasai Mara'
        ELSE 'Core (Nairobi)'
    END AS market,
    COUNT(DISTINCT o.id)                                        AS orders_with_line_items,
    ROUND(
        SUM(oli.selling_price * oli.quantity_dispatched)::numeric, 2
    )                                                           AS gross_revenue,
    ROUND(SUM(oli.cogs)::numeric, 2)                           AS total_cogs,
    ROUND(
        ((SUM(oli.selling_price * oli.quantity_dispatched) - SUM(oli.cogs))
        / NULLIF(SUM(oli.selling_price * oli.quantity_dispatched), 0)
        * 100)::numeric, 2
    )                                                           AS gross_margin_pct,
    ROUND(
        (SUM(oli.quantity_rejected)
        / NULLIF(SUM(oli.quantity_dispatched), 0)
        * 100)::numeric, 2
    )                                                           AS rejection_rate_pct
FROM orders o
JOIN companies c ON o.company_id = c.id
JOIN order_line_items oli ON oli.order_id = o.id
WHERE oli.deleted_at IS NULL
  AND oli.quantity_dispatched > 0
  AND oli.cogs > 0
  -- [apply standard filter from 00_standard_filter.sql]
GROUP BY 1
ORDER BY 1;

-- Results:
-- | Market         | Gross Revenue    | Total COGS       | Gross Margin | Rejection |
-- |----------------|------------------|------------------|--------------|-----------|
-- | Core (Nairobi) | KES 126,537,051  | KES 95,539,271   | 24.50%       | 3.04%     |
-- | Maasai Mara    | KES 156,343,996  | KES 92,306,429   | 40.96%       | 0.10%     |


-- ============================================================
-- QUERY 1C: Wastage split — warehouse vs. customer rejection
-- ============================================================
-- Purpose: Determine whether Coast expansion meaningfully
-- increases wastage risk.
--
-- Hypothesis: Most wastage is warehouse-side (overprocurement,
-- cold room failures) and stays in Nairobi regardless of
-- which markets are served. Only customer rejection is a
-- Coast-specific risk.
--
-- Key design decisions:
-- • Filters inventory_adjustments to only SKUs ordered by
--   Mara customers — these are the products Coast would carry.
-- • ILIKE pattern matching on reason field to classify each
--   adjustment as warehouse-origin vs. customer-origin.
-- • HAVING SUM(ia.quantity) > 0 removes SKUs with net-zero
--   adjustments (offsetting entries).
-- ============================================================

SELECT
    p.name                                          AS product_name,
    ia.product_unit_variant_id                      AS variant_id,
    SUM(CASE
        WHEN ia.reason ILIKE '%overprocurement%'
          OR ia.reason ILIKE '%poor storage%'
          OR ia.reason ILIKE '%cold room%'
          OR ia.reason ILIKE '%lack of cold%'
          OR ia.reason ILIKE '%poor sorting%'
          OR ia.reason ILIKE '%poor handling%'
          OR ia.reason ILIKE '%forecasting%'
          OR ia.reason ILIKE '%semi-processing%'
        THEN ia.quantity ELSE 0
    END)                                            AS warehouse_wastage_qty,
    COUNT(CASE
        WHEN ia.reason ILIKE '%overprocurement%'
          OR ia.reason ILIKE '%poor storage%'
          OR ia.reason ILIKE '%cold room%'
          OR ia.reason ILIKE '%lack of cold%'
          OR ia.reason ILIKE '%poor sorting%'
          OR ia.reason ILIKE '%poor handling%'
          OR ia.reason ILIKE '%forecasting%'
          OR ia.reason ILIKE '%semi-processing%'
        THEN 1
    END)                                            AS warehouse_incidents,
    SUM(CASE
        WHEN ia.reason ILIKE '%customer rejection%'
          OR ia.reason ILIKE '%customer order cancellation%'
        THEN ia.quantity ELSE 0
    END)                                            AS customer_rejection_qty,
    COUNT(CASE
        WHEN ia.reason ILIKE '%customer rejection%'
          OR ia.reason ILIKE '%customer order cancellation%'
        THEN 1
    END)                                            AS customer_rejection_incidents,
    ROUND(SUM(ia.quantity)::numeric, 2)             AS total_adjusted_qty
FROM inventory_adjustments ia
JOIN product_unit_variants puv  ON puv.id  = ia.product_unit_variant_id
JOIN product_grade_variants pgv ON pgv.id  = puv.product_grade_variant_id
JOIN products p                 ON p.id    = pgv.product_id
WHERE ia.deleted_at IS NULL
  AND ia.category = 'loss'
  AND ia.product_unit_variant_id IN (
      SELECT DISTINCT oli.product_unit_variant_id
      FROM order_line_items oli
      JOIN orders o    ON o.id   = oli.order_id
      JOIN companies c ON c.id   = o.company_id
      WHERE c.customer_group_id IN (1, 5)
        AND o.deleted_at IS NULL
        AND o.total_amount > 0
        AND oli.deleted_at IS NULL
  )
GROUP BY 1, 2
HAVING SUM(ia.quantity) > 0
ORDER BY customer_rejection_qty DESC, warehouse_wastage_qty DESC;

-- Key finding: 88 SKUs analysed. 37,756 total adjusted quantity.
-- Warehouse wastage = >97%. Customer rejection is minimal.
-- Highest single customer rejection: Leek at 42.3 units.
-- Coast expansion does NOT meaningfully increase total wastage risk.
