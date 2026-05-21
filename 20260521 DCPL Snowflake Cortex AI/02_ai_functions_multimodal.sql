-- ============================================================
-- DEMO 2: Cortex AI Functions - multimodal 
-- ============================================================

USE DATABASE DCPL_DB;
USE SCHEMA DATA;

-- Documents - parsing (with layout)
SELECT AI_PARSE_DOCUMENT(
    TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/DOCUMENTS', 'Custom_Invoice_2010.pdf'),
    {'mode': 'LAYOUT' , 'page_split': true}
) AS RESULT;

-- Documents - data extraction
SELECT AI_EXTRACT(
    FILE => TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/DOCUMENTS', 'Custom_Invoice_2010.pdf'),
    RESPONSEFORMAT => {
        'invoice_no': 'Invoice number',
        'invoice_date': 'Invoice date',
        'invoice_amount': 'Invoice total gross amount'
    }
) AS RESULT;

-- Images - finding specific images in the folder
CREATE OR REPLACE TABLE IMAGE_FILES AS
SELECT
    RELATIVE_PATH AS FILE_NAME,
    TO_FILE(FILE_URL) AS IMG
FROM DIRECTORY('@DCPL_DB.DATA.RAW_DATA_STAGE')
WHERE RELATIVE_PATH LIKE 'IMAGES/%';

SELECT * FROM IMAGE_FILES;

SELECT FILE_NAME,
    AI_FILTER('This is a commercial advertisement', IMG) AS IS_AD
FROM IMAGE_FILES;

-- Images - image analysis
SELECT AI_COMPLETE(
    MODEL => 'claude-sonnet-4-6',
    PROMPT => PROMPT(
        'From the image {0} - when there was a peak in cost and how high it was?',
        TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/IMAGES', 'cost_history.png')
    )
) AS RESULT;

-- Images - comparison
SELECT AI_COMPLETE('claude-sonnet-4-6',
    PROMPT(
        'Compare this image {0} to this image {1} and describe the ideal audience for each in two concise bullets no longer than 10 words',
        TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/IMAGES', 'car_ad_1.PNG'),
        TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/IMAGES', 'car_ad_2.PNG')
    )
) AS RESULT;

-- Audio - transcript of the call center call
SELECT 
    AI_TRANSCRIBE(
        TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/AUDIO', 'consultation.wav'),
        {'timestamp_granularity': 'speaker'}
    ) AS RESULT;

-- Video - brand and product analysis
SELECT AI_COMPLETE(
    MODEL => 'gemini-3.1-pro',
    PROMPT => PROMPT(
        'Give me a super short summary of the attached video: {0}. List all brands and products.',
        TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/VIDEO', 'Infinite Services - Snowflake Intelligence.mp4')
    )
) AS RESULT;

SELECT AI_COMPLETE(
    model => 'gemini-2.5-flash',
    prompt => PROMPT(
        'Based on this video {0}, write 2 social media posts:
         1. A professional LinkedIn post (150 words)
         2. A Twitter/X post (280 chars max)',
        TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/VIDEO', 'Infinite Services - Snowflake Intelligence.mp4')
    )
) AS RESULT;

-- Excel - analyze data in tables
SELECT AI_COMPLETE(
  MODEL => 'claude-4-sonnet',
  PROMPT => PROMPT(
    'What is sales for Tables sub-category and what percentage of sales for its category it makes based on Sales worksheet of {0}?', 
    TO_FILE('@DCPL_DB.DATA.RAW_DATA_STAGE/EXCEL', 'superstore.xlsx')
  )
) AS RESULT;

-- ============================================================

-- Usage and cost tracking
SELECT F.QUERY_ID, F.START_TIME, F.FUNCTION_NAME, F.MODEL_NAME, H.USER_NAME, H.QUERY_TEXT, F.CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY AS F
INNER JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY AS H 
ON F.QUERY_ID = H.QUERY_ID
ORDER BY F.END_TIME DESC
LIMIT 10;

-- Security: 
SELECT 'https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql#cortex-llm-privileges' AS DOCS;