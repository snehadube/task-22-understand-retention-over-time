"""
Task: Cohort Retention Basics  (Veda Technology - Data Analytics track)
Dataset: Online Retail II (UCI)  |  Tools: Python (pandas, matplotlib, seaborn) + SQL
Goal: Build a cohort retention table by signup (first purchase) month.
"""
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

CSV = "online_retail_II.csv"

# 1. LOAD  (file is latin-1 encoded, dates look like 12/1/10 8:26 = M/D/YY H:MM)
df = pd.read_csv(CSV, encoding="latin1")
df.columns = ["invoice", "stockcode", "description", "quantity",
              "invoicedate", "price", "customer_id", "country"]
df["invoicedate"] = pd.to_datetime(df["invoicedate"], format="%m/%d/%y %H:%M")
raw_rows = len(df)

# 2. CLEAN
no_id = df["customer_id"].isna().sum()
df = df.dropna(subset=["customer_id"])                       # cannot track anonymous buyers
cancelled = df["invoice"].astype(str).str.startswith("C").sum()
df = df[~df["invoice"].astype(str).str.startswith("C")]      # cancellations
df = df[(df["quantity"] > 0) & (df["price"] > 0)]            # bad rows
df["customer_id"] = df["customer_id"].astype(int)
# Dataset ends 9-Dec-2011 -> December 2011 is an incomplete month, so exclude it
partial = (df["invoicedate"] >= "2011-12-01").sum()
df = df[df["invoicedate"] < "2011-12-01"]
clean_rows = len(df)

# 3. DEFINE COHORT = month of a customer's FIRST purchase
df["order_month"] = df["invoicedate"].dt.to_period("M")
df["cohort_month"] = df.groupby("customer_id")["order_month"].transform("min")

# 4. COHORT INDEX = months since first purchase (0 = signup month)
df["cohort_index"] = ((df["order_month"].dt.year - df["cohort_month"].dt.year) * 12
                      + (df["order_month"].dt.month - df["cohort_month"].dt.month))

# 5. COHORT TABLE  (unique active customers)
cohort_counts = (df.groupby(["cohort_month", "cohort_index"])["customer_id"]
                   .nunique().unstack(fill_value=0))
cohort_counts.index = cohort_counts.index.astype(str)

# 6. RETENTION % = active customers in month N / cohort size (month 0)
cohort_size = cohort_counts[0]
retention = cohort_counts.div(cohort_size, axis=0).round(4) * 100
# months that haven't happened yet -> blank instead of fake 0%
last = df["order_month"].max()
for c in retention.index:
    max_idx = (last.year - pd.Period(c).year) * 12 + (last.month - pd.Period(c).month)
    retention.loc[c, retention.columns > max_idx] = np.nan

cohort_counts.to_csv("cohort_counts.csv")
retention.round(1).to_csv("cohort_retention_pct.csv")

# 7. HEATMAP
plt.figure(figsize=(13, 7))
sns.heatmap(retention, annot=True, fmt=".0f", cmap="YlGnBu", vmin=0, vmax=50,
            cbar_kws={"label": "Retention %"}, linewidths=.4, linecolor="white")
plt.title("Monthly Cohort Retention (%)  -  Online Retail II", fontsize=14, pad=12)
plt.xlabel("Months since first purchase")
plt.ylabel("Cohort (first purchase month)")
plt.tight_layout()
plt.savefig("cohort_heatmap.png", dpi=170)
plt.close()

# 8. INSIGHTS
avg_ret = retention.drop(columns=0).mean()      # average per month index
m1 = avg_ret[1]; m3 = avg_ret[3]; m6 = avg_ret[6]; m11 = avg_ret.get(11, np.nan)
best_m1 = retention[1].dropna().idxmax(); worst_m1 = retention[1].dropna().idxmin()
print(f"raw rows {raw_rows:,} | no customer id {no_id:,} | cancelled {cancelled:,} | clean {clean_rows:,}")
print("customers", df.customer_id.nunique(), "| cohorts", len(cohort_counts))
print(cohort_size.to_string())
print("avg retention by month:\n", avg_ret.round(1).to_string())
print("best M1:", best_m1, retention.loc[best_m1, 1], "| worst M1:", worst_m1, retention.loc[worst_m1, 1])
print("Dec-2010 cohort:\n", retention.loc["2010-12"].round(1).to_string())
