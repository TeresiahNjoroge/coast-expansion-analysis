# Coast Expansion: Technical Appendix

**Analyst:** Teresiah Njoroge  
**Date:** May 2026  
**Database:** Agritech company operational database (PostgreSQL via DBeaver)  
**Analysis period:** January 6 – March 13, 2026 (real Mara) + synthetic October 2024 – December 2025  
**Decision memo:** [decision-memo.md](../memo/decision-memo.md)

This document contains all SQL queries, methodology notes, assumptions, and data integrity findings supporting the Coast Expansion decision memo.

---

## Standard Filter

Applied consistently across all queries. See [`00_standard_filter.sql`](../queries/00_standard_filter.sql) for the full WHERE clause.

Excludes:
- Deleted orders (`deleted_at IS NULL`)
- Zero-revenue orders (`total_amount > 0`)
- Internal staff accounts (identified by company name pattern)
- Test and tech accounts present in the production database
- Orders cancelled for confirmed customer-preference reasons (not operational failures) — 31 orders total, `status = 'Cancelled'` (capital C)

**Market segmentation:**
- Mara market: `customer_group_id IN (1, 5)`
- Nairobi core: all other customers

**Critical note on NULL handling:**  
`WHERE customer_group_id NOT IN (1, 5)` was tested and found to silently drop all 374 companies with NULL `customer_group_id` (the Nairobi majority), returning only 16 companies. All Nairobi queries use `CASE WHEN` instead.

---

## Section 1: Data Scope

| Segment | Orders | Customers | Date Range |
|---|---|---|---|
| Core (Nairobi) | 10,080 | 151 | Full history |
| Maasai Mara — real | 153 | 8 | Jan 6 – Mar 13, 2026 |
| Maasai Mara — synthetic | 7,546 | 8 | Oct 2024 – Dec 2025 |
| **Mara total** | **7,699** | **8** | **Full period** |

April 2026 excluded: no Mara orders in system. Analysis period fixed at Jan 6 – Mar 13, 2026.

Synthetic orders are tagged `SYN-MM-` prefix on `order_number`. They are excluded from all rate metrics (OTIF, gross margin, rejection rate). Included in order count and volume comparisons only.

---

## Section 2: Remote Market Performance Diagnostic

Full queries in [`01_market_performance.sql`](../queries/01_market_performance.sql).

### Results

| Metric | Nairobi | Maasai Mara |
|---|---|---|
| Orders | 10,074 | 7,699 (153 real + 7,546 synthetic) |
| Customers | 150 | 8 |
| Avg order value | KES 12,540 | KES 20,405 |
| Gross margin | 24.50% | 40.96% |
| Rejection rate | 3.04% | 0.10% |
| OTIF | 56.19% | 84.76% |

**Query 1A** — OTIF uses `NULLIF` to avoid dividing by zero and counts only orders where `on_time_delivery IS NOT NULL`. Mara OTIF is based on 2 of 153 real orders (the others have NULL). This is a synthetic proxy.

**Query 1B** — Revenue uses `selling_price × quantity_dispatched`, not `total_amount`. Revenue totals are not compared directly across markets because Mara includes 7,546 synthetic orders.

**Query 1C (Wastage)** — 88 SKUs analysed. 37,756 total adjusted quantity across the loss category. Warehouse wastage accounts for >97%. The highest single customer rejection is 42.3 units (Leek). Coast expansion does not meaningfully increase total wastage risk.

---

## Section 3: Coast Product Mix Recommendation

Full queries in [`02_product_mix.sql`](../queries/02_product_mix.sql).

### Tiering Criteria

Applied in priority order:
1. Gross margin above 40%
2. Shelf life viable for 8–10 hours of Coast transit
3. Rejection rate below 1%
4. Order frequency consistency across 15+ months

### Tier 1: Launch Immediately (15 SKUs)

| Product | Margin | Orders | Rejection | Note |
|---|---|---|---|---|
| Red Cabbage | 69.57% | 242 | 0.04% | Highest margin vegetable |
| Butternut | 64.94% | 301 | 0.16% | 28-day shelf life |
| Mango Apple | 60.11% | 1,275 | 0.14% | Natural coastal demand |
| Beefsteak Tomato | 54.51% | 249 | 0.05% | |
| Celery | 53.86% | 1,462 | 0.11% | Most ordered SKU in dataset |
| Banana Kampala | 53.64% | 1,300 | 0.13% | Lowest rejection among fruits |
| Beetroot | 53.13% | 966 | 0.14% | 18-day shelf life |
| Alika Potato (var A) | 52.64% | 1,119 | 0.07% | Bulk staple |
| Green Maize Unshelled | 51.70% | 914 | 0.17% | |
| Alika Potato (var B) | 50.24% | 213 | 0.02% | Lowest rejection in dataset |
| Apple Crispy Red | 47.99% | 1,301 | 0.09% | Highest revenue SKU; temp monitoring required |
| Streaky Bacon | 47.35% | 107 | 0.12% | Cold chain resolved by reefer |
| French Bean | 47.15% | 343 | 0.07% | Zero customer rejections |
| Watermelon | 46.81% | 1,429 | 0.07% | 21-day shelf life |
| Asparagus | 44.89% | 248 | 0.01% | Premium lodge ingredient |

### Tier 2: Pilot Carefully (16 SKUs)

| Product | Margin | Key Risk | Pilot Condition |
|---|---|---|---|
| Managu | 47.64% | 1-day shelf life | Only if same-day delivery confirmed |
| Sukuma | 45.61% | 3-day shelf life | Small quantities only |
| Red Capsicum | 46.09% | Good margin | Reduce initial quantities |
| Breakfast Coffee 500g | 44.57% | Limited real order history | Test 2–3 accounts first |
| Carrot | 43.75% | 7-day shelf life | Weekly dispatch discipline |
| Tomato | 43.43% | 4-day shelf life | Strict procurement controls |
| Chicken Wings | 42.66% | Cold chain needed | Standard pilot |
| Pineapple Delmonte | 40.36% | 3-day shelf life | No overstock |
| Sweet Banana | 37.65% | Below threshold, perishable | Tropical demand may compensate |
| Spinach | 37.01% | 3-day shelf life, humidity | Small quantities only |
| Red Onion | 37.01% | Below threshold | Right-size procurement |
| Sirloin Steak | 36.74% | Below threshold | Only above 13 orders per route |
| Chicken Sausages | 36.01% | Near threshold | Standard pilot |
| Green Maize Shelled | 34.98% | Below threshold | Volume may compensate |
| Red Snapper Fillets | 25.32% | Locally caught at Coast | Test willingness to pay premium |
| Tilapia Fillets | 28.16% | Locally caught at Coast | Same as Red Snapper |

### Tier 3: Avoid at Launch (11 SKUs)

| Product | Margin | Reason |
|---|---|---|
| Arrowroot | -707.76% | KES 12 selling price vs KES 99 COGS — pricing error, fix immediately |
| Avocado | -40.81% | COGS exceeds selling price — pricing error, fix immediately |
| Chicken Drumstick | 6.92% | Near-zero margin |
| Black Passionfruit | 6.44% | Near-zero margin |
| Apple Pink Lady | 10.91% | Low margin, limited demand |
| Beef Sausages | 12.15% | Too thin for remote cold chain |
| Lamb Loin Chops | 11.55% | Too thin for remote cold chain |
| Imported Orange | 14.28% | Locally available at Coast |
| Broccoli | 19.16% | 1-day shelf life and low margin |
| Collar Bacon | 19.15% | Highest rejection in processed meats |
| Apple Fuji | 89.40%* | *COGS backfill artifact — buying_price record is incorrect (KES 5) |

---

## Section 4: Logistics Model Stress Test

Full queries in [`03_logistics_stress_test.sql`](../queries/03_logistics_stress_test.sql).

### Why synthetic costs were necessary

Query 3A (high-mileage route benchmark) returned **zero rows** for Jan–Mar 2026. This confirmed that Mara logistics expenses were not being recorded in the system during the analysis period, despite the route operating weekly. Trip costs were therefore modelled from operational parameters.

### Trip cost parameters

| Trip type | Fuel | On-demand | Lunch | Parking | Total |
|---|---|---|---|---|---|
| Combined N+S route (11 trips) | KES 18,000 | KES 13,000 | KES 2,000 | KES 750 | KES 33,750 |
| South-only route (2 trips) | KES 15,000 | KES 10,000 | KES 2,000 | KES 500 | KES 27,500 |

Distance basis: Haversine formula from warehouse coordinates, × 1.4 circuity factor for road distance. Nearest-neighbour TSP for multi-stop routing.

### Jan–Mar 2026 actuals

| Metric | Value |
|---|---|
| Trips | 13 |
| Orders | 152 |
| Revenue | KES 2,912,087 |
| Logistics cost | KES 426,250 |
| Net contribution | KES 766,541 (26.3%) |
| Best trip | 18 orders, KES 467K, 34% contribution |
| Weakest trip | 2 orders, 11% contribution (still positive) |

### Standalone break-even

KES 27,500 (South-only trip cost) ÷ 40.96% (gross margin) = **KES 67,139** minimum.  
Policy set at **KES 70,800** (5.5% buffer above break-even).

Three dispatches during the analysis period fell below this threshold. These were contribution-negative and should be co-loaded with community route orders in the Coast model.

### Real batching pattern (Query 3C)

Community runs (13–19 orders per dispatch): average order value KES 9,700–25,900.  
Standalone premium runs (1–2 orders): Lodge D averaging KES 78,593 per order — borderline vs. threshold, co-load wherever possible.

---

## Section 5: Assumptions and Data Integrity

### Metric definitions

| Metric | Definition |
|---|---|
| Gross margin | (SUM(selling_price × qty_dispatched) − SUM(cogs)) ÷ SUM(selling_price × qty_dispatched) |
| COGS | buying_price × qty_dispatched at time of order |
| Rejection rate | SUM(qty_rejected) ÷ SUM(qty_dispatched) |
| OTIF | on_time_delivery = true ÷ total non-null on_time_delivery records |

### Key assumptions

1. **COGS backfill.** 727 pre-March 2025 line items had NULL COGS (99.31% backfillable). Backfilled using buying_price × qty_dispatched. Validated: 5.39pp gap between backfilled (16.35%) and original (21.74%) Nairobi margin — slightly above 3pp target but acceptable at this row ratio. Blended margin of 24.50% is the correct figure.

2. **Synthetic order data.** 7,546 Mara orders generated for Oct 2024–Dec 2025. Real SKU pools, real price ranges, tagged SYN-MM-. Rate metrics (margin, OTIF, rejection) only compare across real records.

3. **Logistics cost modelling.** 13 records entered in logistics_expenses (LE-2026-05-001 to LE-2026-05-013), tagged SYNTHETIC in notes. One vehicle was registered in the system before analysis could proceed (vehicle_id assigned). A second active vehicle remains unregistered — partial logistics cost gap.

4. **Mara as Coast proxy.** Two Coast-specific adjustments applied to the Mara baseline: (1) local seafood availability risk factored into Tier 2/3 fish SKU assessment, (2) longer transit time (8–10 hrs vs. 6–7 hrs) applied to shelf life thresholds.

5. **Cancellation filter.** Status field uses 'Cancelled' (capital C). 31 orders excluded for confirmed customer-preference reasons. Operational cancellations retained.

6. **April 2026 excluded.** No Mara orders recorded in April 2026. Analysis period fixed.

### Data inconsistencies

| Issue | Status | Impact |
|---|---|---|
| NULL COGS pre-March 2025 | Resolved via backfill | <6pp margin effect |
| Active vehicle [VEH-001] unregistered in system | Resolved, ID assigned | Synthetic cost records entered |
| Active vehicle [VEH-002] unregistered | **Open** | Partial logistics cost gap |
| Mara orders not in route_orders | **Open** | Trip density untrackable from system |
| OTIF gap (2 of 153 real orders recorded) | **Open** | Mara OTIF is a synthetic proxy |
| Avocado and Arrowroot pricing errors | **Open** | Excluded from SKU tiers, fix immediately |
| Internal staff accounts in Mara customer groups | Resolved via name filter | No impact on metrics |
| Test accounts in production database | Resolved via name filter | No impact on metrics |
| Nairobi logistics Jan–Mar 2026 completely unrecorded | **Open** | No lease, fuel, on-demand or route distance data for active fleet. Cost-per-km derivation ruled out. 2025 actuals suggest contribution-negative. Requires backfill for reliable figure. |
