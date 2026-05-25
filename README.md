# Data Engineering & Analytics Portfolio
 
Data engineering exercises covering SQL analytics, Python web scraping, and system architecture design for a movie recommender platform.
 
---
 
## Sections
 
| # | Section | Topic | Location |
|---|---|---|---|
| 1 | SQL Analytics | NZ Enterprise Survey 2020 | [`section1-sql/`](./section1-sql/) |
| 2 | Python Web Scraper | Shopee Indonesia product crawler | [ecommerce-product-scraper](https://github.com/richardy-lobo-sapan/ecommerce-product-scraper) |
| 3 | Architecture Design | MovFlix movie recommender system on GCP | [`section3-architecture/`](./section3-architecture/) |
 
---
 
## Section 1 — SQL Analytics
 
Exploratory SQL analysis on New Zealand's Annual Enterprise Survey (2020), practicing aggregations, window functions, and pivot/transpose patterns.
 
**Dataset:** `annual-enterprise-survey-2020-financial-year-provisional.csv`
- 37,080 rows × 10 columns
- Years: 2013–2020
- Industries: 111 unique industry names across 3 aggregation levels
**Problems solved:**
1. Filter total equity and liabilities for specific industries
2. Total value per variable name grouped by industry aggregation level
3. Total value per individual industry, level, and unit
4. Yearly total summary per industry
5. Top 3 and bottom 3 variable names in transposed/pivot format per year
**Key decisions:**
- Target DB: PostgreSQL
- `DENSE_RANK()` used for Problem 5 — preserves consecutive rank positions unlike `RANK()`, and is deterministic unlike `ROW_NUMBER()`
- `Value` column stored as VARCHAR with comma-formatting — all aggregations use `CAST(REPLACE(Value, ',', '') AS NUMERIC)`
📁 [`section1-sql/section1_SQL.sql`](./section1-sql/section1_SQL.sql)
 
---
 
## Section 2 — Python Web Scraper
 
A Python scraper that collects product listings from [Shopee Indonesia](https://shopee.co.id) and exports to CSV and JSON.
 
**How it works:** Shopee is a Single Page Application that loads product data from an internal JSON search API. The scraper calls that endpoint directly — no Selenium, no HTML parsing, clean structured JSON responses.
 
**Mandatory fields collected:** Product Name, Category ID, Price (IDR)
 
**Extra fields (with business justification):**
 
| Field | Business Value |
|---|---|
| `rating` | Demand signal; input to price elasticity models |
| `review_count` | Weights rating reliability |
| `units_sold` | Sales velocity; GMV and inventory forecasting |
| `stock` | Live inventory intelligence |
| `seller_location` | Geographic supply mapping for logistics |
| `discount_pct` | Promotional strategy; markdown optimisation input |
| `product_url` | Full traceability; enables price monitoring across runs |
 
**Stack:** Python 3.9+ · `curl_cffi` (TLS fingerprint impersonation — required because Shopee detects standard `requests` at the SSL handshake level)
 
🔗 **[ecommerce-product-scraper](https://github.com/richardy-lobo-sapan/ecommerce-product-scraper)** — full source, results, and run instructions
 
---
 
## Section 3 — Architecture Design
 
End-to-end GCP-based movie recommender system design for MovFlix, a fictional streaming platform, using the MovieLens ml-latest-small dataset (100,836 ratings · 9,742 movies · 610 users).
 
**Architecture layers:**
 
```
Sources       →  MovieLens data · Live user rating events · TMDB/IMDB API
Ingestion     →  Cloud Storage (GCS) · Cloud Pub/Sub
Processing    →  Cloud Dataflow (batch + stream ETL) · Cloud Composer (Airflow orchestration)
Storage       →  BigQuery (data warehouse) · Vertex AI Feature Store
ML            →  Vertex AI Training — ALS collaborative filtering + content-based hybrid
Serving       →  Memorystore (Redis) · Cloud Run API · MovFlix dashboard
```
 
**Recommendation algorithm:**
- Primary: ALS (Alternating Least Squares) — chosen because the ratings matrix is 98.3% sparse
- Secondary: Content-based filtering on genres + TF-IDF tags — handles cold start for new users and new movies
- Hybrid scoring: `final_score = α × ALS_score + (1 − α) × content_score` where α scales with user rating history depth
📁 [`section3-architecture/`](./section3-architecture/) — full architecture document (PDF)
 
---
 
## Stack Summary
 
| Section | Language / Tool |
|---|---|
| SQL | PostgreSQL |
| Scraper | Python 3.9+, curl_cffi |
| Architecture | GCP — GCS, Pub/Sub, Dataflow, Composer, BigQuery, Vertex AI Feature Store, Vertex AI Training, Memorystore (Redis), Cloud Run |
| ML Algorithm | ALS Collaborative Filtering + Content-Based Hybrid |
| Dataset (SQL) | NZ Annual Enterprise Survey 2020 (Stats NZ) |
| Dataset (Architecture) | MovieLens ml-latest-small (GroupLens, University of Minnesota) |
 
---
 
## Repository Structure
 
```
de-analytics-project/
├── README.md
├── section1-sql/
│   └── section1_SQL.sql
└── section3-architecture/
    └── Architecture MovFlix - Movie Recommender System.pdf
 
Section 2 lives in a separate repo:
→ https://github.com/richardy-lobo-sapan/ecommerce-product-scraper
```
 
---
 
## Citation
 
MovieLens dataset: F. Maxwell Harper and Joseph A. Konstan. 2015. The MovieLens Datasets: History and Context. ACM Transactions on Interactive Intelligent Systems (TiiS) 5, 4: 19:1–19:19. https://doi.org/10.1145/2827872
