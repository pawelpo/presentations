SELECT jsonContent
FROM
        OPENROWSET(
            BULK 'https://synapsedemopp1adls.dfs.core.windows.net/datalake/google_analytics/ga_sessions_sample.json',
            FORMAT = 'CSV',
            FIELDQUOTE = '0x0b',
            FIELDTERMINATOR ='0x0b'
        )
        WITH (
            jsonContent varchar(max)
        ) AS [result];

SELECT browser, SUM(hits) AS hits
FROM (
    SELECT
        CONVERT(int, JSON_VALUE(jsonContent, '$.totals.hits')) AS hits,
        JSON_VALUE(jsonContent, '$.device.browser') AS browser
    FROM
        OPENROWSET(
            BULK 'https://synapsedemopp1adls.dfs.core.windows.net/datalake/google_analytics/ga_sessions_sample.json',
            FORMAT = 'CSV',
            FIELDQUOTE = '0x0b',
            FIELDTERMINATOR ='0x0b'
        )
        WITH (
            jsonContent varchar(max)
        ) AS [result]
) AS t
GROUP BY browser
ORDER BY hits DESC;
