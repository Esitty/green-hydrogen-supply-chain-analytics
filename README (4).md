# Green Hydrogen Supply Chain Analytics

A relational database design and analytics project modelling a green hydrogen supply chain from production sites in Morocco, Namibia, and Egypt to European offtakers in Germany, the Netherlands, and France.

Built as part of an MSc Data Analytics module on Enterprise Data Warehouses and Database Management Systems, applying a structured forward engineering methodology — Introduce, Decompose, Build, Validate, Deploy and Document.

---

## Overview

Green hydrogen is produced through electrolysis powered by solar and wind energy. Africa has some of the best solar and wind resources in the world, while Europe is a major buyer under bilateral hydrogen partnerships (e.g. Germany's Nationale Wasserstoffstrategie). This project models the data infrastructure needed to manage that supply chain — from production and storage through to shipping, contracts, and financial performance.

---

## Database Schema

The database consists of **8 tables** covering 8 business domains:

| Domain | Table | Description |
|---|---|---|
| Production | `ProductionSites` | Hydrogen production facilities across Morocco, Namibia, Egypt |
| Supplier Management | `Suppliers` | Equipment and material suppliers per site |
| Storage | `StorageFacilities` | Export port storage facilities |
| Inventory | `StockInventory` | Variance between produced and stored hydrogen |
| Contract Management | `Contracts` | Agreements between producers and European offtakers |
| Offtakers | `Offtakers` | European buyers (Germany, Netherlands, France) |
| Shipments and Logistics | `Shipments` | Vessel movements from Africa to Europe |
| Financial Performance | `Financials` | Revenue, production cost, and logistics cost |

**Schema summary:** 8 primary keys, 11 foreign keys, normalised to 3NF.

---

## Entity Relationship Diagram

The ERD shows all 8 tables, primary keys, foreign keys, and relationships — including the many-to-many relationship between `ProductionSites` and `Offtakers`, resolved through the `Contracts` junction table.

*(See `/diagrams/erd.png`)*

---

## Views

| View | Purpose |
|---|---|
| `vw_offtaker_summary` | Commercial summary per European buyer — total shipments, volume delivered, fulfilment %, contract value |
| `vw_shipment_performance` | Tracks shipment delays and on-time/late/in-transit classification per route |

---

## Analytical Queries

| Query | Technique | Business Question |
|---|---|---|
| Query 1 | JOIN + GROUP BY | Which suppliers are most reliable on delivery time? |
| Query 2 | CASE classification | Which European offtakers are underserved relative to contracted volumes? |
| Query 3 | RANK() window function | How does each production site rank by monthly output? |

---

## Performance Optimisation

A composite index `idx_shipments_status_offtaker` on `Shipments(status, offtaker_id)` was added to optimise a frequently-run query filtering by delivery status and offtaker.

**Result:** Query cost reduced from **0.525** (two-step index lookup + filter) to **0.35** (single direct index lookup), confirmed via `EXPLAIN`.

---

## CAP Theorem

The system is designed as a **CP** (Consistent, Partition Tolerant) database:

- **Consistency** — required, as contract volumes and delivery records carry legal and financial weight across cross-border transactions
- **Partition Tolerance** — required, due to the transoceanic, multi-country infrastructure
- **Availability** — sacrificed, as returning an error is preferable to serving stale or conflicting commercial data

---

## Repository Contents

```
├── green_hydrogen_platform.sql   -- Full SQL: schema, data, views, queries, indexes, tests
├── README.md                     -- This file
└── diagrams/
    ├── erd.png                   -- Entity Relationship Diagram
    └── domain_isolation_map.png  -- Domain decomposition diagram
```

---

## SQL File Contents

The `green_hydrogen_platform.sql` file includes, in order:

1. Database and table creation (8 tables with constraints)
2. Sample data inserts (5–8 rows per table, referential integrity order)
3. Views (`vw_offtaker_summary`, `vw_shipment_performance`)
4. Analytical queries (JOIN+GROUP BY, CASE, RANK())
5. Performance optimisation (composite index + EXPLAIN)
6. Valid input tests
7. Invalid input tests (constraint violation checks)

---

## Tech Stack

- **Database:** MySQL 8.0
- **Tool:** MySQL Workbench

---

## Author

Henrietta Mensah — MSc Data Analytics, Berlin School of Business and Innovation
