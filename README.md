# Sales-Performance-Dashboard-PostgreSQL-Power-BI-
This project showcases an end-to-end Business Intelligence (BI) workflow — from database design in PostgreSQL to interactive dashboard creation in Power BI. It analyzes sales performance across products, regions, time periods, and customer segments.

# Project Overview

The goal of this project was to build a complete analytics solution with:

A Star Schema Data Model

SQL-based data preparation

DAX-powered calculations

Power BI dashboard with rich interactivity

The dashboard helps business users understand trends in sales, product performance, customer behavior, and regional contribution.

# 🗂️ Data Model (Star Schema)

The database contains one fact table and four dimension tables:

# Fact Table

fact_sales
Contains transactional sales data—order quantity, sales amount, date, product, store & customer links.

# Dimension Tables

dim_date

dim_product

dim_customer

dim_store

All tables are connected using surrogate keys to build an optimized star schema suitable for analytics.

# 🧠 Key Metrics (DAX Measures)

Total Sales

Total Orders

Total Quantity

Average Order Value (AOV)

Sales LY (Last Year)

YoY % Growth

Rolling 12-Month Sales

Customer Count

Avg Order Value

These measures help uncover deep insights and support business decisions.

# 📉 Dashboard Features
# 1. KPI Cards

Total Sales

Total Orders

Total Quantity

Average Order Value

# 2. Trend Analysis

Monthly Sales Trend (Line Chart)

YoY Comparison (via DAX)

# 3. Regional Insights

Sales by Region (Bar Chart)

# 4. Product Insights

Sales by Product Name

Custom Product Short IDs (P1, P2…) created using DAX

# 5. Interactive Slicers

Year

Month

Region

Category

These filters allow users to analyze sales dynamically with a single click.

# 📌 Insights & Outcomes

Top-performing regions identified using aggregated regional sales

Product ranking revealed most profitable products

Monthly trend showed seasonal rise and fall in sales

YoY performance highlighted business growth patterns

<img width="764" height="433" alt="pic1" src="https://github.com/user-attachments/assets/d15bee90-8e06-406a-8039-4f0628abc124" />
<img width="329" height="557" alt="pic4" src="https://github.com/user-attachments/assets/4f012bd3-d713-4fed-a353-e7584a4e984e" />
<img width="721" height="485" alt="pic5" src="https://github.com/user-attachments/assets/17c6a715-d9e1-453b-88bc-001ae9bd5328" />



