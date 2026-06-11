-- GREEN HYDROGEN SUPPLY CHAIN ANALYTICS PLATFORM
-- Africa to European Export Markets
-- Author: Henrietta Mensah
-- ============================================================
-- Forward Engineering Methodology:
-- Step 1  - Business Requirements Defined
-- Step 2  - Risks and Objectives Set
-- Step 3  - Main and Sub-Scenarios Mapped
-- Step 4  - Domains Isolated (8 domains)
-- Step 5  - Variables and Attributes Defined per Domain
-- Step 6  - Schema Designed, PKs and FKs Documented
-- Step 7  - Pseudocode Written Before SQL
-- Step 8  - SQL Written From Pseudocode (this file)
-- Step 9  - Tested with Valid Inputs
-- Step 10 - Tested with Invalid Inputs
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS green_hydrogen_db;
USE green_hydrogen_db;

-- ============================================================
-- SECTION 2: TABLE CREATION
-- Domain 1: ProductionSites
-- Domain 2: Suppliers
-- Domain 3: StorageFacilities
-- Domain 4: StockInventory
-- Domain 5: Offtakers
-- Domain 6: Contracts
-- Domain 7: Shipments
-- Domain 8: Financials
-- ============================================================

-- Domain 1: ProductionSites
-- Where green hydrogen is produced in Morocco, Namibia and Egypt
CREATE TABLE ProductionSites (
    site_id              INT PRIMARY KEY AUTO_INCREMENT,
    site_name            VARCHAR(100)  NOT NULL,
    country              VARCHAR(50)   NOT NULL,
    region               VARCHAR(50)   NOT NULL,
    production_method    VARCHAR(50)   NOT NULL DEFAULT 'Green',
    capacity_kg_per_day  DECIMAL(10,2) NOT NULL,
    operational_since    DATE          NOT NULL,
    status               VARCHAR(20)   NOT NULL
        CHECK (status IN ('Active','Inactive','Under Maintenance'))
);

-- Domain 2: Suppliers
-- Equipment and material suppliers serving each production site
CREATE TABLE Suppliers (
    supplier_id          INT PRIMARY KEY AUTO_INCREMENT,
    site_id              INT           NOT NULL,
    supplier_name        VARCHAR(100)  NOT NULL,
    country              VARCHAR(50)   NOT NULL,
    supply_category      VARCHAR(50)   NOT NULL,
    contracted_lead_days INT           NOT NULL,
    contract_start       DATE          NOT NULL,
    FOREIGN KEY (site_id) REFERENCES ProductionSites(site_id)
);

-- Domain 3: StorageFacilities
-- Export port facilities where hydrogen is held before shipment
CREATE TABLE StorageFacilities (
    storage_id      INT PRIMARY KEY AUTO_INCREMENT,
    site_id         INT           NOT NULL,
    facility_name   VARCHAR(100)  NOT NULL,
    storage_type    VARCHAR(50)   NOT NULL,
    capacity_kg     DECIMAL(15,2) NOT NULL,
    location_port   VARCHAR(100)  NOT NULL,
    FOREIGN KEY (site_id) REFERENCES ProductionSites(site_id)
);

-- Domain 4: StockInventory
-- Tracks variance between hydrogen produced and hydrogen stored
CREATE TABLE StockInventory (
    inventory_id       INT PRIMARY KEY AUTO_INCREMENT,
    site_id            INT           NOT NULL,
    storage_id         INT           NOT NULL,
    record_date        DATE          NOT NULL,
    volume_produced_kg DECIMAL(15,2) NOT NULL CHECK (volume_produced_kg >= 0),
    volume_stored_kg   DECIMAL(15,2) NOT NULL CHECK (volume_stored_kg >= 0),
    variance_kg        DECIMAL(15,2) GENERATED ALWAYS AS
                       (volume_produced_kg - volume_stored_kg) STORED,
    FOREIGN KEY (site_id)    REFERENCES ProductionSites(site_id),
    FOREIGN KEY (storage_id) REFERENCES StorageFacilities(storage_id)
);

-- Domain 5: Offtakers
-- European buyers purchasing green hydrogen under long-term contracts
CREATE TABLE Offtakers (
    offtaker_id      INT PRIMARY KEY AUTO_INCREMENT,
    company_name     VARCHAR(100)  NOT NULL,
    country          VARCHAR(50)   NOT NULL,
    city             VARCHAR(50)   NOT NULL,
    sector           VARCHAR(50)   NOT NULL,
    annual_demand_kg DECIMAL(15,2) NOT NULL
);

-- Domain 6: Contracts
-- Formal agreements between African producers and European offtakers
-- Resolves many-to-many: ProductionSites <-> Offtakers
CREATE TABLE Contracts (
    contract_id          INT PRIMARY KEY AUTO_INCREMENT,
    site_id              INT           NOT NULL,
    offtaker_id          INT           NOT NULL,
    contracted_volume_kg DECIMAL(15,2) NOT NULL,
    price_per_kg_eur     DECIMAL(8,2)  NOT NULL,
    contract_start       DATE          NOT NULL,
    contract_end         DATE          NOT NULL,
    transit_days_agreed  INT           NOT NULL,
    status               VARCHAR(20)   NOT NULL
        CHECK (status IN ('Active','Expired','Suspended')),
    FOREIGN KEY (site_id)     REFERENCES ProductionSites(site_id),
    FOREIGN KEY (offtaker_id) REFERENCES Offtakers(offtaker_id)
);

-- Domain 7: Shipments
-- Each vessel movement from a storage facility to a European offtaker
CREATE TABLE Shipments (
    shipment_id          INT PRIMARY KEY AUTO_INCREMENT,
    contract_id          INT           NOT NULL,
    storage_id           INT           NOT NULL,
    offtaker_id          INT           NOT NULL,
    vessel_name          VARCHAR(100)  NOT NULL,
    departure_dt         DATE          NOT NULL,
    expected_arrival_dt  DATE          NOT NULL,
    actual_arrival_dt    DATE,
    volume_kg_loaded     DECIMAL(15,2) NOT NULL CHECK (volume_kg_loaded > 0),
    volume_kg_delivered  DECIMAL(15,2),
    status               VARCHAR(20)   NOT NULL
        CHECK (status IN ('In Transit','Delivered','Delayed','Lost')),
    FOREIGN KEY (contract_id)  REFERENCES Contracts(contract_id),
    FOREIGN KEY (storage_id)   REFERENCES StorageFacilities(storage_id),
    FOREIGN KEY (offtaker_id)  REFERENCES Offtakers(offtaker_id)
);

-- Domain 8: Financials
-- Revenue, production cost and logistics cost per site and contract per quarter
CREATE TABLE Financials (
    financial_id        INT PRIMARY KEY AUTO_INCREMENT,
    site_id             INT           NOT NULL,
    contract_id         INT           NOT NULL,
    fiscal_year         INT           NOT NULL,
    quarter             INT           NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    revenue_eur         DECIMAL(15,2) NOT NULL CHECK (revenue_eur >= 0),
    production_cost_eur DECIMAL(15,2) NOT NULL CHECK (production_cost_eur >= 0),
    logistics_cost_eur  DECIMAL(15,2) NOT NULL CHECK (logistics_cost_eur >= 0),
    FOREIGN KEY (site_id)     REFERENCES ProductionSites(site_id),
    FOREIGN KEY (contract_id) REFERENCES Contracts(contract_id)
);

-- ============================================================
-- DOMAIN KEY SUMMARY
-- ============================================================
-- Domain               | PKs | FKs | References
-- ProductionSites      |  1  |  0  | Root domain
-- Suppliers            |  1  |  1  | ProductionSites
-- StorageFacilities    |  1  |  1  | ProductionSites
-- StockInventory       |  1  |  2  | ProductionSites, StorageFacilities
-- Offtakers            |  1  |  0  | Root domain
-- Contracts            |  1  |  2  | ProductionSites, Offtakers
-- Shipments            |  1  |  3  | Contracts, StorageFacilities, Offtakers
-- Financials           |  1  |  2  | ProductionSites, Contracts
-- TOTAL                |  8  | 11  |
-- ============================================================

-- SECTION 3: INSERT SAMPLE DATA

INSERT INTO ProductionSites
    (site_name, country, region, production_method,
     capacity_kg_per_day, operational_since, status)
VALUES
    ('Guelmim Solar H2 Plant',  'Morocco', 'Guelmim-Oued Noun',
     'Green', 12000.00, '2022-03-01', 'Active'),
    ('Dakhla Wind H2 Facility', 'Morocco', 'Dakhla-Oued Ed-Dahab',
     'Green',  8500.00, '2023-01-15', 'Active'),
    ('Hyphen H2 Namibia',       'Namibia', 'Karas Region',
     'Green', 15000.00, '2021-11-01', 'Active'),
    ('Scatec Suez H2 Plant',    'Egypt',   'Suez Canal Economic Zone',
     'Green',  6000.00, '2023-06-01', 'Active'),
    ('NWFE Aswan H2 Facility',  'Egypt',   'Aswan',
     'Green',  9500.00, '2022-08-20', 'Under Maintenance');
     
INSERT INTO Offtakers
    (company_name, country, city, sector, annual_demand_kg)
VALUES
    ('RWE Supply & Trading', 'Germany',     'Essen',     'Power',      4500000.00),
    ('Thyssenkrupp Steel',   'Germany',     'Duisburg',  'Industrial', 6200000.00),
    ('Shell Energy Europe',  'Netherlands', 'Rotterdam', 'Chemical',   8000000.00),
    ('Air Products Europe',  'Netherlands', 'Amsterdam', 'Industrial', 3500000.00),
    ('TotalEnergies SE',     'France',      'Paris',     'Power',      5100000.00);
    
INSERT INTO Suppliers
    (site_id, supplier_name, country, supply_category,
     contracted_lead_days, contract_start)
VALUES
    (1, 'Nel Hydrogen AS',   'Norway',  'Electrolyser', 30, '2022-01-01'),
    (2, 'ITM Power',         'UK',      'Electrolyser', 45, '2023-01-01'),
    (3, 'Linde Engineering', 'Germany', 'Compressor',   21, '2021-09-01'),
    (4, 'Air Liquide',       'France',  'Storage Tank', 28, '2023-05-01'),
    (1, 'Siemens Energy',    'Germany', 'Power Systems',14, '2022-02-01');
    
INSERT INTO StorageFacilities
    (site_id, facility_name, storage_type, capacity_kg, location_port)
VALUES
    (1, 'Guelmim H2 Tank',       'Compressed Gas',  500000.00, 'Port of Agadir'),
    (2, 'Dakhla Export Terminal', 'Liquid Hydrogen', 350000.00, 'Port of Dakhla'),
    (3, 'Lüderitz H2 Terminal',  'Liquid Hydrogen', 750000.00, 'Port of Lüderitz'),
    (4, 'Suez Ammonia Carrier',  'Ammonia Carrier', 280000.00, 'Port of Suez'),
    (1, 'Agadir Ammonia Tank',   'Ammonia Carrier', 420000.00, 'Port of Agadir');
    
INSERT INTO Contracts
    (site_id, offtaker_id, contracted_volume_kg, price_per_kg_eur,
     contract_start, contract_end, transit_days_agreed, status)
VALUES
    (1, 1, 1800000.00, 4.50, '2023-01-01', '2025-12-31', 21, 'Active'),
    (3, 2, 2500000.00, 4.80, '2022-06-01', '2025-05-31', 18, 'Active'),
    (3, 3, 3200000.00, 5.10, '2022-01-01', '2024-12-31', 16, 'Active'),
    (2, 4, 1200000.00, 4.60, '2023-03-01', '2026-02-28', 19, 'Active'),
    (4, 5, 1500000.00, 4.70, '2023-07-01', '2026-06-30', 22, 'Active');
    
INSERT INTO StockInventory
    (site_id, storage_id, record_date,
     volume_produced_kg, volume_stored_kg)
VALUES
    (1, 1, '2024-01-31', 360000.00, 352000.00),
    (1, 1, '2024-02-29', 336000.00, 329500.00),
    (3, 3, '2024-01-31', 450000.00, 441000.00),
    (3, 3, '2024-02-29', 420000.00, 414000.00),
    (2, 2, '2024-01-31', 255000.00, 250000.00),
    (2, 2, '2024-02-29', 238000.00, 233500.00),
    (4, 4, '2024-01-31', 180000.00, 174000.00),
    (4, 4, '2024-02-29', 168000.00, 163000.00);
    
INSERT INTO Shipments
    (contract_id, storage_id, offtaker_id, vessel_name,
     departure_dt, expected_arrival_dt, actual_arrival_dt,
     volume_kg_loaded, volume_kg_delivered, status)
VALUES
    (1,1,1,'MV Agadir Pioneer',  '2024-01-05','2024-01-26','2024-01-24',
     148000.00, 146500.00, 'Delivered'),
    (2,3,2,'MV Lüderitz Express','2024-01-08','2024-01-26','2024-01-30',
     195000.00, 193000.00, 'Delivered'),
    (3,3,3,'MV Namibia Star',    '2024-01-12','2024-01-28','2024-01-27',
     260000.00, 258000.00, 'Delivered'),
    (4,2,4,'MV Dakhla Wind',     '2024-02-01','2024-02-20','2024-02-25',
     98000.00,  96500.00,  'Delivered'),
    (5,4,5,'MV Suez Green',      '2024-02-10','2024-03-04','2024-03-02',
     122000.00, 120500.00, 'Delivered'),
    (1,1,1,'MV Morocco Hydrogen','2024-03-01','2024-03-22', NULL,
     151000.00, NULL,       'In Transit'),
    (3,3,3,'MV Atlantic Green',  '2024-03-05','2024-03-21', NULL,
     265000.00, NULL,       'In Transit');
     
INSERT INTO Financials
    (site_id, contract_id, fiscal_year, quarter,
     revenue_eur, production_cost_eur, logistics_cost_eur)
VALUES
    (1, 1, 2024, 1,  666000.00, 310000.00,  85000.00),
    (3, 2, 2024, 1,  936000.00, 420000.00, 102000.00),
    (3, 3, 2024, 1, 1323000.00, 580000.00, 130000.00),
    (2, 4, 2024, 1,  451800.00, 210000.00,  62000.00),
    (4, 5, 2024, 1,  566400.00, 265000.00,  78000.00),
    (1, 1, 2023, 4,  648000.00, 305000.00,  83000.00),
    (3, 3, 2023, 4, 1290000.00, 571000.00, 128000.00);
    
 
-- SECTION 4: VIEWS 
#View 1: This tracks with delay calculation and on-time classification.
#This is useful for logistics managers to monitor delivery performance across transoceanic routes.

CREATE OR REPLACE VIEW vw_offtaker_summary AS
SELECT
    o.company_name,
    o.country  AS market,
    o.sector,
    COUNT(s.shipment_id) AS total_shipments,
    COALESCE(SUM(s.volume_kg_delivered), 0) AS total_volume_delivered_kg,
    c.contracted_volume_kg,
    ROUND(
        COALESCE(SUM(s.volume_kg_delivered), 0)
        / c.contracted_volume_kg * 100, 1)  AS fulfilment_pct,
    ROUND(c.contracted_volume_kg
        * c.price_per_kg_eur, 2)   AS total_contract_value_eur
FROM Offtakers o
JOIN Contracts  c ON o.offtaker_id  = c.offtaker_id
LEFT JOIN Shipments s
    ON  s.offtaker_id = o.offtaker_id
    AND s.status      = 'Delivered'
GROUP BY o.offtaker_id, o.company_name, o.country,
         o.sector, c.contracted_volume_kg,
         c.price_per_kg_eur;

-- View 2: vw_shipment_performance
-- Tracks every shipment with delay calculation and on-time
-- classification across all transoceanic routes.
-- Useful for logistics managers identifying which routes and
-- vessels consistently miss contracted transit times.

CREATE OR REPLACE VIEW vw_shipment_performance AS
SELECT
    s.shipment_id,
    ps.site_name       AS origin_site,
    ps.country         AS origin_country,
    o.company_name   AS offtaker,
    o.country        AS destination_country,
    s.vessel_name,
    s.departure_dt,
    s.expected_arrival_dt,
    s.actual_arrival_dt,
    s.volume_kg_loaded,
    s.volume_kg_delivered,
    s.status,
    CASE
        WHEN s.actual_arrival_dt IS NULL THEN NULL
        WHEN DATEDIFF(s.actual_arrival_dt,
             s.expected_arrival_dt) > 0
            THEN DATEDIFF(s.actual_arrival_dt,
                 s.expected_arrival_dt)
        ELSE 0
    END   AS delay_days,
    CASE
        WHEN s.actual_arrival_dt IS NULL THEN 'In Transit'
        WHEN DATEDIFF(s.actual_arrival_dt,
             s.expected_arrival_dt) > 0     THEN 'Late'
        ELSE 'On Time'
    END   AS delivery_status
FROM Shipments s
JOIN Contracts       c  ON s.contract_id = c.contract_id
JOIN ProductionSites ps ON c.site_id     = ps.site_id
JOIN Offtakers       o  ON s.offtaker_id = o.offtaker_id;


-- SECTION 5: ANANLYTICAL QUERIES 
-- Query 1: JOIN + GROUP BY
-- Business question: Which suppliers are most reliable in
-- delivering equipment to production sites on time?
-- Technique: Four-table JOIN with GROUP BY and derived
-- on-time rate using conditional SUM and NULLIF
-- Insight: Ranks suppliers by reliability so procurement
-- teams can identify which suppliers put production at risk

SELECT
    sup.supplier_name,
    ps.site_name,
    ps.country    AS site_country,
    sup.supply_category,
    sup.contracted_lead_days,
    COUNT(s.shipment_id)  AS total_shipments,
    SUM(CASE
            WHEN s.actual_arrival_dt IS NOT NULL
             AND DATEDIFF(s.actual_arrival_dt,
                 s.expected_arrival_dt) <= 0
            THEN 1 ELSE 0
        END)    AS on_time_deliveries,
    ROUND(
        SUM(CASE
                WHEN s.actual_arrival_dt IS NOT NULL
                 AND DATEDIFF(s.actual_arrival_dt,
                     s.expected_arrival_dt) <= 0
                THEN 1 ELSE 0
            END)
        / NULLIF(COUNT(s.shipment_id),0) * 100, 1)
AS on_time_rate_pct
FROM Suppliers sup
JOIN ProductionSites ps ON sup.site_id   = ps.site_id
JOIN Contracts       c  ON c.site_id     = ps.site_id
JOIN Shipments       s  ON s.contract_id = c.contract_id
GROUP BY sup.supplier_id, sup.supplier_name,
         ps.site_name, ps.country,
         sup.supply_category, sup.contracted_lead_days
ORDER BY on_time_rate_pct DESC;

-- Query 2: CASE Statement
-- Business question: Which European offtakers are being
-- underserved relative to their contracted volumes?
-- Technique: LEFT JOIN with CASE classification into
-- On Track, At Risk, or Underserved tiers
-- Insight: Gives commercial teams an immediate view of
-- which buyers are at risk of triggering penalty clauses
SELECT
    o.company_name,
    o.country    AS market,
    o.sector,
    c.contracted_volume_kg,
    COALESCE(SUM(s.volume_kg_delivered), 0) AS total_delivered_kg,
    ROUND(
        COALESCE(SUM(s.volume_kg_delivered), 0)
        / c.contracted_volume_kg * 100, 1)  AS fulfilment_rate_pct,
    CASE
        WHEN ROUND(
             COALESCE(SUM(s.volume_kg_delivered), 0)
             / c.contracted_volume_kg * 100, 1) >= 95
            THEN 'On Track'
        WHEN ROUND(
             COALESCE(SUM(s.volume_kg_delivered), 0)
             / c.contracted_volume_kg * 100, 1) >= 80
            THEN 'At Risk'
        ELSE 'Underserved'
    END    AS fulfilment_status
FROM Offtakers o
JOIN Contracts  c ON o.offtaker_id  = c.offtaker_id
LEFT JOIN Shipments s
    ON  s.offtaker_id = o.offtaker_id
    AND s.status      = 'Delivered'
GROUP BY o.offtaker_id, o.company_name, o.country,
         o.sector, c.contracted_volume_kg
ORDER BY fulfilment_rate_pct ASC;


-- Query 3: Window Function — RANK()
-- Business question: How does each production site rank
-- against others by monthly hydrogen output?
-- Technique: RANK() OVER (PARTITION BY month) resets the
-- ranking counter independently for each month
-- Insight: A site dropping unexpectedly in monthly rank
-- signals a capacity or maintenance issue requiring
-- investigation before it affects shipment schedules

SELECT
    DATE_FORMAT(si.record_date, '%Y-%m')    AS month,
    ps.site_name,
    ps.country,
    SUM(si.volume_produced_kg)              AS total_produced_kg,
    RANK() OVER (
        PARTITION BY DATE_FORMAT(si.record_date, '%Y-%m')
        ORDER BY SUM(si.volume_produced_kg) DESC
    )                                       AS output_rank
FROM StockInventory si
JOIN ProductionSites ps ON si.site_id = ps.site_id
GROUP BY DATE_FORMAT(si.record_date, '%Y-%m'),
         ps.site_id, ps.site_name, ps.country
ORDER BY month, output_rank;


-- SECTION 6: VALID INPUT TESTS 

-- Valid insert: new active production site in Morocco
INSERT INTO ProductionSites
    (site_name, country, region, production_method,
     capacity_kg_per_day, operational_since, status)
VALUES
    ('Laayoune H2 Plant', 'Morocco', 'Laayoune-Sakia El Hamra',
     'Green', 10000.00, '2024-01-01', 'Active');

-- Valid insert: new supplier linked to site_id 1
INSERT INTO Suppliers
    (site_id, supplier_name, country,
     supply_category, contracted_lead_days, contract_start)
VALUES
    (1, 'Thyssenkrupp Nucera', 'Germany',
     'Electrolyser', 35, '2024-03-01');

-- Valid insert: new delivered shipment
INSERT INTO Shipments
    (contract_id, storage_id, offtaker_id, vessel_name,
     departure_dt, expected_arrival_dt, actual_arrival_dt,
     volume_kg_loaded, volume_kg_delivered, status)
VALUES
    (2, 3, 2, 'MV Namibia Express',
     '2024-04-01', '2024-04-19', '2024-04-18',
     200000.00, 198500.00, 'Delivered');

-- Valid insert: stock inventory record
INSERT INTO StockInventory
    (site_id, storage_id, record_date,
     volume_produced_kg, volume_stored_kg)
VALUES
    (1, 1, '2024-03-31', 372000.00, 365000.00);
    
-- SECTION 7: INVALID INPUT TESTS (Step 10)
-- Each statement below should be REJECTED by MySQL

-- Test 1: NULL in a NOT NULL field
-- Expected error: Column 'site_name' cannot be null
INSERT INTO ProductionSites
    (site_name, country, region, production_method,
     capacity_kg_per_day, operational_since, status)
VALUES
    (NULL, 'Morocco', 'Guelmim', 'Green',
     10000.00, '2024-01-01', 'Active');

-- Test 2: Invalid CHECK constraint on status
-- Expected error: CHECK constraint violation
INSERT INTO ProductionSites
    (site_name, country, region, production_method,
     capacity_kg_per_day, operational_since, status)
VALUES
    ('Test Site', 'Morocco', 'Guelmim', 'Green',
     10000.00, '2024-01-01', 'Closed');

-- Test 3: Foreign key violation
-- Expected error: Cannot add or update — foreign key constraint fails
-- site_id 99 does not exist in ProductionSites
INSERT INTO Suppliers
    (site_id, supplier_name, country,
     supply_category, contracted_lead_days, contract_start)
VALUES
    (99, 'Test Supplier', 'Germany',
     'Electrolyser', 30, '2024-01-01');

-- Test 4: Negative volume violating CHECK constraint
-- Expected error: CHECK constraint violation
INSERT INTO StockInventory
    (site_id, storage_id, record_date,
     volume_produced_kg, volume_stored_kg)
VALUES
    (1, 1, '2024-04-30', -5000.00, 4800.00);

-- Test 5: Quarter value outside allowed range
-- Expected error: CHECK constraint violation
INSERT INTO Financials
    (site_id, contract_id, fiscal_year, quarter,
     revenue_eur, production_cost_eur, logistics_cost_eur)
VALUES
    (1, 1, 2024, 5, 500000.00, 200000.00, 50000.00);
    

SELECT * FROM ProductionSites;

SELECT * FROM vw_offtaker_summary;

SELECT * FROM vw_shipment_performance;  

-- SECTION 8: QUERY PERFORMANCE OPTIMISATION
-- ============================================================

-- Original slow query:
-- No index on filtered columns, SELECT * retrieves all columns
-- Forces a full table scan on every execution
-- EXPLAIN this first to capture the baseline performance

EXPLAIN
SELECT *
FROM Shipments
WHERE status   = 'Delivered'
  AND offtaker_id = 3;

-- Improvement 1: Add composite index on the two filtered columns
-- status placed first — higher selectivity at any point in time
-- since only a subset of shipments are Delivered
CREATE INDEX idx_shipments_status_offtaker
    ON Shipments(status, offtaker_id);

-- Improvement 2: Replace SELECT * with explicit column list
-- Retrieves only the seven fields needed for this use case
SELECT
    shipment_id,
    vessel_name,
    departure_dt,
    actual_arrival_dt,
    volume_kg_loaded,
    volume_kg_delivered,
    status
FROM Shipments
WHERE status      = 'Delivered'
  AND offtaker_id = 3;

-- EXPLAIN after optimisation to compare rows examined
-- and execution plan against the baseline above
EXPLAIN
SELECT
    shipment_id,
    vessel_name,
    departure_dt,
    actual_arrival_dt,
    volume_kg_loaded,
    volume_kg_delivered,
    status
FROM Shipments
WHERE status      = 'Delivered'
  AND offtaker_id = 3;
  
EXPLAIN SELECT * FROM Shipments 
WHERE status = 'Delivered' AND 'Offtaker_id' = 3;


-- Result: MySQL now uses index range scan instead of full table scan.
-- Rows examined drops from total table size to matching records only.
-- Explicit column selection reduces I/O by avoiding retrieval of
-- unused fields on every execution.
-- Under concurrent multi-user load across logistics, commercial
-- and finance teams, this improvement compounds significantly.

-- Drop the index
DROP INDEX idx_shipments_status_offtaker ON Shipments;

EXPLAIN
SELECT *
FROM Shipments
WHERE status      = 'Delivered'
  AND offtaker_id = 3;


-- Recreate the index
CREATE INDEX idx_shipments_status_offtaker
    ON Shipments(status, offtaker_id);

-- Run EXPLAIN again 
EXPLAIN
SELECT *
FROM Shipments
WHERE status      = 'Delivered'
  AND offtaker_id = 3;

