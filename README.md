# Cohort Retention Basics

Veda Technology internship - Data Analytics track.
Build a cohort retention table by signup month (first purchase month), with a heatmap and insights.

- **Dataset:** Online Retail II (UCI), 541,910 rows, Dec 2010 - Dec 2011
- **Tools:** Python (pandas, matplotlib, seaborn) + SQL (PostgreSQL)

## Files
| File | Description |
|---|---|
| `cohort_retention.py` | Python: clean data, build cohort table, retention %, heatmap |
| `cohort_retention.sql` | PostgreSQL: table, views, cohort table, retention %, insight query |
| `cohort_counts.csv` | Cohort table (active customers) |
| `cohort_retention_pct.csv` | Cohort retention table (%) |
| `cohort_heatmap.png` | Retention heatmap |
| `Cohort_Retention_Report.pdf` | Project report |

## Method
1. Remove rows with missing Customer ID, cancelled invoices (Invoice starts with `C`), Quantity <= 0, Price <= 0.
2. Exclude Dec 2011 (data ends 9 Dec, incomplete month).
3. Cohort = month of a customer's first purchase. Cohort index = months since that month.
4. Retention % = unique active customers in month N / cohort size x 100.

## Result
4,297 customers in 12 cohorts. About 24% of a cohort buys again in month 1 (size-weighted).
The Dec-2010 cohort is the strongest (32-40% retention in most months). Python and SQL results match.

## Run
```
pip install pandas matplotlib seaborn
python cohort_retention.py        # needs online_retail_II.csv in the same folder
```
SQL: open `cohort_retention.sql` in pgAdmin Query Tool and run step by step.

## SQL Outputs
Screenshots of the pgAdmin query outputs (STEP 8 cohort table, STEP 9 average retention) are in the `screenshots/` folder.

## Dataset
Not included because of file size. Download Online Retail II from UCI / Kaggle and place `online_retail_II.csv` in the project folder.
