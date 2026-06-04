
-- ================================================
-- SaaS Product Analytics — Core SQL Queries
-- ================================================

-- 1. Monthly Active Users (MAU)
SELECT
    DATE_TRUNC('month', event_date) AS month,
    COUNT(DISTINCT user_id)         AS mau
FROM saas_events
GROUP BY 1
ORDER BY 1;

-- 2. Activation Rate (users who created a report within 7 days)
SELECT
    COUNT(DISTINCT CASE
        WHEN event_name = 'report_create'
         AND DATEDIFF(event_date, signup_date) <= 7
        THEN user_id END) * 100.0
    / COUNT(DISTINCT user_id) AS activation_rate_pct
FROM saas_events;

-- 3. Feature Adoption by Plan
SELECT
    plan,
    event_name,
    COUNT(DISTINCT user_id) AS unique_users
FROM saas_events
WHERE event_name NOT IN ('login', 'logout')
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- 4. User Retention — Active in Month 1 vs Month 0
WITH month0 AS (
    SELECT DISTINCT user_id,
           DATE_TRUNC('month', signup_date) AS cohort_month
    FROM saas_events
),
month1 AS (
    SELECT DISTINCT user_id,
           DATE_TRUNC('month', event_date)  AS activity_month
    FROM saas_events
)
SELECT
    m0.cohort_month,
    COUNT(DISTINCT m0.user_id)                        AS cohort_size,
    COUNT(DISTINCT m1.user_id)                        AS retained_month1,
    ROUND(COUNT(DISTINCT m1.user_id) * 100.0
          / COUNT(DISTINCT m0.user_id), 2)            AS retention_pct
FROM month0 m0
LEFT JOIN month1 m1
    ON m0.user_id = m1.user_id
   AND m1.activity_month = ADD_MONTHS(m0.cohort_month, 1)
GROUP BY 1
ORDER BY 1;

-- 5. Stickiness Ratio (DAU / MAU)
WITH dau AS (
    SELECT event_date,
           DATE_TRUNC('month', event_date) AS month,
           COUNT(DISTINCT user_id)          AS daily_users
    FROM saas_events
    GROUP BY 1, 2
),
mau AS (
    SELECT DATE_TRUNC('month', event_date) AS month,
           COUNT(DISTINCT user_id)          AS monthly_users
    FROM saas_events
    GROUP BY 1
)
SELECT
    mau.month,
    ROUND(AVG(dau.daily_users), 0)          AS avg_dau,
    mau.monthly_users                        AS mau,
    ROUND(AVG(dau.daily_users)
          / mau.monthly_users * 100, 2)      AS stickiness_pct
FROM dau
JOIN mau ON dau.month = mau.month
GROUP BY mau.month, mau.monthly_users
ORDER BY 1;