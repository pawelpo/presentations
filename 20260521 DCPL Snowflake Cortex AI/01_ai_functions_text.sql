-- ============================================================
-- DEMO 1: Cortex AI Functions - unstructured text
-- ============================================================

USE DATABASE DCPL_DB;
USE SCHEMA DATA;

-- Sample data
SELECT * FROM HOTEL_REVIEWS LIMIT 10;

-- Step 1: Detect sentiment
CREATE OR REPLACE DYNAMIC TABLE HOTEL_REVIEWS_SENTIMENT
    TARGET_LAG = DOWNSTREAM
    WAREHOUSE = COMPUTE_WH
AS
SELECT
    REVIEW_ID,
    CITY,
    NAME,
    REVIEWS_RATING,
    REVIEWS_TEXT,
    AI_SENTIMENT(REVIEWS_TEXT):categories[0]:sentiment::string AS SENTIMENT
FROM HOTEL_REVIEWS;

-- Step 2: Enrich data for reviews with negative feedback
CREATE OR REPLACE DYNAMIC TABLE HOTEL_REVIEWS_NEGATIVE
    TARGET_LAG = '1 MINUTE'
    WAREHOUSE = COMPUTE_WH
AS
SELECT
    REVIEW_ID,
    CITY,
    NAME,
    REVIEWS_RATING,
    REVIEWS_TEXT,
    SENTIMENT,
    AI_TRANSLATE(REVIEWS_TEXT, '', 'de') AS REVIEW_GERMAN,
    AI_CLASSIFY(REVIEWS_TEXT, ['service', 'dirt', 'food', 'air conditioning', 'other']):labels[0]::string AS ISSUE_CATEGORY
FROM HOTEL_REVIEWS_SENTIMENT
WHERE SENTIMENT = 'negative';

-- Verify enriched data
SELECT
    REVIEW_ID,
    NAME AS HOTEL,
    CITY,
    REVIEWS_TEXT,
    REVIEW_GERMAN,
    ISSUE_CATEGORY,
    SENTIMENT
FROM HOTEL_REVIEWS_NEGATIVE
LIMIT 5;

-- DELETE FROM HOTEL_REVIEWS WHERE CITY = 'Warsaw';
-- DELETE FROM HOTEL_REVIEWS_OPERATOR;

-- Step 3: Add new bad review
INSERT INTO HOTEL_REVIEWS (REVIEW_ID, CITY, NAME, REVIEWS_RATING, REVIEWS_TEXT)
VALUES (
    201,
    'Warsaw',
    'Demo Hotel Warsaw',
    1.0,
    'Terrible experience. The air conditioning was broken and the room was extremely hot. Staff did not care at all when I complained. Would never come back.'
);

-- Verify enriched new entry
SELECT * 
FROM HOTEL_REVIEWS_NEGATIVE WHERE 
CITY = 'Warsaw';

-- Step 4: Generate responses
SELECT 
    REVIEWS_TEXT,
    AI_COMPLETE(
        'mistral-large',
        PROMPT('Generate hotel''s manager response to the review: {0}', REVIEWS_TEXT)
    ) 
FROM HOTEL_REVIEWS_NEGATIVE
LIMIT 1;

-- Step 5: Search for specific feedback
SELECT *
FROM HOTEL_REVIEWS_NEGATIVE
WHERE AI_FILTER(PROMPT('Customer mentioned bad smell: {0}', REVIEWS_TEXT));