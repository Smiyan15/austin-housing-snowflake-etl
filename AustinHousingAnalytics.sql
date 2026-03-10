-----Creating DB for Austin Housing Project-------------
CREATE OR REPLACE DATABASE AUSTIN_RE;

--------Schema for Austin Housing Project---------------
CREATE OR REPLACE SCHEMA ANALYSIS;

-------------Creating Table for raw data----------------
CREATE OR REPLACE TABLE RAW_AUSTIN_HOUSING (
    zpid INT,
    city STRING,
    streetAddress STRING,
    zipcode INT,
    description STRING,
    latestPrice FLOAT,
    livingAreaSqFt FLOAT,
    yearBuilt INT,
    numOfBathrooms FLOAT,
    numOfBedrooms INT,
    latest_saledate DATE
);

---File Format----------------
CREATE OR REPLACE FILE FORMAT austin_housing_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE;

-- Creating the internal stage
CREATE OR REPLACE STAGE austin_housing_stage
  FILE_FORMAT = austin_housing_format;

---- query to identify duplicates by 'zpid' and keep only the most recent/expensive one
CREATE OR REPLACE TABLE AUSTIN_HOUSING_CLEAN AS
WITH DeDuped AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY zpid 
            ORDER BY latestPrice DESC
        ) as occurrence_rank
    FROM RAW_AUSTIN_HOUSING 
)
SELECT * EXCLUDE occurrence_rank 
FROM DeDuped 
WHERE occurrence_rank = 1;

-----Checking for duplicates--------------------
SELECT COUNT(*) FROM RAW_AUSTIN_HOUSING;
SELECT COUNT(*) FROM AUSTIN_HOUSING_CLEAN;

------To check if there are no duplicates(Double check)---------
SELECT zpid, COUNT(*)
FROM RAW_AUSTIN_HOUSING
GROUP BY zpid
HAVING COUNT(*) > 1;

-------Creating a view to check price per sqft and marking the houses according to year built-----
CREATE OR REPLACE VIEW V_AUSTIN_MARKET_INSIGHTS AS
SELECT 
    *,
    latestPrice / NULLIF(livingAreaSqFt, 0) as price_per_sqft,
    CASE 
        WHEN yearBuilt < 1980 THEN 'Pre-1980 (Vintage)'
        WHEN yearBuilt BETWEEN 1980 AND 2000 THEN '1980-2000 (Classic)'
        WHEN yearBuilt BETWEEN 2001 AND 2015 THEN '2001-2015 (Modern)'
        ELSE '2016-Present (New Construction)'
    END as construction_era
FROM AUSTIN_HOUSING_CLEAN;

---To check the view created-------------------
SELECT * FROM V_AUSTIN_MARKET_INSIGHTS;