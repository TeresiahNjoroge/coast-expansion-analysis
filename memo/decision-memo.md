# Coast Expansion: Decision Memo

**Prepared by:** Teresiah Njoroge  
**Date:** May 2026  
**Database:** Operational PostgreSQL (DBeaver)  
**Full methodology:** See [Technical Appendix](../docs/technical-appendix.md)

---

## Recommendation: Conditional Go

Proceed with Coast expansion. Two conditions must be met before the first route dispatches:

1. Minimum **8 committed lodge accounts** secured
2. **KES 70,800 minimum order value** enforced for standalone premium deliveries

---

## Why Go

**The margin case is strong.**  
Maasai Mara's gross margin is **40.96%** vs Nairobi's **24.50%**. After fully loading all logistics costs across 13 real trips (January–March 2026), Mara delivers a **26.3% contribution margin**, generating KES 766,541 net on KES 2.91M revenue. Lodge customers absorb the costs of remote procurement into their pricing. Coast lodges share the same customer profile. Mara's average order value has grown from KES 4,264 in June 2024 to KES 20,405 by March 2026 — a 379% increase driven by maturing lodge relationships and larger basket sizes.

**The logistics model is proven.**  
Mara runs on a two-tier batching model: weekly community route (target 13+ orders) plus a premium standalone threshold of KES 70,800. Every Mara trip was contribution-positive. The same model transfers directly to Coast, with an estimated route cost of KES 35,000–40,000 (480–530 km one-way vs. 270 km to Mara).

**Remote market operational performance is materially better.**  
OTIF: **84.76%** (Mara) vs. **56.19%** (Nairobi). Rejection rate: **0.10%** vs. **3.04%**. Fixed weekly delivery days and deliberate lodge bulk ordering outperform daily Nairobi multi-stop routes on every metric.

---

## Key Numbers

| Metric | Nairobi | Maasai Mara |
|---|---|---|
| Gross margin | 24.50% | 40.96% |
| Contribution margin | Not calculated (see note) | 26.3% |
| Avg order value | KES 12,540 | KES 20,405 |
| OTIF | 56.19% | 84.76% |
| Rejection rate | 3.04% | 0.10% |

> **Note on Nairobi contribution margin:** Logistics costs for Jan–Mar 2026 are not recorded in the system. No lease, fuel, or on-demand entries exist for the active Nairobi fleet. No route distance data exists either, ruling out a cost-per-km derivation. Based on 2025 actuals (~KES 588K/month across fuel, lease, and on-demand), Nairobi logistics costs significantly exceed gross profit, suggesting the segment is contribution-negative. A reliable figure requires cost entries to be backfilled for this period.

---

## Biggest Risk

**Customer concentration.**  
Eight customers generate all of Mara's revenue. Lodge A (highest-volume account) alone accounts for **68% of order volume**. One anchor lodge pausing orders collapses route density below the viable threshold. Coast expansion replicates this vulnerability unless the customer base is diversified from day one.

---

## Required Fixes Before Launch

| Fix | Why it matters |
|---|---|
| Link orders to route system | Dispatch happens via Trackpod but is not connected to the internal system. Route density and cost per order are currently untrackable. |
| Enforce minimum order value policy | Standalone runs below KES 70,800 do not break even at current margins. |
| Improve Nairobi OTIF from 56.19% | A delivery failure in Nairobi is recoverable same day. A failure at Coast requires a 1,000 km round trip. |
| Fix two SKU pricing errors | Avocado and Arrowroot are both selling below COGS. Must be corrected before any new market launch. |

---

## Product Launch List

**15 SKUs cleared for immediate launch.** Led by Celery (most ordered), Apple Crispy Red (highest revenue at KES 29.2M), Watermelon, Banana Kampala, and Alika Potato. Full list in the technical appendix.

**16 SKUs for careful piloting.** Includes Sirloin Steak (KES 9.6M revenue, margin below threshold) and Breakfast Coffee 500g (KES 13.3M revenue, limited real order history). Conditions per SKU in the technical appendix.

**11 SKUs to avoid at launch.** Two confirmed pricing errors. The rest have margins too thin for remote cold chain economics.

> **Note on wastage:** Analysis confirms that >97% of wastage is warehouse-side (overprocurement, cold room failures, storage issues) and stays in Nairobi regardless of which markets are served. The Coast-specific risk is customer rejection only. Mara lodges reject just 0.10% of dispatched quantity — the same pattern is expected at Coast.

---

## Logistics Model: Future Horizon

The two-tier weekly batching model is the correct Day 1 structure. A regional cold storage hub at the Coast becomes viable at approximately 400–500 weekly orders, expected in the 18–24 month horizon if Coast growth follows the Mara trajectory. Not a launch requirement, but should be in the 2-year plan.

---

## Data Confidence: Medium

Logistics costs are modelled from operational parameters, not actual invoices. Mara OTIF is a synthetic proxy (only 2 of 153 real orders have it recorded). Real Mara data covers 10 weeks. These gaps do not change the recommendation, but must be closed before a Coast analysis reaches high confidence.

Full methodology, queries, and data integrity notes in the [Technical Appendix](../docs/technical-appendix.md).
