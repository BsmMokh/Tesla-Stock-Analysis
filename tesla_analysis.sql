-- Tesla Stock Analysis SQL Project

-- Create database and table
CREATE DATABASE IF NOT EXISTS tesla_analysis;
USE tesla_analysis;

CREATE TABLE IF NOT EXISTS tesla_stock (
    date DATE,
    open DECIMAL(10,6),
    high DECIMAL(10,6),
    low DECIMAL(10,6),
    close DECIMAL(10,6),
    adj_close DECIMAL(10,6),
    volume BIGINT
);


-- 1. Basic Data Exploration
SELECT 
    MIN(date) as first_trading_day,
    MAX(date) as last_trading_day,
    COUNT(*) as total_trading_days,
    ROUND(AVG(volume), 2) as avg_daily_volume,
    ROUND(AVG(close), 2) as avg_closing_price
FROM tesla_stock;

-- 2. Monthly Performance Analysis
SELECT 
    YEAR(date) as year,
    MONTH(date) as month,
    ROUND(MIN(low), 2) as monthly_low,
    ROUND(MAX(high), 2) as monthly_high,
    ROUND(AVG(close), 2) as avg_closing_price,
    ROUND(SUM(volume), 2) as total_volume
FROM tesla_stock
GROUP BY YEAR(date), MONTH(date)
ORDER BY year, month;

-- 3. Volatility Analysis
SELECT 
    date,
    close,
    ROUND((high - low) / low * 100, 2) as daily_volatility_percentage,
    ROUND((close - LAG(close) OVER (ORDER BY date)) / LAG(close) OVER (ORDER BY date) * 100, 2) as daily_return_percentage
FROM tesla_stock
ORDER BY date;

-- 4. Moving Averages and Trends
SELECT 
    date,
    close,
    ROUND(AVG(close) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) as 30_day_moving_avg,
    ROUND(AVG(close) OVER (ORDER BY date ROWS BETWEEN 199 PRECEDING AND CURRENT ROW), 2) as 200_day_moving_avg
FROM tesla_stock
ORDER BY date;

-- 5. Volume Analysis
SELECT 
    date,
    volume,
    ROUND(AVG(volume) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) as 30_day_avg_volume,
    CASE 
        WHEN volume > AVG(volume) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) * 1.5 THEN 'High Volume'
        WHEN volume < AVG(volume) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) * 0.5 THEN 'Low Volume'
        ELSE 'Normal Volume'
    END as volume_classification
FROM tesla_stock
ORDER BY date;

-- 6. Year-over-Year Performance
SELECT 
    YEAR(date) as year,
    ROUND(MIN(close), 2) as yearly_low,
    ROUND(MAX(close), 2) as yearly_high,
    ROUND((MAX(close) - MIN(close)) / MIN(close) * 100, 2) as yearly_return_percentage,
    ROUND(AVG(volume), 2) as avg_volume
FROM tesla_stock
GROUP BY YEAR(date)
ORDER BY year;

-- 7. Price Range Analysis
SELECT 
    CASE 
        WHEN close < 50 THEN 'Under $50'
        WHEN close < 100 THEN '$50-$100'
        WHEN close < 200 THEN '$100-$200'
        WHEN close < 300 THEN '$200-$300'
        WHEN close < 400 THEN '$300-$400'
        ELSE 'Over $400'
    END as price_range,
    COUNT(*) as days_in_range,
    ROUND(AVG(volume), 2) as avg_volume,
    ROUND(AVG((high - low) / low * 100), 2) as avg_volatility_percentage
FROM tesla_stock
GROUP BY price_range
ORDER BY MIN(close);

-- 8. Correlation Analysis between Price and Volume
SELECT 
    ROUND(
        (COUNT(*) * SUM(close * volume) - SUM(close) * SUM(volume)) /
        SQRT((COUNT(*) * SUM(close * close) - SUM(close) * SUM(close)) * 
             (COUNT(*) * SUM(volume * volume) - SUM(volume) * SUM(volume))),
    4) as price_volume_correlation
FROM tesla_stock;

-- 9. Market Performance by Quarter
SELECT 
    YEAR(date) as year,
    QUARTER(date) as quarter,
    ROUND(MIN(close), 2) as quarter_low,
    ROUND(MAX(close), 2) as quarter_high,
    ROUND((MAX(close) - MIN(close)) / MIN(close) * 100, 2) as quarter_return_percentage,
    ROUND(AVG(volume), 2) as avg_volume
FROM tesla_stock
GROUP BY YEAR(date), QUARTER(date)
ORDER BY year, quarter;

-- 10. Advanced Analysis: Identifying Significant Price Movements
WITH price_changes AS (
    SELECT 
        date,
        close,
        LAG(close) OVER (ORDER BY date) as prev_close,
        (close - LAG(close) OVER (ORDER BY date)) / LAG(close) OVER (ORDER BY date) * 100 as daily_change_percentage
    FROM tesla_stock
)
SELECT 
    date,
    close,
    ROUND(daily_change_percentage, 2) as daily_change_percentage,
    CASE 
        WHEN daily_change_percentage > 5 THEN 'Significant Gain'
        WHEN daily_change_percentage < -5 THEN 'Significant Loss'
        ELSE 'Normal Movement'
    END as movement_type
FROM price_changes
WHERE ABS(daily_change_percentage) > 5
ORDER BY ABS(daily_change_percentage) DESC; 
