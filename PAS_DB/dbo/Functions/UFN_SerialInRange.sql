/*************************************************************
** Author:  Amit Ghediya
** Create date: 07/10/2026
** Description: Returns 1 if @Serial falls within the [@FromSerial, @ToSerial]
**              range, using the same three supported serial formats as
**              USP_SaveAircraftEffectivity's range-expansion logic:
**                A) Dash-separated  : AB-001  -> AB-003
**                B) Alphanumeric    : AC454245 -> AC454247
**                C) Pure numeric    : 10001    -> 10003
**              Returns 0 (never errors) for unrecognised/mismatched formats
**              so it is safe to call from a WHERE/EXISTS predicate.
**              WITH SCHEMABINDING + deterministic so SQL Server 2019+ can
**              scalar-UDF-inline this call instead of evaluating row-by-row.
**************************************************************/
CREATE FUNCTION [dbo].[UFN_SerialInRange]
(
    @Serial     VARCHAR(100),
    @FromSerial VARCHAR(100),
    @ToSerial   VARCHAR(100)
)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @Result BIT = 0;

    DECLARE
        @SerialPrefix  VARCHAR(100),
        @FromPrefix    VARCHAR(100),
        @ToPrefix      VARCHAR(100),
        @SerialNo      INT,
        @FromNo        INT,
        @ToNo          INT,
        @NumericStart  INT;

    IF @Serial IS NULL OR @FromSerial IS NULL OR @ToSerial IS NULL
        RETURN 0;

    -- ── FORMAT A: dash-separated (AB-001) ────────────────────
    IF CHARINDEX('-', @Serial) > 0 AND CHARINDEX('-', @FromSerial) > 0 AND CHARINDEX('-', @ToSerial) > 0
    BEGIN
        SET @SerialPrefix = LEFT(@Serial,     LEN(@Serial)     - CHARINDEX('-', REVERSE(@Serial)));
        SET @FromPrefix   = LEFT(@FromSerial, LEN(@FromSerial) - CHARINDEX('-', REVERSE(@FromSerial)));
        SET @ToPrefix     = LEFT(@ToSerial,   LEN(@ToSerial)   - CHARINDEX('-', REVERSE(@ToSerial)));

        IF @SerialPrefix = @FromPrefix AND @FromPrefix = @ToPrefix
        BEGIN
            SET @SerialNo = TRY_CAST(RIGHT(@Serial,     CHARINDEX('-', REVERSE(@Serial)) - 1) AS INT);
            SET @FromNo   = TRY_CAST(RIGHT(@FromSerial, CHARINDEX('-', REVERSE(@FromSerial)) - 1) AS INT);
            SET @ToNo     = TRY_CAST(RIGHT(@ToSerial,   CHARINDEX('-', REVERSE(@ToSerial)) - 1) AS INT);

            IF @SerialNo IS NOT NULL AND @FromNo IS NOT NULL AND @ToNo IS NOT NULL
               AND @SerialNo BETWEEN @FromNo AND @ToNo
                SET @Result = 1;
        END

        RETURN @Result;
    END

    -- ── FORMAT B: alphanumeric without dash e.g. AC454245 ────
    IF PATINDEX('%[0-9]%', @Serial) > 1 AND PATINDEX('%[0-9]%', @FromSerial) > 1 AND PATINDEX('%[0-9]%', @ToSerial) > 1
    BEGIN
        SET @NumericStart = PATINDEX('%[0-9]%', @FromSerial);
        SET @FromPrefix   = LEFT(@FromSerial, @NumericStart - 1);
        SET @ToPrefix     = LEFT(@ToSerial,   @NumericStart - 1);
        SET @SerialPrefix = LEFT(@Serial,     CASE WHEN PATINDEX('%[0-9]%', @Serial) > 1 THEN PATINDEX('%[0-9]%', @Serial) - 1 ELSE 0 END);

        IF @SerialPrefix = @FromPrefix AND @FromPrefix = @ToPrefix
           AND PATINDEX('%[^0-9]%', RIGHT(@Serial, LEN(@Serial) - @NumericStart + 1)) = 0
        BEGIN
            SET @SerialNo = TRY_CAST(RIGHT(@Serial,     LEN(@Serial)     - @NumericStart + 1) AS INT);
            SET @FromNo   = TRY_CAST(RIGHT(@FromSerial, LEN(@FromSerial) - @NumericStart + 1) AS INT);
            SET @ToNo     = TRY_CAST(RIGHT(@ToSerial,   LEN(@ToSerial)   - @NumericStart + 1) AS INT);

            IF @SerialNo IS NOT NULL AND @FromNo IS NOT NULL AND @ToNo IS NOT NULL
               AND @SerialNo BETWEEN @FromNo AND @ToNo
                SET @Result = 1;
        END

        RETURN @Result;
    END

    -- ── FORMAT C: pure numeric e.g. 10001 ────────────────────
    IF ISNUMERIC(@Serial) = 1 AND ISNUMERIC(@FromSerial) = 1 AND ISNUMERIC(@ToSerial) = 1
    BEGIN
        SET @SerialNo = TRY_CAST(@Serial     AS INT);
        SET @FromNo   = TRY_CAST(@FromSerial AS INT);
        SET @ToNo     = TRY_CAST(@ToSerial   AS INT);

        IF @SerialNo IS NOT NULL AND @FromNo IS NOT NULL AND @ToNo IS NOT NULL
           AND @SerialNo BETWEEN @FromNo AND @ToNo
            SET @Result = 1;

        RETURN @Result;
    END

    RETURN 0;
END