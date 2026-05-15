# Data Dictionary

**Database:** Agritech company operational database (PostgreSQL)  
**Note:** No raw data is included in this repository. This dictionary describes the schema used in the analysis queries.

---

## Tables Used

### `orders`
Primary order header table.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| company_id | uuid | FK to companies |
| total_amount | numeric | Invoice total (KES) |
| shipping_cost | numeric | Delivery fee charged |
| status | varchar | e.g. 'Delivered', 'Cancelled' |
| cancellation_reason | varchar | Free text, populated on cancellation |
| on_time_delivery | boolean | NULL if not assessed |
| dispatched_at | timestamp | When vehicle left warehouse |
| order_date | date | Order placement date |
| order_number | varchar | Human-readable ID; SYN-MM- prefix = synthetic |
| deleted_at | timestamp | Soft delete; NULL = active |

### `companies`
Customer accounts.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| name | varchar | Company name |
| customer_group_id | int | NULL = Nairobi core; 1 or 5 = Maasai Mara |

### `order_line_items`
One row per product-variant per order.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| order_id | uuid | FK to orders |
| product_unit_variant_id | uuid | FK to product_unit_variants |
| selling_price | numeric | Price per unit at time of order (KES) |
| quantity_dispatched | numeric | Units sent |
| quantity_rejected | numeric | Units returned by customer |
| cogs | numeric | Cost of goods sold per unit. NULL pre-March 2025 (backfilled — see Query A2) |
| metadata | jsonb | Audit trail; includes `cogs_source` tag for backfilled rows |
| deleted_at | timestamp | Soft delete |

### `product_unit_variants`
Pricing and buying cost by unit type.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| buying_price | numeric | Purchase cost per unit (KES). Used as COGS proxy in backfill. |
| product_grade_variant_id | uuid | FK to product_grade_variants |

### `product_grade_variants`
Grade definitions per product.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| product_id | uuid | FK to products |

### `products`
Master product catalogue.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| name | varchar | Product name |
| category_id | uuid | FK to categories |

### `categories`
Product category groupings.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| name | varchar | Category name |

### `inventory_adjustments`
Stock loss and adjustment records.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| product_unit_variant_id | uuid | FK to product_unit_variants |
| category | varchar | 'loss', 'gain', etc. |
| reason | varchar | Free text. Classified via ILIKE patterns in Query 1C. |
| quantity | numeric | Units adjusted |
| deleted_at | timestamp | Soft delete |

### `logistics_expenses`
Trip cost records.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| reference | varchar | Human ID; LE-2026-05-XXX = synthetic records |
| vehicle_id | int | FK to vehicles |
| driver_id | int | FK to drivers |
| date | date | Trip date |
| type | varchar | 'fuel', 'on_demand', etc. |
| cost | numeric | Trip cost (KES) |
| first_mileage | numeric | Odometer at trip start |
| last_mileage | numeric | Odometer at trip end |
| total_mileage | numeric | last_mileage − first_mileage |
| notes | varchar | 'SYNTHETIC' for modelled records |
| status | varchar | 'pending', 'approved', etc. |
| deleted_at | timestamp | Soft delete |

### `routes` + `route_orders`
Route planning tables.

| Column | Type | Description |
|---|---|---|
| routes.id | uuid | Primary key |
| routes.vehicle_id | int | FK to vehicles |
| routes.date | date | Dispatch date |
| routes.type | varchar | 'last_mile', 'collection', etc. |
| route_orders.route_id | uuid | FK to routes |
| route_orders.id | uuid | FK to orders |

**Note:** Mara orders during Jan–Mar 2026 are dispatched via Trackpod but are not linked to `route_orders`. This means route density and cost-per-order cannot be tracked from the system — a data gap flagged in the decision memo.

### `vehicles` + `drivers` + `users`

| Table | Key columns |
|---|---|
| vehicles | id (int), registration_number, vehicle_type |
| drivers | id (int), user_id |
| users | id (int), name |

---

## Anonymisation Note

Customer lodge names appearing in the analysis results have been replaced with generic identifiers (Lodge A–H). Employee names and vehicle registration numbers have been replaced with placeholder identifiers ([VEH-001], [DRIVER_A], etc.). Database-level IDs (vehicle_id, driver_id) have been removed from public documentation.

The company name has been replaced with a fictional identifier (FreshRoute Kenya). All outputs are anonymised to protect the data source.
