# Coast Expansion Strategic Analysis

**Tools:** PostgreSQL · DBeaver · SQL  
**Skills demonstrated:** Data quality investigation · COGS backfill · Synthetic data generation · Business decision memo  
**Status:** Complete — recommendation issued May 2026

---

## The Business Question

A Kenyan agritech company serving Nairobi restaurants and lodges had been operating a remote market route (Maasai Mara, ~270 km from Nairobi) for several years. Leadership wanted to know: **should the company expand to the Kenyan Coast (~500 km)?**

My task was to use the company's operational database to:
1. Diagnose Mara market performance as a proxy for Coast viability
2. Recommend a product mix for Coast launch
3. Stress-test the logistics model
4. Issue a Go/No-Go recommendation backed by data

---

## The Answer

**Conditional Go.** Two conditions before the first route dispatches:
- Minimum 8 committed lodge accounts secured
- KES 70,800 minimum order value enforced for standalone premium deliveries

The margin case is strong: Mara delivers a **40.96% gross margin** vs **24.50% in Nairobi**, and a **26.3% contribution margin** (KES 766,541 net on KES 2.91M revenue across 13 real trips). Coast lodges share the same customer profile.

---

## Key Metrics

| Metric | Nairobi (Core) | Maasai Mara (Proxy) |
|---|---|---|
| Gross margin | 24.50% | 40.96% |
| Contribution margin | Not calculated* | 26.3% |
| Avg order value | KES 12,540 | KES 20,405 |
| OTIF | 56.19% | 84.76% |
| Rejection rate | 3.04% | 0.10% |
| Unique customers | 150 | 8 |

*Nairobi logistics costs for the analysis period were not recorded in the system — see Technical Appendix, Section 5.

---

## What Made This Analysis Hard

This was not a clean dataset. Before any analysis could begin, I had to investigate and resolve several data integrity issues:

**1. NULL COGS on 85,600+ line items**  
All Nairobi orders prior to March 2025 had NULL cost-of-goods-sold, producing an artifactual gross margin of 75%+. I backfilled using `buying_price × quantity_dispatched` from `product_unit_variants` — confirmed as the same formula the system uses when COGS is live. After backfill, the real Nairobi margin corrected to 24.50% and Mara to 40.96% — a complete reversal of the initial finding.

**2. NULL filter bug silently dropping 374 companies**  
A `WHERE NOT IN (1, 5)` filter on `customer_group_id` was silently excluding all 374 Nairobi companies with NULL group IDs (the majority). Fixed using a `CASE WHEN` statement. Validated that the correct Nairobi customer count is 150, not 16.

**3. No real Mara data before January 2026**  
The Mara route launched in late 2024 but real data only existed in the system from January 2026 — 10 weeks, 153 orders. I generated 7,546 synthetic orders (Oct 2024–Dec 2025) calibrated to real lodge ordering patterns to enable meaningful volume comparisons. All synthetic records are tagged `SYN-MM-` and excluded from rate metrics (margin, OTIF, rejection rate).

**4. Logistics costs not recorded for the analysis period**  
Zero logistics expense records existed for Mara trips in Jan–Mar 2026 despite the route operating. I modelled 13 trip costs using operational parameters (fuel rates, on-demand cost, crew allowances), entered them as synthetic records in `logistics_expenses` tagged `SYNTHETIC`, and verified against known Nairobi per-km benchmarks.

**5. Pricing errors on two SKUs**  
Avocado was selling below COGS (-40.81% margin). Arrowroot had a data entry error producing a -707.76% margin (KES 12 selling price vs KES 99 COGS). Both excluded from the product tier analysis and flagged to operations.

---

## Repository Structure

```
coast-expansion-analysis/
│
├── README.md                        ← You are here
│
├── memo/
│   └── decision-memo.md             ← Go/No-Go recommendation for leadership
│
├── queries/
│   ├── 00_standard_filter.sql       ← Exclusion logic applied to every query
│   ├── 01_market_performance.sql    ← OTIF, margin, rejection rate by market
│   ├── 02_product_mix.sql           ← SKU tiering: margin, volatility, shelf life
│   ├── 03_logistics_stress_test.sql ← Trip cost modelling, break-even, batching
│   └── 04_data_integrity.sql        ← COGS backfill scope check, UPDATE, validation
│
├── docs/
│   └── technical-appendix.md        ← Full methodology, assumptions, data issues
│
└── data/
    └── data-dictionary.md           ← Schema reference (no raw data included)
```

---

## Data & Privacy Note

No raw company data is included in this repository. The database is a proprietary operational system. What is included:
- All SQL queries used in the analysis
- Aggregated outputs (totals, percentages, rates) with customer names anonymised
- Synthetic Mara order data parameters (not the actual generated records)
- Full methodology documentation

Customer lodge names have been replaced with Lodge A–H. Employee and vehicle references use placeholder identifiers.

---

## Product Launch Recommendation Summary

**15 SKUs cleared for immediate launch** — led by Celery (most ordered), Apple Crispy Red (highest revenue), Watermelon, Banana Kampala, Alika Potato. Full margin and rejection data in the Technical Appendix.

**16 SKUs for careful piloting** — includes high-revenue items where shelf life, supply consistency, or margin requires initial volume controls.

**11 SKUs to avoid at launch** — two confirmed pricing errors, remainder too thin for remote cold chain economics.

---

## Analyst

Teresiah Njoroge · [linkedin.com/in/teresiah-njoroge](https://www.linkedin.com/in/teresiah-njoroge) · [github.com/TeresiahNjoroge](https://github.com/TeresiahNjoroge)
