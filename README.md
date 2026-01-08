# Courcework_NVBD_Variant10_Riznyk_Maria

Coursework: Very Large Databases (NVBD)
Variant 10 – Cable Television
Student: Riznyk Maria

Project Overview

This project implements a full-cycle data warehouse and analytics solution for a Cable Television domain using Microsoft SQL Server technologies.
The system covers data generation, ETL processes, OLAP cube design, and analytical reporting.

The solution is developed according to the coursework requirements and includes SSIS, SSAS, and SSRS components.

Business Domain

Main entities:
Subscribers
TV Channels
Channel Groups
Movies
Orders
Bills
Payments

Key Constraints
≥ 100,000 subscribers
≥ 1,000,000 movie orders
5 years of historical data

Repository Structure
├── DataGeneration/        # Scripts for large-scale data generation
├── Database/              # Database schema and SQL scripts
├── Documentation/         # Coursework report (PDF)
├── Riznyk_Maria_SSIS/     # ETL packages (SSIS)
├── Riznyk_Maria_SSAS/     # OLAP cube and dimensions (SSAS)
├── Riznyk_Maria_SSRS/     # Analytical reports (SSRS)
└── README.md

ETL (SSIS)
Incremental and full data loading
Data cleansing, type conversion, lookups, derived columns
Loading into a Data Warehouse (Star Schema)

OLAP Cube (SSAS)
Measures: revenue, orders count, payments, subscriptions
Dimensions: Time, Subscriber, Movie, Channel, Channel Group
Supports time-based and analytical queries

Reports (SSRS)
Implemented mandatory reports:
Movie popularity ranking
Subscriber consumption behavior
Monthly financial report
Channel subscription analysis
Subscriber base dynamics
Reports include tables, charts, matrices, dashboards, and parameters.

Technologies Used
Microsoft SQL Server
SQL Server Integration Services (SSIS)
SQL Server Analysis Services (SSAS)
SQL Server Reporting Services (SSRS)
SQL Server Data Tools (SSDT)

How to Run
1. Restore or create the database using scripts in Database/
2. Generate and load data via SSIS packages
3. Deploy and process the SSAS cube
4. Open and view reports in SSRS
