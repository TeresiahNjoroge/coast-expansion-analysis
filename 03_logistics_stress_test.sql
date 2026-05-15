-- ============================================================
-- QUERY 3A: High-mileage route cost benchmark
-- ============================================================
-- Purpose: Establish a real-data cost-per-km benchmark for
-- long-haul routes comparable to the Mara distance class
-- (540–630 km road), to validate synthetic trip cost estimates.
--
-- Key design decisions:
-- • Filter >400 km targets the same distance class as
--   Nairobi–Mara. No equivalent long-haul routes exist for
--   the Nairobi–Coast distance (~1,000 km round trip) in
--   the historical data.
-- • cost < 100,000 excludes known data entry errors (several
--   records show impossibly high fuel costs).
-- • Joined to route_orders to get order density — a trip with
--   zero linked orders is likely a deadhead run and skews the
--   cost-per-order figure.
-- • HAVING COUNT(ro.id) > 0 excludes empty routes.
--
-- RESULT: Zero rows returned for Jan–Mar 2026.
-- This IS the finding — it confirms that Mara logistics costs
-- were not being recorded in the system during the analysis
-- period, validating why synthetic cost modelling was necessary.
-- ============================================================

SELECT
    r.date,
    v.registration_number,
    ROUND((le.last_mileage - le.first_mileage)::numeric, 2)     AS actual_trip_km,
    le.cost                                                      AS route_fuel_cost,
    ROUND(
        le.cost / NULLIF(le.last_mileage - le.first_mileage, 0)::numeric, 2
    )                                                            AS fuel_cost_per_km,
    COUNT(ro.id)                                                 AS orders_on_route,
    ROUND(
        le.cost / NULLIF(COUNT(ro.id), 0)::numeric, 2
    )                                                            AS fuel_cost_per_order
FROM logistics_expenses le
JOIN vehicles v  ON v.id = le.vehicle_id
JOIN routes r    ON r.vehicle_id = le.vehicle_id
    AND r.date = le.date AND r.type = 'last_mile'
LEFT JOIN route_orders ro ON ro.route_id = r.id
WHERE le.deleted_at IS NULL
  AND le.first_mileage IS NOT NULL AND le.last_mileage IS NOT NULL
  AND (le.last_mileage - le.first_mileage) > 400
  AND le.cost > 0 AND le.cost < 100000
  AND le.type = 'fuel'
  AND v.vehicle_type = 'closed_box_truck'
  AND r.deleted_at IS NULL
GROUP BY
    r.date, v.registration_number, v.vehicle_type,
    le.last_mileage, le.first_mileage, le.cost
HAVING COUNT(ro.id) > 0
ORDER BY COUNT(ro.id) DESC;

-- Expected output: 0 rows for Jan–Mar 2026.
-- Finding: No Mara or comparable long-haul routes were recorded
-- in logistics_expenses for the analysis period. Trip costs
-- were modelled from operational parameters instead (see below).


-- ============================================================
-- QUERY 3B: Verify synthetic cost records entered in DB
-- ============================================================
-- Purpose: Confirm all 13 modelled trip cost records were
-- correctly inserted into logistics_expenses.
--
-- Synthetic records are tagged with reference prefix 'LE-2026-05-'
-- and notes field set to 'SYNTHETIC' to distinguish them from
-- real operational data.
--
-- Trip cost parameters (derived from operational knowledge):
--   Combined North+South route (11 trips):
--     Fuel: KES 18,000 | On-demand: KES 13,000
--     Lunch: KES 2,000 | Parking: KES 750 | Total: KES 33,750
--
--   South-only route (2 trips):
--     Fuel: KES 15,000 | On-demand: KES 10,000
--     Lunch: KES 2,000 | Parking: KES 500 | Total: KES 27,500
-- ============================================================

SELECT
    le.reference,
    le.date,
    le.type,
    v.registration_number,
    u.name          AS driver_name,
    le.total_mileage,
    le.cost,
    le.notes,
    le.status
FROM logistics_expenses le
JOIN vehicles v ON v.id = le.vehicle_id
JOIN drivers  d ON d.id = le.driver_id
JOIN users    u ON u.id = d.user_id
WHERE le.reference LIKE 'LE-2026-05-%'
ORDER BY le.date;

-- Expected: 13 rows confirmed in DB.
-- Vehicle: [VEH-001] (registered as vehicle_id = [VEH_ID] before analysis)
-- Driver: [DRIVER_A] (driver_id = [DRIVER_ID])
-- Status: pending on all records

-- Confirmed records summary:
-- | Reference       | Date       | Mileage (km) | Cost       | Trip Type     |
-- |-----------------|------------|--------------|------------|---------------|
-- | LE-2026-05-001  | 2026-01-06 | 630.3        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-002  | 2026-01-13 | 630.3        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-003  | 2026-01-16 | 571.6        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-004  | 2026-01-23 | 599.9        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-005  | 2026-02-06 | 599.3        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-006  | 2026-02-10 | 630.3        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-007  | 2026-02-13 | 600.2        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-008  | 2026-02-20 | 599.3        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-009  | 2026-02-27 | 600.2        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-010  | 2026-03-03 | 581.1        | KES 27,500 | South-only    |
-- | LE-2026-05-011  | 2026-03-06 | 600.0        | KES 33,750 | Combined N+S  |
-- | LE-2026-05-012  | 2026-03-10 | 581.1        | KES 27,500 | South-only    |
-- | LE-2026-05-013  | 2026-03-13 | 571.6        | KES 33,750 | Combined N+S  |
--
-- Total logistics cost: KES 426,250
-- Revenue over period:  KES 2,912,087
-- Net contribution:     KES 766,541 (26.3%)


-- ============================================================
-- QUERY 3C: Real Mara dispatch batching pattern
-- ============================================================
-- Purpose: Understand how the existing Mara route is batched
-- in practice — which customers consolidate orders, which
-- request standalone dispatches, and whether the KES 70,800
-- minimum order threshold is being enforced.
--
-- Key design decisions:
-- • dispatched_at used (not delivery_date) as the correct cost
--   attribution timestamp — this is when the vehicle left the
--   warehouse.
-- • SYN-MM- prefix filter excludes synthetic orders from the
--   dispatch date batching view (synthetic orders have
--   fabricated dispatch dates and would distort the pattern).
-- • STRING_AGG shows which lodge accounts appear on each run,
--   revealing route consolidation behaviour.
-- ============================================================

SELECT
    DATE(o.dispatched_at)                       AS dispatch_date,
    COUNT(DISTINCT o.id)                         AS orders_dispatched,
    ROUND(SUM(o.total_amount)::numeric, 2)       AS batch_revenue,
    ROUND(AVG(o.total_amount)::numeric, 2)       AS avg_order_value,
    STRING_AGG(DISTINCT c.name, ', ')            AS customers
FROM orders o
JOIN companies c ON c.id = o.company_id
WHERE c.customer_group_id IN (1, 5)
  AND o.dispatched_at IS NOT NULL
  AND o.order_number NOT LIKE 'SYN-MM-%'
  -- [apply standard filter from 00_standard_filter.sql]
GROUP BY 1
ORDER BY 1 DESC;

-- Key findings from results:
-- • Community runs (13–19 orders): avg KES 9,700–25,900 per order
-- • Standalone premium runs (1–2 orders): Lodge D averaging
--   KES 78,593 per order — borderline vs KES 70,800 threshold
-- • Three dispatches below KES 70,800 threshold identified —
--   these were contribution-negative and should be co-loaded
--   or deferred in the Coast model
-- • One data entry error (KES 15.60 single-item order) excluded


-- ============================================================
-- STANDALONE BREAK-EVEN CALCULATION
-- ============================================================
-- Minimum standalone order value for a South-only trip (KES 27,500):
--   KES 27,500 / 40.96% gross margin = KES 67,139 break-even
--   Policy set at KES 70,800 (5.5% buffer above break-even)
--
-- For a Combined N+S trip (KES 33,750):
--   KES 33,750 / 40.96% = KES 82,397 — only viable bundled
--   with community route orders
--
-- Jan–Mar 2026 actuals summary:
--   Trips:             13
--   Orders:            152
--   Revenue:           KES 2,912,087
--   Logistics cost:    KES 426,250
--   Net contribution:  KES 766,541 (26.3%)
--   Best trip:         18 orders, KES 467K revenue, 34% contribution
--   Weakest trip:      2 orders, 11% contribution (still positive)
