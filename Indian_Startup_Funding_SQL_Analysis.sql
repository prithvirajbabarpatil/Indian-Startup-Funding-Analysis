SELECT * FROM indian_startup_funding.indian_startup_funding_cleaned;

-- PART 1 - Data Validation
-- Total records
SELECT COUNT(*) AS total_records
FROM indian_startup_funding_cleaned;

-- Check missing values
SELECT
    COUNT(*) AS total_records,
    SUM(company_name IS NULL) AS missing_company,
    SUM(city IS NULL) AS missing_city,
    SUM(sector IS NULL) AS missing_sector,
    SUM(stage IS NULL) AS missing_stage,
    SUM(amount_usd IS NULL) AS missing_amount,
    SUM(lead_investor IS NULL) AS missing_investor
FROM indian_startup_funding_cleaned;

-- Check distinct sectors,cities and stages
SELECT
    COUNT(DISTINCT sector) AS total_sectors,
    COUNT(DISTINCT city) AS total_cities,
    COUNT(DISTINCT stage) AS total_funding_stages
FROM indian_startup_funding_cleaned;

-- PART 2 - BASIC SQL EXPLORATION
-- Display all records
SELECT *
FROM indian_startup_funding_cleaned
LIMIT 20;

-- find startups with disclosed funding above $10 million
SELECT company_name, sector, city, amount_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd > 10000000
ORDER BY amount_usd DESC;

-- find startups founded after 2020
SELECT company_name, founded_year, sector
FROM indian_startup_funding_cleaned
WHERE founded_year > 2020
ORDER BY founded_year DESC;

-- find records by funding stage
SELECT *
FROM indian_startup_funding_cleaned
WHERE stage = 'Series A';

-- PART 3 - AGGREGATE FUNCTIONS
-- Total disclosed funding
SELECT
    SUM(amount_usd) AS total_funding_usd
FROM indian_startup_funding_cleaned;

-- Average,maximum and minimum funding
SELECT
    ROUND(AVG(amount_usd), 2) AS average_funding,
    MAX(amount_usd) AS highest_funding,
    MIN(amount_usd) AS lowest_funding
FROM indian_startup_funding_cleaned;

-- Number of funding rounds by sector
SELECT
    sector,
    COUNT(*) AS funding_rounds
FROM indian_startup_funding_cleaned
GROUP BY sector
ORDER BY funding_rounds DESC;

-- Total funding by sector
SELECT
    sector,
    COUNT(*) AS funding_rounds,
    ROUND(SUM(amount_usd), 2) AS total_funding
FROM indian_startup_funding_cleaned
GROUP BY sector
ORDER BY total_funding DESC;

-- funding by city
SELECT
    city,
    COUNT(*) AS total_rounds,
    ROUND(SUM(amount_usd), 2) AS total_funding
FROM indian_startup_funding_cleaned
GROUP BY city
ORDER BY total_funding DESC;

-- funding by investment stage
SELECT
    stage,
    COUNT(*) AS total_rounds,
    ROUND(AVG(amount_usd), 2) AS average_funding,
    ROUND(SUM(amount_usd), 2) AS total_funding
FROM indian_startup_funding_cleaned
GROUP BY stage
ORDER BY total_funding DESC;

-- PART 4 - BUSINESS ANALYSIS
-- Top 10 startups by funding
SELECT
    company_name,
    sector,
    city,
    stage,
    amount_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
ORDER BY amount_usd DESC
LIMIT 10;

-- Top 10 lead investors by numbers of rounds
SELECT
    lead_investor,
    COUNT(*) AS total_investments
FROM indian_startup_funding_cleaned
WHERE lead_investor IS NOT NULL
GROUP BY lead_investor
ORDER BY total_investments DESC
LIMIT 10;

-- Annual funding trends
SELECT
    year,
    COUNT(*) AS total_rounds,
    ROUND(SUM(amount_usd), 2) AS total_funding
FROM indian_startup_funding_cleaned
GROUP BY year
ORDER BY year;

-- Funding distribution by country
SELECT
    country,
    COUNT(*) AS total_rounds,
    ROUND(SUM(amount_usd), 2) AS total_funding
FROM indian_startup_funding_cleaned
GROUP BY country
ORDER BY total_funding DESC;

-- Disclosed versus undisclosed funding
SELECT
    amount_status,
    COUNT(*) AS total_rounds,
    ROUND(SUM(amount_usd), 2) AS total_funding
FROM indian_startup_funding_cleaned
GROUP BY amount_status;

-- Average number of investors by funding stage
SELECT
    stage,
    ROUND(AVG(investor_count), 2) AS avg_investors,
    COUNT(*) AS total_rounds
FROM indian_startup_funding_cleaned
GROUP BY stage
ORDER BY avg_investors DESC;

-- sectors with more than 100 funding rounds
SELECT
    sector,
    COUNT(*) AS total_rounds
FROM indian_startup_funding_cleaned
GROUP BY sector
HAVING COUNT(*) > 100
ORDER BY total_rounds DESC;

-- startups with the most news mentions
SELECT
    company_name,
    sector,
    news_mentions
FROM indian_startup_funding_cleaned
ORDER BY news_mentions DESC
LIMIT 10;

-- PART 5 - INTERMEDIATE SQL
-- Case when - categorize funding amounts
SELECT
    company_name,
    amount_usd,
    CASE
        WHEN amount_usd >= 100000000 THEN 'Mega Funding'
        WHEN amount_usd >= 10000000 THEN 'High Funding'
        WHEN amount_usd >= 1000000 THEN 'Medium Funding'
        WHEN amount_usd > 0 THEN 'Low Funding'
        ELSE 'Undisclosed'
    END AS funding_category
FROM indian_startup_funding_cleaned;

-- subquery - startups receiving above - average funding
SELECT
    company_name,
    sector,
    amount_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd > (
    SELECT AVG(amount_usd)
    FROM indian_startup_funding_cleaned
)
ORDER BY amount_usd DESC;

-- CTE - Top funded sector
WITH sector_funding AS (
    SELECT
        sector,
        SUM(amount_usd) AS total_funding
    FROM indian_startup_funding_cleaned
    GROUP BY sector
)
SELECT
    sector,
    ROUND(total_funding, 2) AS total_funding
FROM sector_funding
ORDER BY total_funding DESC
LIMIT 5;

-- Compare funding by year
SELECT
    year,
    ROUND(SUM(amount_usd), 2) AS current_funding,
    ROUND(
        LAG(SUM(amount_usd)) OVER (ORDER BY year), 2
    ) AS previous_year_funding
FROM indian_startup_funding_cleaned
GROUP BY year
ORDER BY year;

-- PART 6 - ADVANCED SQL
-- Rank sectors by total funding
SELECT
    sector,
    ROUND(SUM(amount_usd), 2) AS total_funding,
    RANK() OVER (
        ORDER BY SUM(amount_usd) DESC
    ) AS sector_rank
FROM indian_startup_funding_cleaned
GROUP BY sector;

-- Rank startups within each sector
SELECT *
FROM (
    SELECT
        company_name,
        sector,
        amount_usd,
        DENSE_RANK() OVER (
            PARTITION BY sector
            ORDER BY amount_usd DESC
        ) AS funding_rank
    FROM indian_startup_funding_cleaned
    WHERE amount_usd IS NOT NULL
) ranked_startups
WHERE funding_rank <= 3;

-- Calculate each sectors percentage contribution to funding
SELECT
    sector,
    ROUND(SUM(amount_usd), 2) AS total_funding,
    ROUND(
        SUM(amount_usd) * 100.0 /
        SUM(SUM(amount_usd)) OVER (), 2
    ) AS funding_percentage
FROM indian_startup_funding_cleaned
GROUP BY sector
ORDER BY funding_percentage DESC;

-- Top 5 cities by ffunding within each sector
WITH city_funding AS (
    SELECT
        sector,
        city,
        SUM(amount_usd) AS total_funding
    FROM indian_startup_funding_cleaned
    GROUP BY sector, city
),
ranked_cities AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY sector
            ORDER BY total_funding DESC
        ) AS city_rank
    FROM city_funding
)
SELECT *
FROM ranked_cities
WHERE city_rank <= 5
ORDER BY sector, city_rank;

-- PART 7 - Final business analysis
-- which sectorsattract the highest total funding ?
SELECT
    sector,
    COUNT(*) AS total_rounds,
    SUM(amount_usd) AS total_funding_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
GROUP BY sector
ORDER BY total_funding_usd DESC
LIMIT 10;

-- Which cities receive the highest startups funding ?
SELECT
    city,
    COUNT(*) AS total_rounds,
    SUM(amount_usd) AS total_funding_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
  AND city IS NOT NULL
GROUP BY city
ORDER BY total_funding_usd DESC
LIMIT 10;

-- How has startups funding changed year by year ?
SELECT
    year,
    COUNT(*) AS total_rounds,
    SUM(amount_usd) AS total_funding_usd,
    ROUND(AVG(amount_usd), 2) AS average_funding_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
GROUP BY year
ORDER BY year;

-- Which funding stages receive the most investment?
SELECT
    stage,
    COUNT(*) AS total_rounds,
    SUM(amount_usd) AS total_funding_usd,
    ROUND(AVG(amount_usd), 2) AS average_funding_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
GROUP BY stage
ORDER BY total_funding_usd DESC;

-- Which startups received the highest funding?
SELECT
    company_name,
    sector,
    city,
    stage,
    SUM(amount_usd) AS total_funding_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
GROUP BY company_name, sector, city, stage
ORDER BY total_funding_usd DESC
LIMIT 10;

-- Which investors participate in the highest numbers of funding rounds ?
SELECT
    lead_investor,
    COUNT(*) AS total_rounds,
    SUM(amount_usd) AS total_funding_usd
FROM indian_startup_funding_cleaned
WHERE lead_investor IS NOT NULL
GROUP BY lead_investor
ORDER BY total_rounds DESC
LIMIT 10;

-- What percentage of total disclosed funding does each sector contribute ?
SELECT
    sector,
    SUM(amount_usd) AS sector_funding,
    ROUND(
        SUM(amount_usd) * 100.0 /
        (SELECT SUM(amount_usd)
         FROM indian_startup_funding_cleaned),
        2
    ) AS funding_percentage
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
GROUP BY sector
ORDER BY sector_funding DESC;

-- How much funding is disclosed versus undisclosed?
SELECT
    amount_status,
    COUNT(*) AS total_records,
    SUM(amount_usd) AS disclosed_funding_usd
FROM indian_startup_funding_cleaned
GROUP BY amount_status
ORDER BY total_records DESC;

-- Which sectors have the highest number of funding rounds ?
SELECT
    sector,
    COUNT(*) AS total_rounds,
    SUM(amount_usd) AS total_funding_usd,
    ROUND(AVG(amount_usd), 2) AS average_funding_usd
FROM indian_startup_funding_cleaned
GROUP BY sector
ORDER BY total_rounds DESC
LIMIT 10;

-- What are the major funding patterns across cities and sectors?
SELECT
    sector,
    city,
    COUNT(*) AS total_rounds,
    SUM(amount_usd) AS total_funding_usd
FROM indian_startup_funding_cleaned
WHERE amount_usd IS NOT NULL
  AND sector IS NOT NULL
  AND city IS NOT NULL
GROUP BY sector, city
ORDER BY total_funding_usd DESC
LIMIT 20;
